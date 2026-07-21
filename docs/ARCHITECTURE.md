# Messy — Architecture

Mesh-network messaging for Android, built in Flutter. Messages, photos, and videos travel over Wi-Fi LAN and Wi-Fi Direct/hotspot meshes when no internet exists, and opportunistically over direct internet P2P when available. Everything is end-to-end encrypted; there is **no server anywhere** in the system.

## 1. Design principles

1. **No infrastructure.** Pure peer-to-peer. The internet path is direct WebRTC between peers (STUN only, no TURN relay). If two peers can't hole-punch, messages simply wait for a mesh path.
2. **LAN-first.** Cheapest transport wins: same-Wi-Fi TCP > Wi-Fi Direct group > internet P2P.
3. **Ciphertext everywhere.** Intermediate mesh hops store and forward opaque encrypted envelopes. They can see routing metadata (sender/recipient keys, sizes, timing) but never content.
4. **Local-only storage.** A single on-device SQLite database (via drift — the same SQLite engine WhatsApp uses). No cloud sync, no backups (`android:allowBackup="false"`).
5. **Honest UX.** Delivery over a mesh is best-effort. The UI always tells the truth: *queued → sent to mesh → delivered*.

## 2. Package selection

| Concern | Package | Why |
|---|---|---|
| Wi-Fi Direct / hotspot | `flutter_p2p_connection` | Wraps Android `WifiP2pManager` incl. group creation (hotspot mode) with real sockets. Chosen over Google Nearby Connections, which is a Play-Services black box (own crypto, opaque strategy switching, no raw sockets). |
| LAN discovery | UDP broadcast beacon (pure `dart:io`, port 47488) | Implemented for v1: no plugin, no multicast-lock platform channel, and it behaves identically on home Wi-Fi and phone hotspots. Beacons only advertise (nodeId, name, TCP port); identity is proven by the signed hello handshake, never by the beacon. mDNS (`nsd`) remains the upgrade path if broadcast is filtered on some APs. |
| Sockets | `dart:io` TCP | One framed byte-stream abstraction for every transport. |
| Internet P2P | `flutter_webrtc` (data channels, STUN only) | Signaling is carried over the mesh/LAN when peers meet; candidate endpoints cached per contact for later dial attempts. |
| Crypto | `cryptography` + `cryptography_flutter` | X25519, Ed25519, HKDF, AES-256-GCM; platform-accelerated AES for media. |
| Key storage | `flutter_secure_storage` | Android Keystore-backed private seed. |
| Database | `drift` | Typed SQLite, migrations, reactive streams. Local-only. |
| QR | `qr_flutter` (show) + `mobile_scanner` (scan) | |
| Media | `image_picker`, `flutter_image_compress`, `video_compress`, `video_thumbnail`, `video_player`, `photo_view` | Photos downscaled, videos transcoded to ≤720p/2 Mbps before transfer. |
| Background | `flutter_foreground_task` (mesh service), `workmanager` (auto-wipe) | |
| State/DI | `flutter_riverpod` | |
| Misc | `permission_handler`, `flutter_local_notifications`, `uuid` (UUIDv7), `freezed`, `clock` | |

## 3. Layered architecture

```
┌─────────────────────────────────────────────────────┐
│ UI (Flutter widgets, Riverpod providers)            │
│   ChatList · PublicRoom · Chat · Contacts ·         │
│   AddContact (QR/Nearby) · ContactDetail · Settings │
├─────────────────────────────────────────────────────┤
│ Application / Services                              │
│   ChatService      – send/receive, message state    │
│   ContactService   – QR add, request/accept         │
│   TransferService  – chunking, resume, reassembly   │
│   MeshRouter       – store-and-forward, dedupe, TTL │
│   CryptoService    – identity, sessions, seal/open  │
│   WipeService      – disappearing msgs + auto-wipe  │
├─────────────────────────────────────────────────────┤
│ Domain (pure Dart, fully unit-testable)             │
│   entities · envelope/frame codecs · routing policy │
├─────────────────────────────────────────────────────┤
│ Transport Abstraction                               │
│   Link (interface) ── LanLink · WifiDirectLink ·    │
│                       InternetLink (webrtc)         │
│   Discovery ── MdnsDiscovery · WifiDirectDiscovery  │
│   ConnectivityManager – priority, auto-switching    │
├─────────────────────────────────────────────────────┤
│ Infrastructure                                      │
│   drift (SQLite) · Keystore · media file store ·    │
│   platform channels (MulticastLock)                 │
└─────────────────────────────────────────────────────┘
```

Dependency rule: `ui → services → domain ← transport/data`.

### The `Link` interface

```dart
abstract class Link {
  String get peerNodeId;          // known after handshake
  LinkTransport get transport;    // lan | wifiDirect | internet
  int get costHint;               // lan=1, wifiDirect=2, internet=3
  Stream<Uint8List> get frames;   // length-prefixed frames in
  Future<void> sendFrame(Uint8List frame);
  Stream<LinkState> get state;
  Future<void> close();
}

abstract class Discovery {
  Stream<PeerAdvert> get peers;
  Future<void> startAdvertising(LocalIdentity id);
  Future<void> startBrowsing();
  Future<void> stop();
}
```

All transports reduce to a framed byte stream — LAN and Wi-Fi Direct are TCP sockets (Wi-Fi Direct just adds group formation to obtain an IP); internet is a WebRTC data channel; **Bluetooth LE** is a GATT connection. **One codec, one router, many pipes.**

### Bluetooth LE mesh (the true multi-hop path)

Wi-Fi's hard limit is that a radio joins one network at a time, so two separate hotspots can never bridge live. BLE removes that constraint: a device is simultaneously a **peripheral** (advertises + hosts a GATT server) and a **central** (scans + connects to several neighbours). A single BLE connection is full-duplex — the central writes to the peer's characteristic, the peer notifies back — so one connection per neighbour is a complete `Link`, and because a phone holds several BLE connections at once it relays between neighbours in real time. Chains A↔B↔C↔D form by proximity with **no shared network at all**.

Frames are fragmented to the negotiated MTU on send and reassembled by the same `FrameReader` the TCP path uses, so the mesh layer above is unchanged — BLE links are handed to `ConnectivityManager.ingestLink` exactly like TCP links, go through the identical signed-hello handshake, and carry the identical encrypted envelopes. A per-pair tie-break (the lower nodeId dials) prevents double connections. The whole BLE subsystem is isolated and fail-safe: if Bluetooth is off, denied, or unsupported, it silently no-ops and the Wi-Fi/hotspot mesh is unaffected.

**Verification status:** the BLE transport compiles, analyzes clean, and is architecturally integrated, but Bluetooth cannot be exercised on an emulator or a single device — it requires on-device testing across multiple physical handsets to confirm real-world behavior (advertising quirks, MTU, multi-connection stability vary by OEM). Treat it as field-test-pending, not yet proven.

### ConnectivityManager

- Holds `Map<nodeId, List<Link>>`; picks the lowest-cost live link per peer.
- Discovery loops: mDNS whenever on Wi-Fi; Wi-Fi Direct scan on user action or when no LAN peers found (duty-cycled 15 s scan / 45 s idle); internet dial when online and a contact has cached endpoints.
- New link ⇒ handshake (`hello` frame: protocol version, nodeId, Ed25519-signed challenge — prevents nodeId spoofing) ⇒ hand to MeshRouter ⇒ **anti-entropy summary exchange** (each side lists carried envelope IDs; peers request what they lack).

## 4. Wire format

Stream framing: `uint32 length | frame bytes`.

```
offset  size  field
0       1     version (0x01)
1       1     frameType  (0x01 hello, 0x02 envelope, 0x03 ack,
                          0x04 summary, 0x05 want, 0x06 chunkReq,
                          0x07 contactReq, 0x08 contactAccept)
```

**Envelope (frameType 0x02)** — the store-and-forward unit:

```
2       16    messageId      (UUIDv7 — time-ordered, dedupe key)
18      32    senderPubKey   (X25519)
50      32    recipientPubKey (all-zeros = public room broadcast)
82      1     ttl            (1:1 start 8, public room start 5; drop at 0)
83      1     hopCount
84      8     timestampMs
92      1     payloadType    (0x01 text, 0x02 mediaManifest,
                              0x03 mediaChunk, 0x04 deliveryReceipt,
                              0x05 publicText)
93      2     chunkIndex
95      2     chunkTotal
97      12    nonce (AES-GCM)
109     …     ciphertext (AES-256-GCM, includes 16 B tag)
```

- Immutable header fields (`messageId … chunkTotal`, excluding `ttl`/`hopCount`) are fed to GCM as **associated data** — routing metadata is tamper-evident at the recipient.
- Dedupe key: `messageId` (text) or `(messageId, chunkIndex)` (chunks), tracked in `seen_envelopes`, pruned after 7 days.

**Routing (v1, epidemic):** on receipt → if seen, drop; store; if mine (or public), decrypt + deliver (+ gossip a `deliveryReceipt` for 1:1); else decrement TTL and re-forward on all live links except the arrival link. Foreign envelopes retained 72 h (public: 24 h), capped at a 256 MB relay budget (evict oldest, media first).

**Media:** chunk plaintext at 32 KiB, each chunk independently encrypted. An encrypted `mediaManifest` precedes chunks: filename, MIME, size, chunkTotal, SHA-256 of plaintext, inline JPEG thumbnail ≤16 KiB. **Resume:** the receiver persists a chunk bitmap; `summary`/`want` frames request specific missing chunks from any carrier. Relayed media hard-capped at 25 MB; media chunks follow a direction hint (links that recently produced delivery receipts for the recipient) rather than pure flooding.

## 5. Identity, contacts, sessions

- First launch: one random seed → HKDF → X25519 keypair (encryption) + Ed25519 keypair (signing). Seed in Keystore. `nodeId = hex(SHA-256(x25519Pub)[0..16])`.
- **QR add (verified):** `messy://contact?v=1&x=<x25519>&e=<ed25519>&n=<name>`. In-person scan ⇒ `verified = true`. "My QR" and scanner live in one tabbed screen.
- **Nearby add (unverified):** discovery adverts carry nodeId + name; tapping sends a signed `contactReq`; the peer accepts/declines; stored `verified = false` with a **6-word fingerprint phrase** (from SHA-256 over both pubkeys, sorted) shown for out-of-band comparison, plus a "verify via QR" nudge.
- **Session keys:** `shared = X25519(myPriv, theirPub)`; `sendKey/recvKey = HKDF-SHA256(shared, salt="messy-v1", info=pubA‖pubB)` directional; fresh random 12-byte nonce per message.

## 6. Public chatroom ("Local")

- One built-in broadcast room, pinned atop the chat list. Anyone on the mesh can read and post — no contact required.
- Envelope recipient = all-zeros sentinel; every node delivers locally **and** keeps forwarding (TTL 5).
- Payload is Ed25519-signed (no impersonation) and encrypted with a room key derived from the room name — uniform wire format, but this is **obfuscation, not secrecy** (see SECURITY.md).
- Text only in v1. Public messages always expire after 24 h on every device.

## 7. Privacy: disappearing messages & auto-wipe

- **Disappearing messages (per chat):** off / 1 h / 24 h / 7 d, set in contact detail. The timer travels encrypted inside the payload so both sides honor it; each message gets `expires_at`. A sweeper (foreground-service tick + on-app-resume) deletes expired rows and media files.
- **24 h auto-wipe (global toggle):** wipes all messages, media, relay_store, and seen_envelopes every 24 h (contacts and identity survive). `workmanager` periodic task + sweep-on-launch fallback guarantees nothing older than 24 h is ever displayed even if the exact-time job is deferred.
- SQLite runs with `PRAGMA secure_delete = ON` so wiped rows are overwritten, not just unlinked. `android:allowBackup="false"` keeps message data out of device backups.

## 8. Storage schema (drift / SQLite, local-only)

```sql
identity(id PK=1, x25519_pub, ed25519_pub, display_name, created_at)
contacts(node_id PK, x25519_pub, ed25519_pub, display_name,
         verified, added_via, last_seen_at, cached_endpoints)
chats(chat_id PK, node_id NULL,          -- NULL = public room
      disappear_after_secs NULL)
messages(message_id PK, chat_id, direction, payload_type, body,
         media_id NULL, sent_at, received_at NULL, expires_at NULL, status)
media(media_id PK, message_id, file_path, mime_type, total_size,
      chunk_total, sha256, thumbnail, complete)
media_chunks(media_id, chunk_index, received, PK(media_id, chunk_index))
relay_store(message_id, chunk_index, frame BLOB, recipient_node_id,
            ttl, size, stored_at, PK(message_id, chunk_index))
seen_envelopes(message_id, chunk_index, seen_at, PK(message_id, chunk_index))
settings(key PK, value)                  -- auto_wipe, relay_budget, …
```

Media files live under `getApplicationDocumentsDirectory()/media/`; the DB stores paths.

## 9. Project structure

```
lib/
  main.dart
  app.dart
  core/                          # constants, logger, Result, utils
  domain/
    entities/                    # contact, message, envelope, media_manifest, peer_advert
    codec/                       # envelope_codec, frame_codec   (pure)
    routing/                     # routing_policy (ttl, dedupe, eviction — pure)
  services/
    crypto/                      # identity_service, session_crypto
    chat/                        # chat_service
    contacts/                    # contact_service, qr_payload
    transfer/                    # transfer_service, chunker
    mesh/                        # mesh_router, relay_store, anti_entropy
    wipe/                        # wipe_service (disappearing + auto-wipe)
  transport/
    link.dart                    # Link, Discovery interfaces
    connectivity_manager.dart
    lan/                         # mdns_discovery, lan_link, tcp_server
    wifi_direct/                 # wd_discovery, wd_link, group_manager
    internet/                    # webrtc_link, mesh_signaling
  data/
    db/                          # drift tables, database, DAOs
    files/                       # media_file_store
    secure/                      # key_store
  ui/
    screens/                     # chat_list/ public_room/ chat/ contacts/
                                 # add_contact/ settings/
    widgets/                     # message_bubble, transfer_progress, mesh_status_chip
    providers/                   # riverpod wiring
test/                            # codec, crypto, routing get heavy unit tests
```

`domain/codec` and `domain/routing` are pure Dart — testable without devices, which matters because full integration testing needs 2–3 physical phones.

## 10. Roadmap

| Phase | Scope | Exit criterion |
|---|---|---|
| 1 (1–2 wk) | Scaffold, drift DB, identity in Keystore, QR contact exchange, chat UI shell | Two phones exchange contacts via QR |
| 2 (2–3 wk) | Frame/envelope codecs (TDD), TCP + mDNS LAN transport, handshake, session crypto, 1:1 text, public room over LAN | Encrypted chat between two phones on one Wi-Fi |
| 3 (3–4 wk) | Wi-Fi Direct groups, permission flow, MeshRouter (dedupe/TTL/relay), anti-entropy, receipts, foreground service | A→C via relay B; B cannot read content; message survives B physically carrying it |
| 4 (2–3 wk) | Media pick/compress/chunk/resume, progress UI, relay budgeting; disappearing messages + 24 h auto-wipe | 20 MB video with mid-transfer disconnect + resume; photo relayed via B; wipe verified |
| 5 (3–4 wk) | WebRTC internet links, endpoint caching, honest failure UX, notifications, battery tuning, onboarding | Two phones on different networks chat directly when NAT allows |

## 11. Risks & gotchas

1. **Android permission maze (highest risk).** Wi-Fi Direct needs `ACCESS_FINE_LOCATION` (+ Location Services ON) on API ≤ 32, and `NEARBY_WIFI_DEVICES` (`neverForLocation`) on API 33+. mDNS silently fails without `CHANGE_WIFI_MULTICAST_STATE` + an acquired MulticastLock. Build the permission-gate flow early; test API 29 / 33 / 34+.
2. **Background execution.** Doze kills sockets and groups. Foreground service (`connectedDevice`/`dataSync`) with a visible "Mesh active" toggle; a fully backgrounded app will not relay — the UX says so.
3. **Wi-Fi Direct group pain.** 3–15 s formation, OEM accept dialogs (Samsung), one group membership at a time ⇒ topology is star-per-group; multi-group meshing happens by time-slicing and physical carrying, not simultaneous links. MeshRouter assumes intermittent links from day one.
4. **Video practicality.** 1 min 1080p ≈ 60–130 MB — untenable multi-hop. Cap relayed media at 25 MB, transcode to 720p, thumbnail-first with lazy fetch.
5. **NAT honesty.** STUN-only means symmetric-NAT pairs (~15–25 %) can't connect over the internet. UX: "will deliver when you're nearby or share a network."
6. **Battery/storage of epidemic routing.** Relay cap, seen-set pruning, duty-cycled scans.
7. **Clock skew.** Never order UI by peer timestamps; order by UUIDv7 sender-side per chat, display sender time with local fallback.

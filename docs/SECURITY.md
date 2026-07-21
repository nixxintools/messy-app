# Messy — Security Design & Threat Model

This document states plainly what Messy protects, how, and — just as importantly — what it does **not** protect in v1.

## 1. Identity & keys

- On first launch the app generates a single random 32-byte seed and derives, via HKDF-SHA256:
  - an **X25519 keypair** — encryption identity
  - an **Ed25519 keypair** — signing identity
- The seed is stored in `flutter_secure_storage`, backed by the **Android Keystore**. It never leaves the device. There is no account, no phone number, no email.
- `nodeId = hex(SHA-256(x25519Pub)[0..16])`. Because every link handshake includes an Ed25519-signed challenge, a nodeId cannot be spoofed by a device that lacks the matching private key.

## 2. End-to-end encryption (1:1 chats)

### Forward secrecy via one-time prekeys (texts, receipts, invites)

Each device maintains a pool of X25519 **one-time prekeys (OTKs)**:

- Prekey publics are **issued per peer** (no two contacts ever hold the same one): a signed batch on every link-up (Ed25519 over the bundle, so a hostile network can't inject keys), plus a couple of fresh keys piggybacked inside every encrypted text and delivery receipt — long conversations replenish themselves with no server and no extra round trips.
- Sealing: the sender consumes one unused OTK and computes
  `K = HKDF-SHA256( DH(ephemeral, otk) ‖ DH(senderStatic, otk), salt="messy-otk-v1", info = ephPub ‖ otkPub )`
  The ephemeral secret is discarded immediately; the envelope carries `ephPub` and the OTK id (both bound into the GCM associated data).
- Opening: the recipient decrypts and then **deletes the OTK secret** — that deletion is the forward secrecy. A later compromise of the device's long-term key cannot decrypt captured ciphertext sealed to a burned OTK. The second DH authenticates the sender (only the holder of the sender's static key derives K).
- When a peer's OTK pool is dry (e.g. long offline stretch), sending **falls back to the static session** below — delivery is never blocked, that message simply lacks FS, and the pool refills with the next contact.

This is the OTK model (as used by store-and-forward messengers) rather than a Double Ratchet: it needs no synchronous round trips, which mesh delivery cannot guarantee. It does **not** provide post-compromise security — see §7.

### Static session (fallback + media)

- **Key agreement:** static-static ECDH — `shared = X25519(myPriv, theirPub)`.
- **Session keys:** directional
  `sendKey = HKDF-SHA256(shared, salt="messy-v1", info = myPub ‖ theirPub)`
  `recvKey = HKDF-SHA256(shared, salt="messy-v1", info = theirPub ‖ myPub)`
- **Per message:** fresh random 12-byte nonce, **AES-256-GCM**. The immutable envelope header (messageId, sender/recipient keys, timestamp, payload type, chunk fields, and the FS fields) is authenticated as GCM associated data, so a relay that tampers with routing metadata breaks authentication at the recipient. TTL and hop count are excluded (they legitimately change per hop).
- Media (manifest + 32 KiB chunks, each with its own nonce, SHA-256-verified on reassembly) intentionally uses the static session: one video would burn hundreds of OTKs. Per-transfer keys are the planned upgrade.
- OTK secrets live in the local SQLite database (`secure_delete` on), not the Keystore — Android's Keystore cannot hold a rotating pool of raw X25519 keys. Unused keys expire after 14 days.

### What relays see
Intermediate mesh hops store and forward **ciphertext only**. They can observe: sender and recipient public keys, message IDs, sizes, timing, TTL/hops. They can never read content. Traffic-analysis metadata is *not* hidden in v1.

## 3. Contact verification

| Method | Trust | Rationale |
|---|---|---|
| QR scan | **verified** | Keys exchanged by physical presence — a trusted channel. |
| Nearby request/accept | **unverified** | Keys exchanged over the air; a MITM on first contact is theoretically possible. The UI shows a **6-word fingerprint phrase** (derived from SHA-256 over both public keys, sorted) that both users can compare out-of-band, plus a nudge to re-verify via QR. |

## 4. Public channels — not secret, but authenticated and moderated

The "Local" room and the public "Media" channel are encrypted with a key derived from a public constant. Every copy of Messy can derive this key, so this is **obfuscation, not confidentiality**: treat anything posted there as public speech. Posts expire everywhere after 24 h.

**Sender authentication.** Because the channel key is shared, the `senderPub` field alone proves nothing — anyone could set it. So every public/group post is **Ed25519-signed** over `messageId ‖ senderPub ‖ timestamp ‖ payloadType ‖ content`, and the receiver rejects any post whose signature doesn't verify. If the sender key matches a **known contact** whose signing key we hold, the post must be signed by exactly that key — so a stranger cannot impersonate a saved contact. (An attacker can still mint a fresh anonymous identity per post; that's inherent to a registration-free network, and is what the moderation layer in §9 addresses.) Group media chunks carry no separate signature — their integrity comes from the SHA-256 in the signed manifest, so a forged chunk fails reassembly.

**No auto-download in the public Media channel.** Public media is never fetched to disk or shown automatically. The manifest arrives, chunks are held encrypted-at-rest in the app database (never materialized as a gallery file), and the image/video is only assembled and displayed when the user explicitly taps "download & view" on a placeholder marked *unverified sender*. This stops drive-by illegal content from silently landing in a user's gallery or being auto-redistributed. Media inside 1:1 chats and invite-only groups (consensual, bounded audiences) still auto-downloads.

## 9. Moderation on a serverless mesh

A serverless anonymous channel has no gatekeeper — you cannot *prevent* someone posting. Every defense is therefore client-side, and Messy layers several:

- **Block ("block for me").** Blocking a node hides its messages, **purges** everything it sent that you stored, and makes your device **stop relaying its posts** — so a spammer loses reach through everyone who blocks them. It cannot stop them transmitting to others.
- **Relay rate limiting.** A per-sender token bucket caps how much any one node can push through your device, so a flooder can't fill relay budgets, drain batteries, or drown out Local.
- **Web-of-trust blocklists.** When you block someone, a **signed** block record is shared with your *verified* contacts on connection. If several verified contacts have each blocked the same node, you auto-mute it too. Only manually-created blocks are shared (never auto-blocks, to prevent cascades), and only **verified** contacts get a vote (an unverified/sybil identity cannot manufacture auto-blocks).

This is the ceiling of what a serverless design allows: abuse becomes low-reach, non-persistent, and attributable — but not impossible. Users should understand that public channels are open-broadcast spaces.

## 5. App access: PIN gate

- A PIN is set up **mandatorily during onboarding** and the gate is **on by default** — Messy starts at maximum security and only the user can reduce it.
- The PIN is required to open the app at least once every 24 h; a successful unlock is valid for 24 h across restarts.
- Disabling the gate in Settings requires entering the current PIN.
- Storage: salted SHA-256 of the PIN in the Keystore-backed secure store. The gate protects the UI; data-at-rest protection comes from Android file-based encryption + the measures below. (Deriving a DB encryption key from the PIN, e.g. SQLCipher, is the v2 upgrade path.)

## 6. Data at rest

- Single local **SQLite** database (via drift). No cloud storage, no sync, no server. `android:allowBackup="false"` keeps chats out of Google/device backups.
- `PRAGMA secure_delete = ON` — deleted rows are overwritten in the database file, not merely unlinked.
- **Disappearing messages:** per-chat timer (off / 1 h / 24 h / 7 d) carried *inside the encrypted payload* so both ends enforce it. Cooperative, not cryptographic: a malicious recipient can screenshot or fork the app. This is the same honesty caveat Signal/WhatsApp carry.
- **24 h auto-wipe (opt-in):** wipes messages, media files, the relay store, and the seen-envelope set every 24 h; identity and contacts survive. Enforced by a periodic job plus a sweep-on-launch guarantee (nothing older than 24 h is ever displayed even if the background job was deferred by the OS).
- Relayed foreign envelopes are ciphertext and are evicted at 72 h (24 h for public posts) or under storage pressure.

## 7. Known limitations (v1) — deliberate, documented tradeoffs

1. **Forward secrecy is per-message and best-effort, not absolute.** Texts, receipts, and group invites get FS whenever an unused one-time prekey is available; the first messages to a brand-new contact met over the mesh, messages after a long offline stretch, and all media fall back to the static session (no FS for those). There is **no post-compromise security**: an attacker who fully compromises a device can read messages going forward until keys age out — healing requires a Double Ratchet, which store-and-forward delivery cannot guarantee. Group messages use a static shared group key (no FS by design). The 24 h auto-wipe and disappearing messages shrink the on-device exposure window.
2. **Metadata visible to relays** (who↔who, when, how much). Mitigating this (onion routing, cover traffic) is out of scope for v1.
3. **First-contact MITM for nearby adds** — mitigated by the fingerprint phrase and QR re-verification, not eliminated.
4. **Deniability/anonymity are non-goals.** Messages are signed; participation on a mesh is observable by radio proximity.
5. **Compromised relay behavior:** a hostile relay can drop, delay, or replay envelopes. Replays are deduplicated by message ID; drops are mitigated only by epidemic redundancy.

## 8. Platform hardening checklist

- `allowBackup="false"`, `dataExtractionRules` opt-out (API 31+)
- Keystore-backed seed, no key material in SharedPreferences or logs
- `FLAG_SECURE` on chat screens (blocks screenshots/recents thumbnail) — Settings toggle
- No third-party analytics/telemetry of any kind
- Dependency pinning + `flutter pub outdated` review each release

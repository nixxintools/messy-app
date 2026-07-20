# Messy — Security Design & Threat Model

This document states plainly what Messy protects, how, and — just as importantly — what it does **not** protect in v1.

## 1. Identity & keys

- On first launch the app generates a single random 32-byte seed and derives, via HKDF-SHA256:
  - an **X25519 keypair** — encryption identity
  - an **Ed25519 keypair** — signing identity
- The seed is stored in `flutter_secure_storage`, backed by the **Android Keystore**. It never leaves the device. There is no account, no phone number, no email.
- `nodeId = hex(SHA-256(x25519Pub)[0..16])`. Because every link handshake includes an Ed25519-signed challenge, a nodeId cannot be spoofed by a device that lacks the matching private key.

## 2. End-to-end encryption (1:1 chats)

- **Key agreement:** static-static ECDH — `shared = X25519(myPriv, theirPub)`.
- **Session keys:** directional
  `sendKey = HKDF-SHA256(shared, salt="messy-v1", info = myPub ‖ theirPub)`
  `recvKey = HKDF-SHA256(shared, salt="messy-v1", info = theirPub ‖ myPub)`
- **Per message:** fresh random 12-byte nonce, **AES-256-GCM**. The immutable envelope header (messageId, sender/recipient keys, timestamp, payload type, chunk fields) is authenticated as GCM associated data, so a relay that tampers with routing metadata breaks authentication at the recipient. TTL and hop count are excluded (they legitimately change per hop).
- Media is chunked at 32 KiB; every chunk is independently encrypted with its own nonce, and the decrypted whole is verified against a SHA-256 in the (encrypted) manifest.

### What relays see
Intermediate mesh hops store and forward **ciphertext only**. They can observe: sender and recipient public keys, message IDs, sizes, timing, TTL/hops. They can never read content. Traffic-analysis metadata is *not* hidden in v1.

## 3. Contact verification

| Method | Trust | Rationale |
|---|---|---|
| QR scan | **verified** | Keys exchanged by physical presence — a trusted channel. |
| Nearby request/accept | **unverified** | Keys exchanged over the air; a MITM on first contact is theoretically possible. The UI shows a **6-word fingerprint phrase** (derived from SHA-256 over both public keys, sorted) that both users can compare out-of-band, plus a nudge to re-verify via QR. |

## 4. Public chatroom — explicitly not secret

The "Local" room is encrypted with a key derived from the room name (`HKDF("messy-public-room" ‖ name)`). Every copy of Messy can derive this key. This keeps the wire format uniform and keeps casual packet sniffers out, but it is **obfuscation, not confidentiality**: treat anything posted to the public room as public speech. Posts are Ed25519-signed, so display names cannot be forged for a given nodeId, but nothing stops a user from choosing any display name they like. Public posts expire everywhere after 24 h.

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

1. **No forward secrecy.** Static-static ECDH means a future compromise of a device's private key decrypts previously captured ciphertext for that pair. Ratcheting (Signal-style) needs round trips that store-and-forward delivery cannot guarantee. **v2 path:** X3DH-style signed prekeys gossiped over the mesh, then a Double Ratchet per session — the reference implementation to build against is [signalapp/libsignal](https://github.com/signalapp/libsignal) (the audited Rust core with FFI bindings that Signal itself ships; its sealed-sender and Kyber-hybrid work are also relevant to Messy's metadata and post-quantum roadmap). The 24 h auto-wipe and disappearing messages materially shrink this exposure window on-device.
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

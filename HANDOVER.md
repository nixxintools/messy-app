# HANDOVER — Messy

State of play so a new session can continue seamlessly. Last updated at
**v2.8.0** (2026-07-21).

Read this first, then [CLAUDE.md](CLAUDE.md) for how to work in the repo.

---

## 1. Where things stand

- Repo: **github.com/nixxintools/messy-app** — public, MIT, `main` clean and
  fully pushed.
- Current release: **v2.8.0** (Latest). History: v0.1.0 → v2.0.0 (open-sourced)
  → v2.1.0 → v2.2.0 → v2.3.0 → v2.4.0 → v2.5.0 → v2.6.0 → v2.7.0 → v2.8.0.
- `flutter analyze` clean · **28 tests passing** · release APK builds (~93 MB).
- Installed on the user's phone (**OnePlus 12**, adb id `1eb68dd6`) and a copy
  sits at `/sdcard/Download/messy.apk` for forwarding to others.

The app is a working, feature-complete offline mesh messenger. The gap is
**field validation**, not features.

---

## 2. ⚠️ Verified vs NOT verified — the single most important section

Be precise about this with the user; it has been tracked honestly all along.

**Verified working (on real hardware):**
- Wi-Fi / hotspot mesh — messaging between two phones, proven in a live test.
- Startup radio gate (correctly detects Wi-Fi off and blocks).
- App UI: chat list, Local room, groups, media gallery, contacts, fingerprint
  screen, settings incl. the FLAG_SECURE toggle. Screenshots in
  `docs/screenshots/`.
- App launches with the SQLCipher-encrypted DB wired in, no DB errors in
  logcat.

**Built, compiles, tested in CI-sense — but NEVER verified on hardware:**
- **Bluetooth LE transport** (v2.2)
- **Wi-Fi Aware / NAN transport** (v2.3, native Kotlin)
- **Wi-Fi Direct transport** (v2.5, native Kotlin)

None of these can run on an emulator or a single phone. They need **2–3
physical handsets in a room**. Expect a round of on-device iteration — BLE
never works first try. All three are isolated and fail-safe, so if they don't
work the proven Wi-Fi path still carries the mesh.

**Partially verified:**
- The encrypted DB *opens* — the app launches clean and a
  `PRAGMA cipher_version` assertion makes a silent plaintext fallback
  impossible, but I never got past the radio gate on-device to watch it open
  in the live UI (a persistent Truecaller popup + a pending permission dialog
  blocked adb interaction). Worth confirming on a clean device.

---

## 3. Immediate next step

**Run the three-phone field test.** This is the only thing that can't be done
without the user.

1. Install v2.8.0 on 2–3 phones (share via the in-app **Share → over hotspot**
   flow, or from the GitHub release).
2. **Baseline (should work):** all phones on one hotspot → Local room, 1:1
   chat, a group, a photo. Confirms the proven path still works.
3. **BLE test:** Wi-Fi fully off, Bluetooth on, two phones apart with a third
   between → does a message cross?
4. **Wi-Fi Aware:** first find out whether the handsets even report
   `isSupported()` true (budget Oppo/Xiaomi/Realme often don't). If not,
   Wi-Fi Direct + BLE are the answer for those devices.
5. Bring back logcat output / symptoms and iterate.

---

## 4. Decisions the user has made (don't re-litigate)

- **No servers, ever.** Internet path, if ever built, must be P2P (WebRTC),
  and it's the *lowest* priority — the mission is working with no internet.
- **Public "Media" channel kept**, but with **no auto-download**: unverified
  media shows a tap-to-view placeholder. (User chose this over removing the
  channel.)
- **Web-of-trust blocklists**: blocks are shared with *verified* contacts and
  auto-mute after 2 votes.
- **Ship to live even when unverified** — the user explicitly accepted this
  for the radios after being advised against it. Keep flagging the risk, but
  respect the call.
- **Radio gate = Bluetooth + Wi-Fi**, not hotspot (a hotspot can't be
  universal — one host, everyone else joins).
- **Wi-Fi Direct built natively** rather than via `flutter_p2p_connection`,
  whose client uses BLE for discovery and would fight our BLE mesh.
- Brand: bright **sunlight yellow `#FFD60A`** (not WhatsApp green); logo is a
  yellow mesh-web, drawn in code (`WebLogo`) and generated for the launcher by
  `tool/gen_icon.dart`.

---

## 5. External security review — what happened

A friend of the user reviewed the code and (correctly) found the security
posture under-built. All five findings were fixed in **v2.6.0**:

| Finding | Fix |
|---|---|
| PIN not KDF-protected | **Argon2id** + constant-time compare |
| No PIN rate limiting | Escalating lockout 5s → 15s → 60s → 5m → 15m → 1h |
| OTK storage plain sqlite | **SQLCipher** whole-DB encryption, Keystore key |
| Routing metadata plain DB | same |
| FLAG_SECURE documented but absent | actually implemented + Settings toggle |

The reviewer's broader point — *secure software can't be vibe-coded* — was
accepted, not argued with. **SECURITY.md and README now open with a prominent
"not audited, unproven, don't rely on it for high-stakes needs" banner.**
Keep that honesty; do not quietly soften it.

Still weak (documented in SECURITY.md §9): no professional audit; small PIN
keyspace; DB key is Keystore-held, not PIN-derived; metadata visible to
relays; no post-compromise security (no Double Ratchet); radios not
security-reviewed.

---

## 6. Known issues / rough edges

- **README download link is version-pinned** and must be bumped every release.
  Offered to switch it to the auto-redirecting
  `releases/latest/download/messy.apk` — user hasn't decided. Worth asking.
- **Groups tab app-bar title** was never visually confirmed on device (uses
  the same verified `MessyTitle` widget as the chat list, so almost certainly
  fine).
- **Chat history resets** when upgrading past v2.6.0 — the old plaintext DB
  can't be read with the new encrypted one, so it's discarded. Expected,
  one-time, documented.
- R8 / code shrinking is **off** (`isMinifyEnabled = false`) until after field
  testing — would roughly halve the APK.
- Build warns that some plugins still apply the Kotlin Gradle Plugin
  (`mobile_scanner`, `flutter_foreground_task`, `video_compress`,
  `bluetooth_low_energy_android`). Harmless today, future Flutter will break.
- The user's phone drops off USB fairly often mid-session; re-check
  `adb devices` before assuming a failure is real.

---

## 7. Roadmap (rough priority)

1. **Field-test the three radios** ← blocking everything else.
2. Fix whatever that surfaces.
3. Enable R8 shrinking + re-verify.
4. Forward secrecy for **media** (per-transfer keys; currently static-session).
5. Post-compromise security (X3DH + Double Ratchet). Reference implementation
   would be `signalapp/libsignal` — *do not name it in docs until it's
   actually implemented* (the user asked for a premature reference to be
   removed once already).
6. In-app video playback (gallery currently shows a path for videos).
7. Opportunistic internet P2P (WebRTC, STUN-only, serverless) — lowest
   priority; only helps when internet exists, which isn't the mission.

---

## 8. Environment / critical facts

- Windows, Flutter 3.44.4 / Dart 3.12.2, project at `C:\Dev\Messy`.
- Phone: OnePlus 12, adb id `1eb68dd6`. User notes most target users will be
  on **low-cost Indian handsets** (Oppo/Xiaomi/Realme) — design for the
  budget-device path (BLE + Wi-Fi Direct), not just flagships.
- 🔑 **The release signing keystore is local-only and gitignored**
  (`android/upload-keystore.jks` + `android/key.properties`, random 27-year
  key). **If it is lost, existing installs can never be updated.** The user
  should back it up somewhere safe — worth reminding them.
- App id `dev.messy.messy`. DB schema version **4**; envelope wire format
  **v2** (adding FS fields) — bumping either is a breaking change requiring
  every phone to be on the same build.

# CLAUDE.md — working notes for AI sessions on Messy

Operational guidance for anyone (human or AI) picking up this repo. Design
detail lives in [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md); the threat model
lives in [docs/SECURITY.md](docs/SECURITY.md). This file is about *how to work
here*.

---

## What this is

**Messy** — a serverless, end-to-end-encrypted mesh messenger for Android
(Flutter). It works with **no internet**: phones talk over Wi-Fi/hotspot,
Bluetooth LE, Wi-Fi Aware, and Wi-Fi Direct, and relay messages for each other
store-and-forward. Repo: `nixxintools/messy-app` (public, MIT).

---

## Commands

```sh
flutter pub get
dart run build_runner build      # REQUIRED after touching drift tables/models
flutter analyze                  # must be clean before shipping
flutter test                     # 28 tests currently
flutter build apk --release      # signed release APK
```

**Install / verify on device** (Windows + PowerShell; adb lives at
`$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe`):

```powershell
$adb = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
& $adb devices
& $adb -s <DEVICE_ID> install -r "C:\Dev\Messy\build\app\outputs\flutter-apk\app-release.apk"
& $adb -s <DEVICE_ID> push  "C:\Dev\Messy\build\app\outputs\flutter-apk\app-release.apk" /sdcard/Download/messy.apk
```

**Screenshot for visual verification:**
```powershell
& $adb -s <ID> shell screencap -p /sdcard/s.png
& $adb -s <ID> pull /sdcard/s.png "$env:TEMP\s.png"   # then Read the PNG
```

---

## Release process (do all of these)

1. `flutter analyze` clean + `flutter test` green.
2. Bump `version:` in `pubspec.yaml`.
3. **Update the README download link** — it is version-pinned
   (`releases/download/vX.Y.Z/messy.apk`) and goes stale every release.
   Also check the `Status` heading says the right version.
4. `flutter build apk --release`
5. Commit + push.
6. Tag + release, always naming the asset `messy.apk`:
   ```sh
   git tag -a vX.Y.Z -m "..." && git push origin vX.Y.Z
   gh release create vX.Y.Z "<apk>#messy.apk" --title "..." --notes-file <f> --latest
   ```
   Release notes should start with a bold direct download link (GitHub renders
   notes above the Assets box and this cannot be reordered).
7. Install on the phone **and** refresh `/sdcard/Download/messy.apk` so the
   user can forward it.

---

## Layout

```
lib/
  core/            constants (wire protocol), bytes helpers, well-known rooms
  domain/          entities + pure codecs (envelope, frame) + routing policy
  data/db/         drift schema, SQLCipher open, DbKey
  services/
    crypto/        identity, session crypto, one-time prekeys, public_auth
    chat/ contacts/ transfer/ mesh/ moderation/ wipe/ security/ share/ radio/
  transport/       link.dart (the abstraction) + lan/ ble/ wifi_aware/ wifi_direct/
  ui/              screens/, widgets/, providers/ (riverpod)
android/app/src/main/kotlin/dev/messy/messy/
  MainActivity.kt        platform channels (wifi_aware, wifi_direct, radio, window, app)
  WifiAwareTransport.kt  native NAN
  WifiDirectTransport.kt native Wi-Fi Direct
```

---

## Conventions that matter

- **Transports are pluggable.** Anything that can be a framed byte stream
  implements `Link` and is handed to `ConnectivityManager.ingestLink()`. It
  then gets the signed handshake, crypto, and routing for free. *Never* put
  framing/crypto in a transport. Native transports are **transparent byte
  pipes** only.
- **Transports run in parallel with failover.** `_peerLinks` keeps one link
  *per transport per peer*; `pickBest` picks the lowest `costHint`
  (lan 1 < wifiAware 2 < wifiDirect 3 < bluetooth 4). A peer is only "down"
  when its last link drops.
- **New radios must be isolated and fail-safe.** Wrap start-up in try/catch,
  no-op when unsupported. A broken radio must never take down the working
  Wi-Fi path.
- **Honest UX language.** Delivery states are *queued → sent to mesh →
  ✓✓ delivered* and must never over-claim. Public rooms say plainly that
  they're public.
- **Never document something that isn't implemented.** SECURITY.md once
  claimed FLAG_SECURE before it existed; an external reviewer caught it. If
  you write it in the docs, wire it in the code in the same change.
- **Security defaults are on**; only the user may reduce them (PIN, auto-wipe).

---

## Gotchas (these have bitten before)

- **drift codegen**: touching table classes requires
  `dart run build_runner build` or the build fails on missing `.g.dart`.
- **SQLCipher vs sqlite3**: `sqlcipher_flutter_libs` is a normal dependency;
  `sqlite3_flutter_libs` is a **dev_dependency only** (host tests need a
  sqlite lib, but shipping both puts two `libsqlite3.so` in the APK). Don't
  promote it to a real dependency.
- **Do not remove the `PRAGMA cipher_version` assertion** in
  `lib/data/db/database.dart`. Without it, if SQLCipher fails to load, stock
  SQLite silently ignores `PRAGMA key` and the app runs on a **plaintext**
  database — working but insecure. The assertion makes that fail loudly.
- **Git Bash mangles adb remote paths** (`/sdcard/...` becomes
  `C:/Program Files/Git/sdcard/...`). Use PowerShell for adb, or `//sdcard/`.
- **PowerShell**: `$pid` is read-only; adb writes normal progress to stderr so
  PowerShell may render success as a red "error" — check the text, not the
  color. `Select-String` pipelines can make a successful build return a
  non-zero exit code; verify by checking the APK timestamp.
- **The signing keystore is local-only and gitignored**
  (`android/upload-keystore.jks`, `android/key.properties`). **If it is lost,
  no future build can update installed apps.** Back it up.
- **BLE/Wi-Fi Aware/Wi-Fi Direct cannot be tested** on an emulator or a single
  phone. Don't claim they work; say "compiles/unverified" until field-tested.
- Wi-Fi Aware needs API 29+ **and** hardware support (`isAvailable()`); many
  budget phones lack it — that's why Wi-Fi Direct + BLE exist as fallbacks.

---

## Verification bar before saying "done"

1. `flutter analyze` clean.
2. `flutter test` green.
3. `flutter build apk --release` succeeds (this is what compiles the Kotlin).
4. Where possible, install and **screenshot the actual screen** to confirm UI.
5. Say plainly what was *not* verified. The radios are the standing example.

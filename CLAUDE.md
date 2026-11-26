# Secure SMS (پیامک امن)

End-to-end encrypted SMS, no server. Design, wire format and threat model: `docs/ARCHITECTURE.md`. Plan: `docs/ROADMAP.md`.

## Commands
- `flutter test` (all green before any commit) · `flutter analyze` (no errors/warnings)
- Strings: edit `lib/l10n/app_fa.arb` (template) + `app_en.arb`, then `flutter gen-l10n`
- `flutter build apk --debug`, install on emulator-5554 / emulator-5556; `python3 tool/sms_bridge.py` carries SMS between them

## Rules
- No network, ever: no analytics, cloud, AI APIs or runtime font fetching. The promise is "no server".
- No URL in any SMS the app sends: Iranian carriers block SMS with links. Name Bazaar in plain text only.
- Crypto and wire formats live in `lib/crypto/sms_crypto.dart` (pure Dart, unit-tested). A format change needs a new tag version, a test and an ARCHITECTURE.md update.
- Plaintext is never stored. Key material stays in `flutter_secure_storage`; it leaves only inside a passphrase-sealed `#SB1:` backup.
- Changed keys are never trusted silently. New native permissions (e.g. RECEIVE_SMS) need the user's OK first.
- `MainActivity` is a `FlutterFragmentActivity` (local_auth) with `FLAG_SECURE`; keep both. Read the UI on emulators with `uiautomator dump` (screenshots are blocked).

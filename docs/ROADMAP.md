# Roadmap

Each phase ends with tests green and `flutter build apk` passing.

## ✅ Phase 1: Crypto core
X25519 + HKDF + XChaCha20-Poly1305, the wire format, the safety number, and SMS part math.
Done when round-trip, tamper, wrong-key, reflection, and restore tests pass (`test/sms_crypto_test.dart`).

## ✅ Phase 2: Key store and contacts
`Vault` stores the identity and contacts in secure storage. A key change resets verification.
Done when persistence and sender-lookup tests pass (`test/vault_test.dart`).

## ✅ Phase 3: App (no SMS permission)
Home (my key, contacts, empty state), contact screen (safety number, verify, composer with SMS count), invite, key-change warning, decrypt sheet, Android share-in and text-selection entry, `FLAG_SECURE`, fa/en.
Done when the widget flow tests pass (`test/app_flow_test.dart`) and the debug APK builds.

## ✅ Phase 3b: SMS thread (optional permissions)
READ_SMS + SEND_SMS on request: a decrypted per-contact thread that updates live via a ContentObserver, direct send through `SmsManager`, and the phone number auto-filled from the first incoming message. Tested with `tool/sms_bridge.py` on two emulators.

## ✅ Phase 3c: Shared phrase
Per-contact phrase mixed into the session key (D8). Set from the contact menu; the safety card shows when it is on.

## ✅ Phase 3d: Contact picker and automatic invites
- Pick the phone from the system contact picker; invite text carries a Bazaar install hint (no link)
- Incoming keys are detected while the app is open: accept → our key goes back automatically → the inviter's waiting contact connects

## ✅ Phase 4a: Safety and first run
- Encrypted backup/restore (`#SB1:`, Argon2id) to move identity + contacts to a new phone (D10)
- Optional app lock: biometrics or device PIN, off by default (D11)
- Bundled Vazirmatn font; a first-run explainer (3 cards: send key → compare code → chat)

## ✅ Phase 4b-1: Closed-app alerts
- RECEIVE_SMS receiver + notification for incoming keys and messages, never the text (D12)

## Phase 4b: Release (next)
- App icon and name artwork
- Release signing and store listing. iOS build on a Mac with signing
- QR code of the safety number for in-person checks (`qr_flutter`; scanning needs a camera library, so weigh its size first)

## Phase 5: Optional, only if needed
- **Forward secrecy**: a ratchet over SMS is fragile (lost or reordered SMS). A cheaper option is to rotate the identity key manually.
- **Android auto mode**: become the default SMS app and decrypt in place. This is large (a full SMS client), Android only, and Play policy-heavy.
- **Length padding** to hide message size (costs SMS parts).

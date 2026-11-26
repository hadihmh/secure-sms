# Architecture: پیامک امن (Secure SMS)

End-to-end encrypted text over ordinary SMS. No server, no account. SMS permissions are optional (Android).
The user's normal SMS app is the transport; this app only encrypts, decrypts, and holds keys.

## Decisions
| # | Decision | Why |
|---|----------|-----|
| D1 | Flutter (Android + iOS), one codebase | iOS can't read or send SMS directly, so copy/paste/share is the only portable transport |
| D2 | Optional READ_SMS + SEND_SMS, never the default SMS app | Granting them gives a decrypted per-contact thread and direct send. Only bodies containing `#SM1:` are read. Without them, the share/paste flow still works. Play policy restricts these permissions, so sideload/F-Droid only |
| D3 | `cryptography` (pure Dart): X25519, HKDF-SHA256, XChaCha20-Poly1305 | Audited primitives, no native code. The 24-byte random nonce is safe without a counter |
| D4 | TOFU key exchange inside SMS + an optional 20-digit safety number | No server to vouch for keys. Comparing safety numbers detects a MITM key swap |
| D5 | No plaintext stored, ever | The SMS store keeps the ciphertext. The thread is decrypted in memory each time it opens |
| D6 | Identity + contacts in `flutter_secure_storage` (Keystore/Keychain); `allowBackup=false` | A key that leaves the device in a backup weakens everything |
| D7 | Android `FLAG_SECURE` | Keeps plaintext out of screenshots and the recents thumbnail |
| D8 | Optional per-contact shared phrase | Agreed in person, normalized (trim, spaces, ی/ک, digits), stretched with PBKDF2-SHA256 (100k) and appended to the X25519 secret before HKDF (`info` = `secure-sms v1 phrase`). A carrier that swaps keys in transit still can't read anything without the phrase. Empty phrase = the unchanged v1 key. Strict: messages under another phrase don't open. A weak phrase is only as strong as its guessability once keys are swapped, so the safety number stays the primary check |
| D8 | ASCII-only wire format (base64url) | Stays in GSM-7: 160 chars per SMS instead of 70 for Unicode |
| D9 | State: one `Vault` ChangeNotifier | Small app; no state-management dependency needed |
| D10 | Encrypted backup as text (`#SB1:`), Argon2id | The only way the identity leaves the phone, and only under a passphrase (≥10 chars, normalized like D8). Argon2id (19 MiB, t=2, p=1) runs in its own isolate. Text, not a file, so it travels through any share target and is restored through the same paste/share path |
| D11 | Optional app lock (`local_auth`, off by default) | Device biometrics or PIN before anything shows. Re-locks after 30 s in the background, so the contact picker and SMS app hand-off don't re-lock. It covers every route via `MaterialApp.builder`. A phone without a screen lock can't enable it, and if the lock is later removed the app opens rather than locking the user out |

## Wire format v1
- **Key invite**: `SecureSMS key #SK1:<b64url(X25519 pub, 32B)>`, 62 chars, 1 SMS.
- **Message**: `#SM1:<b64url(nonce24 ‖ ciphertext ‖ tag16)>`.
  - The session key is `HKDF-SHA256(ikm = X25519(me, them), salt = sort(pubA, pubB), info = "secure-sms v1")`.
  - The AAD is `"SM1" ‖ senderPub`. It binds the direction: a reflected message can't pass as incoming, and the sender can still re-read their own messages.
  - Overhead is 59 chars. A single SMS holds about 75 UTF-8 bytes (about 37 Persian or 75 Latin chars). Longer messages are sent as a multi-part SMS, and the composer shows the part count.
- **Safety number**: `SHA-256("SSN1" ‖ sort(pubA, pubB))`, cut into 5 groups of 4 digits (`uint32 mod 10000`), about 66 bits. It is the same on both phones.
- **Backup**: `#SB1:<b64url(header ‖ nonce24 ‖ ciphertext ‖ tag16)>`. The header is `"SB1" ‖ memKiB u32 ‖ iterations u8 ‖ parallelism u8 ‖ salt16`; it is the AAD, and the key is `Argon2id(passphrase, salt)` with those parameters. The plaintext is JSON `{v, identity, contacts (with phrases), ignored}`. Restore refuses costs above 256 MiB or 10 iterations, checks everything before asking to overwrite, and never half-restores.
- Parsing finds the tag anywhere in the pasted text, so forwarded or quoted SMS still work.

## Flows
- **Invite**: add a contact (name + phone, typed or picked with the system contact picker, no READ_CONTACTS). The invite is the key line, then a line telling people without the app to install it from Bazaar. With SEND_SMS it is sent directly, otherwise the SMS app opens prefilled. The contact shows "waiting for key".
- **Invite detection** (READ_SMS, while the app is open): the app scans the inbox for `#SK1:` (newest per sender) on launch and on every SMS change. A key from the number of a waiting contact connects that contact at once (no reply, so no loop). Any other unknown key asks "accept?"; accepting saves the contact (phone prefilled) and sends our key back with an "accepted" line, which connects the inviter the same way. Declined keys are remembered in secure storage.
- **Receive a key**: paste, share, or select the text. A sheet asks "whose key?": a new contact, a waiting contact, or an existing contact. Picking an existing contact is treated as a key change: a red warning appears, and accepting the new key resets verification. After adding a new contact, the app offers to send our key back.
- **Send**: the composer encrypts. With SEND_SMS it sends directly via `SmsManager` (the system writes the sent box). Otherwise it opens the SMS app prefilled. The plaintext is cleared only after the SMS app has opened.
- **Move to a new phone**: menu → Encrypted backup → passphrase twice → share sheet (or clipboard). On the new phone: copy the text and tap Restore backup (or share it into the app) → passphrase → confirm overwrite. Contacts keep the same key, so they see no key-change warning.
- **Receive a message**: Android "Share → پیامک امن", select text → "پیامک امن", or the "Open message" button (clipboard). The app tries every contact key, the AAD identifies the sender, and the plaintext appears in a sheet.

## Threat model
- **Protected**: message content against the carrier, the SMS app, and backups. Tampering (AEAD). Key swaps (safety number; changed keys are never auto-accepted).
- **Not protected**: metadata (who, when, length to about 1 byte). A compromised phone. A backup is only as strong as its passphrase: anyone holding the backup text can guess offline, slowed by Argon2id. No forward secrecy: a stolen identity key decrypts past captured SMS. The base64 text is visibly "encrypted".

## Code map
- `lib/crypto/sms_crypto.dart`: all crypto and the wire format (pure Dart, unit-tested)
- `lib/data/vault.dart`: identity and contacts persistence
- `lib/ui/`: `home_screen`, `contact_screen`, `inbound` (paste/share handling), `backup`, `app_lock`, `intro` (first run), `common`, `theme` (Vazirmatn, bundled under `assets/fonts`, OFL)
- `android/.../MainActivity.kt`: a `FlutterFragmentActivity` (needed by `local_auth`): share-in / PROCESS_TEXT → MethodChannel `secure_sms/inbound`, SMS + share sheet on `secure_sms/sms`, plus `FLAG_SECURE`
- `lib/l10n/app_{fa,en}.arb`: all strings (fa is the default, en is used only when the device is set to English)

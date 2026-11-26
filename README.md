# پیامک امن (Secure SMS)

End-to-end encrypted messages over plain SMS: no server, no account. Optional SMS permissions show a decrypted thread per contact.
Write a message, tap **Send by SMS**, and your normal SMS app opens with ciphertext.
The receiver shares or selects that SMS into the app, or copies it and taps **Open message**.

- X25519 + XChaCha20-Poly1305. Keys never leave the phone's secure storage.
- Keys are exchanged by SMS. Compare the 20-digit safety number once to rule out tampering.
- A changed key is never accepted silently.
- A passphrase-sealed backup (Argon2id) moves you to a new phone without key-change warnings. There is an optional app lock, and an alert (never the text) when a secure message arrives while the app is closed.

Design, wire format and threat model: [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md). Plan: [docs/ROADMAP.md](docs/ROADMAP.md).

## Run
```bash
flutter pub get
flutter test
flutter run                     # device or emulator
flutter build apk --release     # needs your signing config; debug: --debug
```
iOS: `flutter build ios`. This needs Xcode and a signing team. Share-in is Android only; on iOS use copy and **Open message**.

## Strings
Edit `lib/l10n/app_fa.arb` (template) and `app_en.arb`, then run `flutter gen-l10n`.

## License
GPL-3.0. See [LICENSE](LICENSE). Vazirmatn font: SIL OFL 1.1 (`assets/fonts/OFL.txt`).

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../crypto/sms_crypto.dart';

typedef BackupData = ({
  Identity id,
  List<Contact> contacts,
  List<String> ignored,
});

class Contact {
  Contact({
    required this.id,
    required this.name,
    this.phone = '',
    this.key,
    this.verified = false,
    this.secret = '',
  });
  final String id;
  String name;
  String phone;
  Uint8List? key; // null = invited, waiting for their key
  bool verified;
  String secret; // optional shared phrase, '' = none

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'phone': phone,
    'key': key == null ? null : b64(key!),
    'verified': verified,
    'secret': secret,
  };
  factory Contact.fromJson(Map<String, dynamic> j) => Contact(
    id: j['id'],
    name: j['name'],
    phone: j['phone'] ?? '',
    key: j['key'] == null ? null : unb64(j['key']),
    verified: j['verified'] ?? false,
    secret: j['secret'] ?? '',
  );
}

/// Identity + contacts, kept only in the OS keystore-backed secure storage.
/// No message plaintext is ever stored.
class Vault extends ChangeNotifier {
  Vault([FlutterSecureStorage? storage])
    : _s = storage ?? const FlutterSecureStorage();
  final FlutterSecureStorage _s;
  late Identity me;
  final contacts = <Contact>[];
  final ignored = <String>{}; // declined invite keys (b64)

  Future<void> load() async {
    final priv = await _s.read(key: 'identity');
    if (priv == null) {
      me = await Identity.generate();
      await _s.write(key: 'identity', value: b64(await me.privateBytes()));
    } else {
      me = await Identity.fromPrivate(unb64(priv));
    }
    final raw = await _s.read(key: 'contacts');
    contacts
      ..clear()
      ..addAll([for (final j in jsonDecode(raw ?? '[]')) Contact.fromJson(j)]);
    ignored
      ..clear()
      ..addAll([
        for (final k in jsonDecode(await _s.read(key: 'ignored') ?? '[]'))
          k as String,
      ]);
    lock = await _s.read(key: 'lock') == '1';
    introDone = await _s.read(key: 'intro') == '1';
    notifyListeners();
  }

  /// Ask for the device lock before showing anything. Per phone, not in backups.
  bool lock = false;
  bool introDone = false;

  Future<void> setLock(bool on) async {
    await _s.write(key: 'lock', value: on ? '1' : '0');
    lock = on;
    notifyListeners();
  }

  Future<void> finishIntro() async {
    await _s.write(key: 'intro', value: '1');
    introDone = true;
    notifyListeners();
  }

  Future<void> _save() async {
    // Write before notifying so the UI never shows unsaved state.
    await _s.write(
      key: 'contacts',
      value: jsonEncode([for (final c in contacts) c.toJson()]),
    );
    notifyListeners();
  }

  Future<void> ignore(String keyB64) async {
    ignored.add(keyB64);
    await _s.write(key: 'ignored', value: jsonEncode([...ignored]));
  }

  Contact? byKey(List<int> key) {
    for (final c in contacts) {
      if (c.key != null && sameKey(c.key!, key)) return c;
    }
    return null;
  }

  Future<Contact> add(String name, String phone, Uint8List? key) async {
    final c = Contact(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name,
      phone: phone,
      key: key,
    );
    contacts.add(c);
    await _save();
    return c;
  }

  Future<void> edit(Contact c, String name, String phone) async {
    c
      ..name = name
      ..phone = phone;
    await _save();
  }

  /// A new or changed key is never trusted as verified.
  Future<void> setKey(Contact c, Uint8List key) async {
    c
      ..key = key
      ..verified = false;
    await _save();
  }

  Future<void> setSecret(Contact c, String s) async {
    c.secret = s.trim();
    await _save();
  }

  Future<void> setVerified(Contact c, bool v) async {
    c.verified = v;
    await _save();
  }

  Future<void> remove(Contact c) async {
    contacts.remove(c);
    await _save();
  }

  /// Identity + contacts (with their phrases), sealed under [pass], for moving to a new phone.
  Future<String> exportBackup(String pass) async => sealBackup(
    utf8.encode(
      jsonEncode({
        'v': 1,
        'identity': b64(await me.privateBytes()),
        'contacts': [for (final c in contacts) c.toJson()],
        'ignored': [...ignored],
      }),
    ),
    pass,
  );

  /// Opens and checks a backup without touching this phone. Throws [BackupError].
  static Future<BackupData> readBackup(String payload, String pass) async {
    final plain = await openBackup(payload, pass);
    try {
      final j = jsonDecode(utf8.decode(plain));
      return (
        id: await Identity.fromPrivate(unb64(j['identity'])),
        contacts: [for (final c in j['contacts']) Contact.fromJson(c)],
        ignored: [for (final k in j['ignored'] ?? const []) k as String],
      );
    } catch (_) {
      throw BackupError(); // authentic but unreadable: never half-restore
    }
  }

  /// Replaces everything here with [b].
  Future<void> restore(BackupData b) async {
    final (:id, contacts: cs, ignored: ign) = b;
    await _s.write(key: 'identity', value: b64(await id.privateBytes()));
    await _s.write(key: 'ignored', value: jsonEncode(ign));
    me = id;
    contacts
      ..clear()
      ..addAll(cs);
    ignored
      ..clear()
      ..addAll(ign);
    if (!introDone) await finishIntro(); // not a new user
    await _save();
  }

  Future<String> encryptFor(Contact c, String text) =>
      me.encrypt(text, c.key!, c.secret);

  Future<(Contact, Decrypted)?> decrypt(String payload) async {
    final d = await me.decrypt(payload, [
      for (final c in contacts)
        if (c.key != null) c.key!,
    ], secretOf: (k) => byKey(k)?.secret ?? '');
    return d == null ? null : (byKey(d.contactKey)!, d);
  }
}

/// Same number in different formats (0912…, +98912…, emulator 5554 vs 1555521…5554).
// shortcut: compares the last ≤10 digits, so two numbers sharing that suffix match; use libphonenumber if that bites.
bool samePhone(String a, String b) {
  final x = a.replaceAll(RegExp(r'\D'), ''),
      y = b.replaceAll(RegExp(r'\D'), '');
  final n = [x.length, y.length, 10].reduce((p, q) => p < q ? p : q);
  return n >= 4 && x.substring(x.length - n) == y.substring(y.length - n);
}

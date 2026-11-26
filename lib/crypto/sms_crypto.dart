import 'dart:convert';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

/// Wire format v1 (see docs/ARCHITECTURE.md). Pure Dart, no Flutter.
const keyTag = '#SK1:';
const msgTag = '#SM1:';

final _x25519 = X25519();
final _aead = Xchacha20.poly1305Aead();
final _hkdf = Hkdf(hmac: Hmac.sha256(), outputLength: 32);
// Stretches a shared phrase so a man in the middle can't cheaply guess it from one ciphertext.
final _pbkdf2 = Pbkdf2(
  macAlgorithm: Hmac.sha256(),
  iterations: 100000,
  bits: 256,
);
final _keyRe = RegExp(r'#SK1:([A-Za-z0-9_-]{43})');
final _msgRe = RegExp(r'#SM1:([A-Za-z0-9_-]{54,})');

String b64(List<int> b) => base64Url.encode(b).replaceAll('=', '');
Uint8List unb64(String s) =>
    base64Url.decode(s.padRight((s.length + 3) & ~3, '='));

/// This device's long-term X25519 key pair.
class Identity {
  Identity._(this.keyPair, this.publicKey);
  final SimpleKeyPair keyPair;
  final Uint8List publicKey;

  static Future<Identity> generate() async =>
      fromPrivate(await (await _x25519.newKeyPair()).extractPrivateKeyBytes());

  static Future<Identity> fromPrivate(List<int> priv) async {
    final kp = await _x25519.newKeyPairFromSeed(priv);
    final pub = await kp.extractPublicKey();
    return Identity._(kp, Uint8List.fromList(pub.bytes));
  }

  Future<List<int>> privateBytes() => keyPair.extractPrivateKeyBytes();

  /// ASCII-only so the invite fits one GSM-7 SMS.
  String invite() => 'SecureSMS key $keyTag${b64(publicKey)}';

  final _sessions = <String, Future<SecretKey>>{};

  /// [secret] is an optional phrase both people agreed on in person. It is mixed
  /// into the key, so a swapped public key alone can't read the messages. Empty = v1 key.
  Future<SecretKey> _sessionKey(List<int> theirPub, [String secret = '']) {
    final s = normalizeSecret(secret);
    return _sessions.putIfAbsent('${b64(theirPub)}|$s', () async {
      final salt = _sortedConcat(publicKey, theirPub);
      SecretKey ikm = await _x25519.sharedSecretKey(
        keyPair: keyPair,
        remotePublicKey: SimplePublicKey(theirPub, type: KeyPairType.x25519),
      );
      if (s.isNotEmpty) {
        final phrase = await _pbkdf2.deriveKey(
          secretKey: SecretKey(utf8.encode(s)),
          nonce: salt,
        );
        ikm = SecretKey([
          ...await ikm.extractBytes(),
          ...await phrase.extractBytes(),
        ]);
      }
      return _hkdf.deriveKey(
        secretKey: ikm,
        nonce: salt,
        info: utf8.encode(s.isEmpty ? 'secure-sms v1' : 'secure-sms v1 phrase'),
      );
    });
  }

  Future<String> encrypt(
    String text,
    List<int> theirPub, [
    String secret = '',
  ]) async {
    final box = await _aead.encrypt(
      utf8.encode(text),
      secretKey: await _sessionKey(theirPub, secret),
      aad: _aad(publicKey),
    );
    return msgTag + b64([...box.nonce, ...box.cipherText, ...box.mac.bytes]);
  }

  /// Tries every known key. AAD binds the sender's key, so a hit also tells
  /// whether the message came from [contacts] key (incoming) or from us.
  Future<Decrypted?> decrypt(
    String payload,
    Iterable<List<int>> contacts, {
    String Function(List<int> pub)? secretOf,
  }) async {
    final Uint8List raw;
    try {
      raw = unb64(payload);
    } on FormatException {
      return null;
    }
    if (raw.length < 24 + 16) return null;
    final box = SecretBox(
      raw.sublist(24, raw.length - 16),
      nonce: raw.sublist(0, 24),
      mac: Mac(raw.sublist(raw.length - 16)),
    );
    for (final pub in contacts) {
      final key = await _sessionKey(pub, secretOf?.call(pub) ?? '');
      for (final outgoing in [false, true]) {
        try {
          final clear = await _aead.decrypt(
            box,
            secretKey: key,
            aad: _aad(outgoing ? publicKey : pub),
          );
          return Decrypted(utf8.decode(clear), pub, outgoing);
        } on SecretBoxAuthenticationError {
          continue;
        }
      }
    }
    return null;
  }
}

class Decrypted {
  Decrypted(this.text, this.contactKey, this.outgoing);
  final String text;
  final List<int> contactKey;
  final bool outgoing;
}

/// What a pasted/shared text contains (first tag found wins: key, then message).
sealed class Parsed {}

class KeyInvite extends Parsed {
  KeyInvite(this.key);
  final Uint8List key;
}

class Ciphertext extends Parsed {
  Ciphertext(this.payload);
  final String payload;
}

class Backup extends Parsed {
  Backup(this.payload);
  final String payload;
}

Parsed? parse(String text) {
  final k = _keyRe.firstMatch(text);
  if (k != null) return KeyInvite(unb64(k.group(1)!));
  final m = _msgRe.firstMatch(text);
  if (m != null) return Ciphertext(m.group(1)!);
  final b = _backupRe.firstMatch(text);
  return b == null ? null : Backup(b.group(1)!);
}

/// Backup v1: '#SB1:' + b64(header | nonce 24 | ciphertext | mac 16).
/// Header = 'SB1' | Argon2id memory KiB (u32) | iterations | parallelism | salt 16; bound as AAD.
const backupTag = '#SB1:';
final _backupRe = RegExp(r'#SB1:([A-Za-z0-9_-]{100,})');
const _headerLen = 3 + 4 + 1 + 1 + 16;

/// Wrong passphrase, or the text is damaged.
class BackupError implements Exception {}

Future<String> sealBackup(
  List<int> plain,
  String pass, {
  int memory = 19456, // 19 MiB, t=2, p=1: OWASP's Argon2id minimum
  int iterations = 2,
}) async {
  final rnd = Random.secure();
  final header = Uint8List(_headerLen)
    ..setAll(0, utf8.encode('SB1'))
    ..[7] = iterations
    ..[8] = 1
    ..setAll(9, List.generate(16, (_) => rnd.nextInt(256)));
  ByteData.sublistView(header).setUint32(3, memory);
  final box = await _aead.encrypt(
    plain,
    secretKey: await _backupKey(pass, header),
    aad: header,
  );
  return backupTag +
      b64([...header, ...box.nonce, ...box.cipherText, ...box.mac.bytes]);
}

Future<List<int>> openBackup(String payload, String pass) async {
  final Uint8List raw;
  try {
    raw = unb64(payload);
  } on FormatException {
    throw BackupError();
  }
  if (raw.length < _headerLen + 40 ||
      utf8.decode(raw.sublist(0, 3), allowMalformed: true) != 'SB1') {
    throw BackupError();
  }
  final header = raw.sublist(0, _headerLen);
  // Refuse absurd costs from a crafted text instead of hanging the phone.
  final mem = ByteData.sublistView(header).getUint32(3);
  if (mem < 8 ||
      mem > 262144 ||
      header[7] < 1 ||
      header[7] > 10 ||
      header[8] != 1) {
    throw BackupError();
  }
  try {
    return await _aead.decrypt(
      SecretBox(
        raw.sublist(_headerLen + 24, raw.length - 16),
        nonce: raw.sublist(_headerLen, _headerLen + 24),
        mac: Mac(raw.sublist(raw.length - 16)),
      ),
      secretKey: await _backupKey(pass, header),
      aad: header,
    );
  } on SecretBoxAuthenticationError {
    throw BackupError();
  }
}

/// Runs in its own isolate: pure-Dart Argon2id takes seconds and would freeze the UI.
Future<SecretKey> _backupKey(String pass, Uint8List header) async {
  final p = normalizeSecret(pass);
  final bytes = await Isolate.run(() async {
    final d = ByteData.sublistView(header);
    final k = await Argon2id(
      memory: d.getUint32(3),
      iterations: header[7],
      parallelism: header[8],
      hashLength: 32,
    ).deriveKey(secretKey: SecretKey(utf8.encode(p)), nonce: header.sublist(9));
    return k.extractBytes();
  });
  return SecretKey(bytes);
}

/// 20 digits (~66 bits), same on both phones: 5 groups of 4.
Future<String> safetyNumber(List<int> a, List<int> b) async {
  final h = (await Sha256().hash([
    ...utf8.encode('SSN1'),
    ..._sortedConcat(a, b),
  ])).bytes;
  final d = ByteData.sublistView(Uint8List.fromList(h));
  return List.generate(
    5,
    (i) => (d.getUint32(i * 4) % 10000).toString().padLeft(4, '0'),
  ).join(' ');
}

/// SMS parts for an ASCII (GSM-7) body: 160 single, 153 per part when split.
int smsParts(int chars) => chars <= 160 ? 1 : (chars + 152) ~/ 153;

/// Length of [Identity.encrypt] output without encrypting: tag + b64(24+16+n).
int cipherLength(String text) =>
    msgTag.length + ((40 + utf8.encode(text).length) * 4 + 2) ~/ 3;

/// Same phrase typed on two keyboards must give the same key: trim, collapse spaces,
/// Arabic ي/ك → Persian ی/ک, Persian/Arabic digits → ASCII.
String normalizeSecret(String s) {
  final b = StringBuffer();
  for (final r in s.trim().replaceAll(RegExp(r'\s+'), ' ').runes) {
    b.writeCharCode(switch (r) {
      0x064A || 0x0649 => 0x06CC,
      0x0643 => 0x06A9,
      >= 0x06F0 && <= 0x06F9 => r - 0x06F0 + 0x30,
      >= 0x0660 && <= 0x0669 => r - 0x0660 + 0x30,
      _ => r,
    });
  }
  return b.toString();
}

List<int> _aad(List<int> senderPub) => [...utf8.encode('SM1'), ...senderPub];

List<int> _sortedConcat(List<int> a, List<int> b) =>
    _cmp(a, b) <= 0 ? [...a, ...b] : [...b, ...a];

int _cmp(List<int> a, List<int> b) {
  for (var i = 0; i < a.length && i < b.length; i++) {
    if (a[i] != b[i]) return a[i] - b[i];
  }
  return a.length - b.length;
}

bool sameKey(List<int> a, List<int> b) =>
    a.length == b.length && _cmp(a, b) == 0;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:secure_sms/crypto/sms_crypto.dart';
import 'package:secure_sms/data/vault.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'identity and contacts persist; key change resets verification',
    () async {
      FlutterSecureStorage.setMockInitialValues({});
      final v = Vault();
      await v.load();
      final bob = await Identity.generate();
      final c = await v.add('Bob', '+98912', bob.publicKey);
      await v.setVerified(c, true);

      final again = Vault();
      await again.load(); // same mock storage
      expect(sameKey(again.me.publicKey, v.me.publicKey), isTrue);
      final c2 = again.byKey(bob.publicKey)!;
      expect((c2.name, c2.phone, c2.verified), ('Bob', '+98912', true));

      await again.setKey(c2, (await Identity.generate()).publicKey);
      expect(c2.verified, isFalse);
      expect(again.byKey(bob.publicKey), isNull);
    },
  );

  test(
    'backup restores identity, contacts and phrase on a new phone',
    () async {
      FlutterSecureStorage.setMockInitialValues({});
      final old = Vault();
      await old.load();
      final bob = await Identity.generate();
      final c = await old.add('Bob', '+98912', bob.publicKey);
      await old.setSecret(c, 'گل سرخ');
      await old.setVerified(c, true);
      final blob = await old.exportBackup('long passphrase ۱۲۳');
      final payload = (parse('saved:\n$blob') as Backup).payload;

      FlutterSecureStorage.setMockInitialValues({}); // new phone
      final fresh = Vault();
      await fresh.load();
      await expectLater(
        Vault.readBackup(payload, 'wrong'),
        throwsA(isA<BackupError>()),
      );
      final tampered = payload.replaceRange(
        60,
        61,
        payload[60] == 'A' ? 'B' : 'A',
      );
      await expectLater(
        Vault.readBackup(tampered, 'long passphrase 123'),
        throwsA(isA<BackupError>()),
      );

      // A crafted header asking for 4 GiB of memory is refused before any work.
      final raw = unb64(payload)..setAll(3, [0xFF, 0xFF, 0xFF, 0xFF]);
      await expectLater(
        Vault.readBackup(b64(raw), 'long passphrase 123'),
        throwsA(isA<BackupError>()),
      );

      // Persian digits normalize, like the shared phrase.
      await fresh.restore(
        await Vault.readBackup(payload, 'long passphrase 123'),
      );
      expect(sameKey(fresh.me.publicKey, old.me.publicKey), isTrue);
      final c2 = fresh.byKey(bob.publicKey)!;
      expect((c2.name, c2.secret, c2.verified), ('Bob', 'گل سرخ', true));
      final sms = await bob.encrypt('hi', old.me.publicKey, 'گل سرخ');
      expect(
        (await fresh.decrypt((parse(sms) as Ciphertext).payload))!.$2.text,
        'hi',
      );

      final again = Vault();
      await again.load(); // persisted
      expect(sameKey(again.me.publicKey, old.me.publicKey), isTrue);
    },
  );

  test('decrypt finds the sender among contacts', () async {
    FlutterSecureStorage.setMockInitialValues({});
    final v = Vault();
    await v.load();
    final bob = await Identity.generate();
    await v.add('Waiting', '', null);
    final c = await v.add('Bob', '', bob.publicKey);
    final sms = await bob.encrypt('salam', v.me.publicKey);
    final (who, d) = (await v.decrypt((parse(sms) as Ciphertext).payload))!;
    expect((who, d.text, d.outgoing), (c, 'salam', false));
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:secure_sms/crypto/sms_crypto.dart';
import 'package:secure_sms/data/sms_box.dart';
import 'package:secure_sms/data/vault.dart';

void main() {
  test(
    'thread keeps only this contact, both directions, oldest first',
    () async {
      final me = await Identity.generate(),
          bob = await Identity.generate(),
          eve = await Identity.generate();
      final c = Contact(id: '1', name: 'Bob', key: bob.publicKey);
      final rows = [
        SmsRow(
          '+98912',
          await bob.encrypt('reply', me.publicKey),
          DateTime(2026, 1, 2),
        ),
        SmsRow(
          '+98912',
          await me.encrypt('hello', bob.publicKey),
          DateTime(2026, 1, 1),
        ),
        SmsRow(
          '+98935',
          await eve.encrypt('not bob', me.publicKey),
          DateTime(2026, 1, 3),
        ),
        SmsRow('+98912', 'plain text', DateTime(2026, 1, 4)),
      ];
      final t = await thread(me, c, rows);
      expect(
        [for (final m in t) (m.text, m.outgoing)],
        [('hello', true), ('reply', false)],
      );
    },
  );

  test('samePhone ignores format, needs 4+ matching tail digits', () {
    expect(samePhone('0912 345 6789', '+989123456789'), isTrue);
    expect(samePhone('5554', '15555215554'), isTrue);
    expect(samePhone('09123456789', '09123456788'), isFalse);
    expect(samePhone('', '5554'), isFalse);
  });
}

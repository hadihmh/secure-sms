import 'package:flutter_test/flutter_test.dart';
import 'package:secure_sms/crypto/sms_crypto.dart';

void main() {
  late Identity alice, bob, eve;
  setUpAll(() async {
    alice = await Identity.generate();
    bob = await Identity.generate();
    eve = await Identity.generate();
  });

  test('round trip, Persian text, both directions', () async {
    final sms = await alice.encrypt('سلام، فردا ساعت ۵', bob.publicKey);
    expect(sms, startsWith(msgTag));
    expect(RegExp(r'^[A-Za-z0-9_#:-]+$').hasMatch(sms), isTrue); // GSM-7 safe
    final got = await bob.decrypt((parse(sms) as Ciphertext).payload, [
      eve.publicKey,
      alice.publicKey,
    ]);
    expect(got!.text, 'سلام، فردا ساعت ۵');
    expect(got.outgoing, isFalse);
    expect(sameKey(got.contactKey, alice.publicKey), isTrue);
  });

  test(
    'sender can re-read own message; reflection is not mistaken as incoming',
    () async {
      final p = (parse(
        await alice.encrypt('hi', bob.publicKey),
      ) as Ciphertext).payload;
      final own = await alice.decrypt(p, [bob.publicKey]);
      expect(own!.outgoing, isTrue);
    },
  );

  test('wrong key, tampering and junk are rejected', () async {
    final p =
        (parse(await alice.encrypt('x', bob.publicKey)) as Ciphertext).payload;
    expect(await eve.decrypt(p, [alice.publicKey, bob.publicKey]), isNull);
    final flipped =
        p.substring(0, 30) + (p[30] == 'A' ? 'B' : 'A') + p.substring(31);
    expect(await bob.decrypt(flipped, [alice.publicKey]), isNull);
    expect(await bob.decrypt('!!!', [alice.publicKey]), isNull);
    expect(parse('hello'), isNull);
  });

  test('invite parses from surrounding text and fits one SMS', () async {
    final inv = alice.invite();
    expect(inv.length, lessThanOrEqualTo(160));
    final k = parse('fwd: $inv thanks') as KeyInvite;
    expect(sameKey(k.key, alice.publicKey), isTrue);
  });

  test('private key restore gives same identity', () async {
    final again = await Identity.fromPrivate(await alice.privateBytes());
    expect(sameKey(again.publicKey, alice.publicKey), isTrue);
  });

  test('safety number is symmetric and key-specific', () async {
    final ab = await safetyNumber(alice.publicKey, bob.publicKey);
    expect(ab, await safetyNumber(bob.publicKey, alice.publicKey));
    expect(ab, matches(RegExp(r'^\d{4}( \d{4}){4}$')));
    expect(ab, isNot(await safetyNumber(alice.publicKey, eve.publicKey)));
  });

  test('cipherLength predicts real output', () async {
    for (final t in ['', 'a', 'سلام دنیا', 'x' * 117]) {
      expect(cipherLength(t), (await alice.encrypt(t, bob.publicKey)).length);
    }
  });

  test('sms part count', () {
    expect(smsParts(160), 1);
    expect(smsParts(161), 2);
    expect(smsParts(306), 2);
    expect(smsParts(307), 3);
  });

  test('shared phrase: both sides need the same (normalized) phrase', () async {
    final p = (parse(
      await alice.encrypt('سلام', bob.publicKey, 'كليد ۱۲'),
    ) as Ciphertext).payload;
    expect(await bob.decrypt(p, [alice.publicKey]), isNull); // no phrase
    expect(
      await bob.decrypt(p, [alice.publicKey], secretOf: (_) => 'wrong'),
      isNull,
    );
    final ok = await bob.decrypt(p, [
      alice.publicKey,
    ], secretOf: (_) => ' کلید  12 ');
    expect(ok!.text, 'سلام');
    expect(
      (await alice.decrypt(p, [
        bob.publicKey,
      ], secretOf: (_) => 'كليد ۱۲'))!.outgoing,
      isTrue,
    );
  });
}

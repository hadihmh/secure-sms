import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:secure_sms/crypto/sms_crypto.dart';
import 'package:secure_sms/data/vault.dart';
import 'package:secure_sms/main.dart';

void main() {
  late Vault vault;
  late Identity bob;
  String? clipboard;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({'intro': '1'});
    clipboard = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'Clipboard.getData') return {'text': clipboard};
          if (call.method == 'Clipboard.setData')
            clipboard = (call.arguments as Map)['text'];
          return null;
        });
  });

  Future<void> start(WidgetTester t) async {
    t.platformDispatcher.localesTestValue = const [Locale("fa")];
    addTearDown(t.platformDispatcher.clearLocalesTestValue);
    await t.runAsync(() async {
      vault = Vault();
      await vault.load();
      bob = await Identity.generate();
    });
    await t.pumpWidget(SecureSmsApp(vault: vault));
    await t.pumpAndSettle();
  }

  // Crypto futures complete on real time; drive them, then settle frames.
  Future<void> tapAndRun(WidgetTester t, Finder f) async {
    await t.tap(f);
    await t.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await t.pumpAndSettle();
  }

  testWidgets('empty state, then a pasted invite becomes a contact', (t) async {
    await start(t);
    expect(find.text('هنوز مخاطبی ندارید'), findsOneWidget);

    clipboard = 'hi ${bob.invite()}';
    await tapAndRun(t, find.text('باز کردن پیام'));
    expect(find.text('کلید جدید دریافت شد'), findsOneWidget);
    await tapAndRun(
      t,
      find.text('مخاطب جدید'),
    ); // looks up the key's SMS sender first
    await t.enterText(find.byType(TextField).first, 'Bob');
    await t.pump();
    await tapAndRun(t, find.text('ذخیره'));

    expect(vault.contacts.single.name, 'Bob');
    expect(sameKey(vault.contacts.single.key!, bob.publicKey), isTrue);
    expect(find.text('کد امنیتی'), findsOneWidget); // contact screen opened
    expect(
      find.text(await safetyNumber(vault.me.publicKey, bob.publicKey)),
      findsOneWidget,
    );
  });

  testWidgets('pasted ciphertext opens decrypted; changed key shows warning', (
    t,
  ) async {
    await start(t);
    await t.runAsync(() => vault.add('Bob', '', bob.publicKey));
    await t.pump();

    clipboard = await t.runAsync(
      () => bob.encrypt('سلام علی', vault.me.publicKey),
    );
    await tapAndRun(t, find.text('باز کردن پیام'));
    expect(find.text('سلام علی'), findsOneWidget);
    expect(find.text('از Bob'), findsOneWidget);
    await t.tap(find.text('بستن'));
    await t.pumpAndSettle();

    final mallory = (await t.runAsync(Identity.generate))!;
    clipboard = mallory.invite();
    await tapAndRun(t, find.text('باز کردن پیام'));
    await t.tap(find.text('Bob').last);
    await t.pumpAndSettle();
    expect(find.text('کلید Bob عوض شده!'), findsOneWidget);
    await t.tap(find.text('انصراف'));
    await t.pumpAndSettle();
    expect(
      sameKey(vault.contacts.single.key!, bob.publicKey),
      isTrue,
    ); // not replaced

    clipboard = 'random text';
    await tapAndRun(t, find.text('باز کردن پیام'));
    expect(find.textContaining('پیدا نشد'), findsOneWidget);
  });

  testWidgets('composer shows SMS count and copies ciphertext', (t) async {
    await start(t);
    await t.runAsync(() => vault.add('Bob', '', bob.publicKey));
    await t.pump();
    await t.tap(find.text('Bob'));
    await t.pumpAndSettle();
    await t.enterText(find.byType(TextField), 'hello');
    await t.pump();
    expect(
      find.text('${cipherLength('hello')} نویسه · 1 پیامک'),
      findsOneWidget,
    );
    await tapAndRun(t, find.byIcon(Icons.copy_rounded));
    final d = await t.runAsync(
      () => bob.decrypt((parse(clipboard!) as Ciphertext).payload, [
        vault.me.publicKey,
      ]),
    );
    expect(d!.text, 'hello');
  });

  testWidgets('first run shows the intro once, then home', (t) async {
    FlutterSecureStorage.setMockInitialValues({});
    await start(t);
    expect(find.text('کلیدت را بفرست'), findsOneWidget);
    await t.tap(find.text('بعدی'));
    await t.pumpAndSettle();
    await t.tap(find.text('بعدی'));
    await t.pumpAndSettle();
    await t.tap(find.text('شروع'));
    await t.runAsync(() => Future<void>.delayed(Duration.zero));
    await t.pumpAndSettle();
    expect(find.text('کلید شما'), findsOneWidget);
    expect(vault.introDone, isTrue);
  });

  testWidgets('a declined key still connects a contact we invited later', (
    t,
  ) async {
    final friend = await Identity.generate();
    final waiting = Contact(id: '1', name: 'Ali', phone: '+15555215554');
    FlutterSecureStorage.setMockInitialValues({
      'intro': '1',
      'contacts': jsonEncode([waiting.toJson()]),
      'ignored': jsonEncode([b64(friend.publicKey)]),
    });
    t.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('secure_sms/sms'),
      (call) async => switch (call.method) {
        'granted' => true,
        'list' => [
          {'address': '5554', 'body': friend.invite(), 'date': 1, 'type': 1},
        ],
        _ => null,
      },
    );
    await start(t);
    await t.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await t.pumpAndSettle();
    expect(sameKey(vault.contacts.single.key!, friend.publicKey), isTrue);
  });
}

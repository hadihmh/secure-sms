import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_auth_platform_interface/local_auth_platform_interface.dart';
import 'package:secure_sms/data/vault.dart';
import 'package:secure_sms/main.dart';

class _FakeAuth extends LocalAuthPlatform {
  final answers = <Object>[]; // true/false, or an error to throw
  int calls = 0;
  @override
  Future<bool> authenticate({
    required String localizedReason,
    required Iterable<AuthMessages> authMessages,
    AuthenticationOptions options = const AuthenticationOptions(),
  }) async {
    calls++;
    final a = answers.removeAt(0);
    if (a is bool) return a;
    throw a;
  }
}

void main() {
  testWidgets('locked at start; a failed prompt can be retried, then unlocks', (
    t,
  ) async {
    final auth = _FakeAuth()
      ..answers.addAll([StateError('platform blew up'), true]);
    LocalAuthPlatform.instance = auth;
    FlutterSecureStorage.setMockInitialValues({'intro': '1', 'lock': '1'});
    t.platformDispatcher.localesTestValue = const [Locale('fa')];
    addTearDown(t.platformDispatcher.clearLocalesTestValue);
    late Vault vault;
    await t.runAsync(() async {
      vault = Vault();
      await vault.load();
    });
    await t.pumpWidget(SecureSmsApp(vault: vault));
    await t.pumpAndSettle();

    expect(auth.calls, 1); // prompted on launch, and it threw
    expect(find.text('پیامک امن قفل است'), findsOneWidget);
    expect(find.text('کلید شما'), findsNothing); // home is hidden

    await t.tap(find.text('باز کردن قفل'));
    await t.pumpAndSettle();
    expect(auth.calls, 2);
    expect(find.text('پیامک امن قفل است'), findsNothing);
    expect(find.text('کلید شما'), findsOneWidget);
  });
}

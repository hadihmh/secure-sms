import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'data/sms_box.dart';
import 'data/vault.dart';
import 'l10n/app_localizations.dart';
import 'ui/app_lock.dart';
import 'ui/home_screen.dart';
import 'ui/inbound.dart';
import 'ui/intro.dart';
import 'ui/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final vault = Vault();
  await vault.load();
  runApp(SecureSmsApp(vault: vault));
}

class SecureSmsApp extends StatefulWidget {
  const SecureSmsApp({super.key, required this.vault});
  final Vault vault;
  @override
  State<SecureSmsApp> createState() => _SecureSmsAppState();
}

class _SecureSmsAppState extends State<SecureSmsApp> {
  static const _inbound = MethodChannel('secure_sms/inbound');
  final _nav = GlobalKey<NavigatorState>();
  final _seen = <String>{};
  bool _askedPermission = false;

  /// Watches the SMS store for invites; asks for SMS permission once per launch.
  Future<void> _scan() async {
    final ctx = _nav.currentContext;
    // Don't cover the first-run explainer with the permission dialog.
    if (ctx == null || !widget.vault.introDone) return;
    if (!await smsBox.granted()) {
      if (_askedPermission) return;
      _askedPermission = true;
      await smsBox.request(); // on success it notifies, which re-runs _scan
      return;
    }
    if (ctx.mounted) await checkInvites(ctx, widget.vault, _seen);
  }

  @override
  void initState() {
    super.initState();
    // Android: text shared into the app, or selected in the SMS app ("پیامک امن").
    _inbound.setMethodCallHandler(
      (call) async => _open(call.arguments as String?),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final t = await _inbound.invokeMethod<String>('initial');
        if (t != null) _open(t);
      } on MissingPluginException {
        // iOS / tests: no share-in channel.
      }
      smsBox.addListener(_scan);
      widget.vault.addListener(_afterIntro);
      await _scan();
    });
  }

  void _afterIntro() {
    if (!widget.vault.introDone) return;
    widget.vault.removeListener(_afterIntro);
    _scan();
  }

  void _open(String? text) {
    final ctx = _nav.currentContext;
    if (ctx != null) handleInbound(ctx, widget.vault, text);
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    navigatorKey: _nav,
    onGenerateTitle: (c) => AppLocalizations.of(c).appTitle,
    debugShowCheckedModeBanner: false,
    theme: buildTheme(),
    // Persian by default; English only when the phone is set to English.
    localeResolutionCallback: (d, _) =>
        Locale(d?.languageCode == 'en' ? 'en' : 'fa'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    builder: (_, child) => AppLock(vault: widget.vault, child: child!),
    home: ListenableBuilder(
      listenable: widget.vault,
      builder: (_, _) => widget.vault.introDone
          ? HomeScreen(vault: widget.vault)
          : IntroScreen(vault: widget.vault),
    ),
  );
}

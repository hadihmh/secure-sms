import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';

import '../data/vault.dart';
import 'common.dart';
import 'theme.dart';

final _auth = LocalAuthentication();

/// Device lock prompt (fingerprint, face or PIN). True = let in.
Future<bool> deviceAuth(BuildContext context) async {
  try {
    return await _auth.authenticate(
      localizedReason: context.l.unlock,
      persistAcrossBackgrounding: true,
    );
  } on LocalAuthException catch (e) {
    // No screen lock on the phone: nothing to check against, so never lock the user out.
    return e.code == LocalAuthExceptionCode.noCredentialsSet;
  } catch (_) {
    return false; // stay locked but retryable
  }
}

/// Turns the lock on only after one successful prompt, so it is known to work here.
Future<void> toggleLock(BuildContext context, Vault vault) async {
  if (vault.lock) return vault.setLock(false);
  if (!await _auth.isDeviceSupported()) {
    if (context.mounted) context.toast(context.l.appLockUnavailable);
    return;
  }
  if (context.mounted && await deviceAuth(context)) await vault.setLock(true);
}

/// Covers every route (dialogs and the share-in message sheet too) while locked.
class AppLock extends StatefulWidget {
  const AppLock({super.key, required this.vault, required this.child});
  final Vault vault;
  final Widget child;
  @override
  State<AppLock> createState() => _AppLockState();
}

class _AppLockState extends State<AppLock> with WidgetsBindingObserver {
  // The contact picker, SMS app and share sheet also pause us; don't re-lock for those.
  static const _grace = Duration(seconds: 30);
  late bool _locked = widget.vault.lock;
  bool _authing = false;
  DateTime? _pausedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (_locked) WidgetsBinding.instance.addPostFrameCallback((_) => _unlock());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    if (_authing) return; // the prompt itself pauses the app on some phones
    if (s == AppLifecycleState.paused) _pausedAt = DateTime.now();
    if (s == AppLifecycleState.resumed && _pausedAt != null) {
      final away = DateTime.now().difference(_pausedAt!);
      _pausedAt = null;
      if (widget.vault.lock && away > _grace) {
        setState(() => _locked = true);
        _unlock();
      }
    }
  }

  Future<void> _unlock() async {
    if (_authing || !mounted) return;
    _authing = true;
    try {
      if (await deviceAuth(context) && mounted) {
        setState(() => _locked = false);
      }
    } finally {
      _authing = false;
    }
  }

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      // Kept alive but hidden, so unlocking returns to the same screen.
      Offstage(offstage: _locked, child: widget.child),
      if (_locked) _LockScreen(onUnlock: _unlock),
    ],
  );
}

class _LockScreen extends StatelessWidget {
  const _LockScreen({required this.onUnlock});
  final VoidCallback onUnlock;
  @override
  Widget build(BuildContext context) {
    final l = context.l;
    return Material(
      color: Palette.bg,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_rounded, size: 64, color: Palette.mint),
            const SizedBox(height: 20),
            Text(l.lockedTitle, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: onUnlock,
              icon: const Icon(Icons.fingerprint_rounded),
              label: Text(l.unlock),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../crypto/sms_crypto.dart';
import '../data/sms_box.dart';
import '../data/vault.dart';
import 'common.dart';

/// Seals identity + contacts under a passphrase and hands the text to the share sheet.
Future<void> exportBackup(BuildContext context, Vault vault) async {
  final pass = await showDialog<String>(
    context: context,
    builder: (_) => const _PassDialog(confirm: true),
  );
  if (pass == null || !context.mounted) return;
  final blob = await _busy(context, vault.exportBackup(pass));
  if (!context.mounted) return;
  if (!await smsBox.share(blob) && context.mounted) copyText(context, blob);
}

Future<void> restoreBackup(
  BuildContext context,
  Vault vault,
  String payload,
) async {
  final l = context.l;
  final pass = await showDialog<String>(
    context: context,
    builder: (_) => const _PassDialog(confirm: false),
  );
  if (pass == null || !context.mounted) return;
  final BackupData b;
  try {
    b = await _busy(context, Vault.readBackup(payload, pass));
  } on BackupError {
    if (context.mounted) context.toast(l.backupWrong);
    return;
  }
  if (!context.mounted ||
      !await confirm(
        context,
        l.restoreBackup,
        l.restoreConfirm,
        l.restoreBackup,
        danger: true,
      )) {
    return;
  }
  await vault.restore(b);
  if (context.mounted) context.toast(l.restoreDone(b.contacts.length));
}

/// Argon2id takes a moment: block input meanwhile.
Future<T> _busy<T>(BuildContext context, Future<T> work) async {
  final nav = Navigator.of(context);
  // Remove this exact route later: an invite dialog may land on top meanwhile.
  final route = DialogRoute<void>(
    context: context,
    barrierDismissible: false,
    builder: (c) => PopScope(
      canPop: false,
      child: AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 20),
            Expanded(child: Text(c.l.working)),
          ],
        ),
      ),
    ),
  );
  nav.push(route);
  try {
    return await work;
  } finally {
    nav.removeRoute(route);
  }
}

class _PassDialog extends StatefulWidget {
  const _PassDialog({required this.confirm});
  final bool confirm; // export: ask twice and enforce length
  @override
  State<_PassDialog> createState() => _PassDialogState();
}

class _PassDialogState extends State<_PassDialog> {
  final _a = TextEditingController(), _b = TextEditingController();
  String? _err;

  @override
  void dispose() {
    _a.dispose();
    _b.dispose();
    super.dispose();
  }

  void _ok() {
    final l = context.l;
    final p = normalizeSecret(_a.text);
    if (widget.confirm && p.length < 10) {
      return setState(() => _err = l.passTooShort);
    }
    if (widget.confirm && p != normalizeSecret(_b.text)) {
      return setState(() => _err = l.passMismatch);
    }
    if (p.isNotEmpty) Navigator.pop(context, p);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    return AlertDialog(
      icon: const Icon(Icons.enhanced_encryption_rounded, size: 36),
      title: Text(widget.confirm ? l.backup : l.restoreBackup),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.confirm ? l.backupBody : l.restoreBody,
              style: const TextStyle(height: 1.6),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _a,
              autofocus: true,
              obscureText: true,
              textInputAction: widget.confirm
                  ? TextInputAction.next
                  : TextInputAction.done,
              onSubmitted: widget.confirm ? null : (_) => _ok(),
              decoration: InputDecoration(
                labelText: l.passphrase,
                errorText: widget.confirm ? null : _err,
              ),
            ),
            if (widget.confirm) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _b,
                obscureText: true,
                onSubmitted: (_) => _ok(),
                decoration: InputDecoration(
                  labelText: l.passphraseAgain,
                  errorText: _err,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l.cancel),
        ),
        FilledButton(onPressed: _ok, child: Text(l.ok)),
      ],
    );
  }
}

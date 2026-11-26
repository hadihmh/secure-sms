import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/sms_box.dart';
import '../data/vault.dart';
import '../l10n/app_localizations.dart';
import 'theme.dart';

extension L10nX on BuildContext {
  AppLocalizations get l => AppLocalizations.of(this);
  void toast(String msg) => ScaffoldMessenger.of(this)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(msg)));
}

Future<void> copyText(BuildContext context, String text) async {
  await Clipboard.setData(ClipboardData(text: text));
  if (context.mounted) context.toast(context.l.copied);
}

/// Opens the SMS app prefilled; empty [phone] lets the user pick a recipient.
/// Falls back to the clipboard so the text is never lost.
Future<bool> sendSms(BuildContext context, String phone, String body) async {
  final sep = Platform.isIOS ? '&' : '?';
  final uri = Uri.parse(
    'sms:${Uri.encodeComponent(phone)}${sep}body=${Uri.encodeComponent(body)}',
  );
  var ok = false;
  try {
    ok = await launchUrl(uri);
  } on Exception {
    ok = false; // no SMS app / plugin
  }
  if (!ok) {
    await Clipboard.setData(ClipboardData(text: body));
    if (context.mounted) context.toast(context.l.smsFailed);
  }
  return ok;
}

/// Key first (the app finds it anywhere in the text), then a hint for people without the app.
/// No URL: Iranian carriers filter SMS that contain links.
String inviteText(BuildContext context, Vault v, {bool accepted = false}) {
  final l = context.l;
  return '${v.me.invite()}\n${accepted ? '${l.inviteAccepted}\n' : ''}${l.inviteHint}';
}

/// Sends our key: directly when SMS permission is granted, else through the SMS app.
Future<void> sendInvite(
  BuildContext context,
  Vault v,
  String phone, {
  bool accepted = false,
}) async {
  final l = context.l;
  final body = inviteText(context, v, accepted: accepted);
  if (phone.isNotEmpty &&
      await smsBox.granted() &&
      await smsBox.send(phone, body)) {
    if (context.mounted) context.toast(l.inviteSent);
    return;
  }
  if (context.mounted) await sendSms(context, phone, body);
}

/// Name + phone dialog. Returns null on cancel.
Future<(String, String)?> askContact(
  BuildContext context, {
  Contact? initial,
  String phone = '',
}) => showDialog(
  context: context,
  builder: (_) => _ContactDialog(initial, phone),
);

class _ContactDialog extends StatefulWidget {
  const _ContactDialog(this.initial, this.phone);
  final Contact? initial;
  final String phone; // prefill for a new contact
  @override
  State<_ContactDialog> createState() => _ContactDialogState();
}

class _ContactDialogState extends State<_ContactDialog> {
  late final _name = TextEditingController(text: widget.initial?.name);
  late final _phone = TextEditingController(
    text: widget.initial?.phone ?? widget.phone,
  );

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final p = await smsBox.pickContact();
    if (p == null) return;
    if (_name.text.trim().isEmpty) _name.text = p.$1;
    _phone.text = p.$2.replaceAll(RegExp(r'[^\d+]'), '');
  }

  void _submit() {
    final n = _name.text.trim();
    if (n.isNotEmpty)
      Navigator.pop(context, (
        n,
        _phone.text.replaceAll(RegExp(r'[^\d+]'), ''),
      ));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    return AlertDialog(
      scrollable: true, // keyboard + picker button don't fit on short screens
      title: Text(widget.initial == null ? l.newContact : l.edit),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (Platform.isAndroid) ...[
            OutlinedButton.icon(
              onPressed: _pick,
              icon: const Icon(Icons.contacts_rounded),
              label: Text(l.pickContact),
            ),
            const SizedBox(height: 12),
          ],
          TextField(
            controller: _name,
            autofocus: true,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(labelText: l.name),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            textDirection: TextDirection.ltr,
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(labelText: l.phone),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l.cancel),
        ),
        ListenableBuilder(
          listenable: _name,
          builder: (_, _) => FilledButton(
            onPressed: _name.text.trim().isEmpty ? null : _submit,
            child: Text(l.save),
          ),
        ),
      ],
    );
  }
}

Future<bool> confirm(
  BuildContext context,
  String title,
  String body,
  String ok, {
  bool danger = false,
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        icon: danger
            ? const Icon(
                Icons.gpp_maybe_rounded,
                color: Palette.danger,
                size: 40,
              )
            : null,
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: Text(c.l.cancel),
          ),
          FilledButton(
            style: danger
                ? FilledButton.styleFrom(backgroundColor: Palette.danger)
                : null,
            onPressed: () => Navigator.pop(c, true),
            child: Text(ok),
          ),
        ],
      ),
    ) ??
    false;

class Avatar extends StatelessWidget {
  const Avatar(this.name, {super.key, this.size = 44});
  final String name;
  final double size;
  static const _hues = [
    Color(0xFF4DE3B5),
    Color(0xFF7AA7FF),
    Color(0xFFF5B84A),
    Color(0xFFE38BFF),
    Color(0xFF6FD6FF),
  ];
  @override
  Widget build(BuildContext context) {
    final c = _hues[name.runes.fold(0, (a, b) => a + b) % _hues.length];
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: c.withValues(alpha: .14),
        border: Border.all(color: c.withValues(alpha: .5)),
      ),
      child: Text(
        name.characters.first.toUpperCase(),
        style: TextStyle(
          color: c,
          fontWeight: FontWeight.w700,
          fontSize: size * .4,
        ),
      ),
    );
  }
}

/// Trust state of a contact, one glance: waiting / not verified / verified.
class TrustChip extends StatelessWidget {
  const TrustChip(this.c, {super.key});
  final Contact c;
  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final (color, icon, label) = c.key == null
        ? (Palette.muted, Icons.hourglass_top_rounded, l.waitingKey)
        : c.verified
        ? (Palette.mint, Icons.verified_user_rounded, l.verified)
        : (Palette.amber, Icons.shield_outlined, l.unverified);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: Container(
        key: ValueKey(label),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

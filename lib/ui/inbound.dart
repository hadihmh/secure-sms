import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../crypto/sms_crypto.dart';
import '../data/sms_box.dart';
import '../data/vault.dart';
import 'backup.dart';
import 'common.dart';
import 'contact_screen.dart';
import 'theme.dart';

/// Handles text from the clipboard, a share or a text selection:
/// a key invite adds/updates a contact, a ciphertext is decrypted on screen.
Future<void> handleInbound(
  BuildContext context,
  Vault vault,
  String? text,
) async {
  final l = context.l;
  final p = text == null ? null : parse(text);
  switch (p) {
    case null:
      context.toast(l.nothingToOpen);
    case Ciphertext(:final payload):
      final r = await vault.decrypt(payload);
      if (!context.mounted) return;
      if (r == null) return context.toast(l.notRecognized);
      final (c, d) = r;
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (_) => _MessageSheet(vault, c, d),
      );
    case KeyInvite(:final key):
      await _onKey(context, vault, key);
    case Backup(:final payload):
      await restoreBackup(context, vault, payload);
  }
}

Future<void> pasteInbound(BuildContext context, Vault vault) async {
  final data = await Clipboard.getData(Clipboard.kTextPlain);
  if (context.mounted) await handleInbound(context, vault, data?.text);
}

Future<void> _onKey(BuildContext context, Vault vault, Uint8List key) async {
  final l = context.l;
  if (sameKey(key, vault.me.publicKey)) return context.toast(l.ownKey);
  final known = vault.byKey(key);
  if (known != null) return context.toast(l.keyKnown(known.name));

  // Contacts waiting for a key first; picking one that already has a key = key change.
  final choices = [...vault.contacts]
    ..sort((a, b) => (a.key == null ? 0 : 1) - (b.key == null ? 0 : 1));
  final picked = await showModalBottomSheet<Object>(
    context: context,
    builder: (c) => SafeArea(
      child: ListView(
        shrinkWrap: true,
        children: [
          ListTile(
            leading: const Icon(Icons.key_rounded, color: Palette.mint),
            title: Text(
              l.newKeyTitle,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Text(l.newKeyBody),
          ),
          ListTile(
            leading: const CircleAvatar(
              backgroundColor: Palette.raised,
              child: Icon(Icons.person_add_alt_1_rounded),
            ),
            title: Text(l.newContact),
            onTap: () => Navigator.pop(c, 'new'),
          ),
          for (final x in choices)
            ListTile(
              leading: Avatar(x.name, size: 40),
              title: Text(x.name),
              trailing: TrustChip(x),
              onTap: () => Navigator.pop(c, x),
            ),
        ],
      ),
    ),
  );
  if (!context.mounted || picked == null) return;

  final Contact contact;
  if (picked is Contact) {
    if (picked.key != null &&
        !await confirm(
          context,
          l.keyChangedTitle(picked.name),
          l.keyChangedBody(picked.name),
          l.acceptNewKey,
          danger: true,
        )) {
      return;
    }
    await vault.setKey(picked, key);
    contact = picked;
  } else {
    // The key came by SMS, so its sender is the contact's number (needs READ_SMS).
    final from = await smsBox.senderOf('$keyTag${b64(key)}');
    if (!context.mounted) return;
    return _acceptKey(context, vault, key, from ?? '');
  }
  if (context.mounted) openContact(context, vault, contact);
}

Future<void> _acceptKey(
  BuildContext context,
  Vault vault,
  Uint8List key,
  String phone,
) async {
  final r = await askContact(
    context,
    phone: phone.replaceAll(RegExp(r'[^\d+]'), ''),
  );
  if (r == null || !context.mounted) return;
  final c = await vault.add(r.$1, r.$2, key);
  if (!context.mounted) return;
  openContact(context, vault, c);
  // Our key goes straight back, so both sides are connected with no extra step.
  await sendInvite(context, vault, c.phone, accepted: true);
}

/// Keys that arrived by SMS (newest per sender). A reply to our invite connects the
/// waiting contact at once; any other new key is offered. [seen] = asked this session.
Future<void> checkInvites(
  BuildContext context,
  Vault vault,
  Set<String> seen,
) async {
  final senders = <String>{};
  for (final r in await smsBox.list(tag: keyTag)) {
    if (!r.incoming || !senders.add(r.address)) continue;
    if (parse(r.body) case KeyInvite(:final key)) {
      final id = b64(key);
      if (!seen.add(id)) continue;
      if (sameKey(key, vault.me.publicKey) || vault.byKey(key) != null)
        continue;
      if (!context.mounted) return;
      final l = context.l;
      final waiting = vault.contacts
          .where((c) => c.key == null && samePhone(c.phone, r.address))
          .firstOrNull;
      if (waiting != null) {
        await vault.setKey(waiting, key);
        if (context.mounted) context.toast(l.connected(waiting.name));
        continue;
      }
      // Declined once: don't ask again (but a contact we invited since still connects, above).
      if (vault.ignored.contains(id)) continue;
      final ok = await confirm(
        context,
        l.inviteTitle,
        l.inviteFrom(r.address),
        l.accept,
      );
      if (!context.mounted) return;
      if (ok) {
        await _acceptKey(context, vault, key, r.address);
      } else {
        await vault.ignore(id);
      }
    }
  }
}

class _MessageSheet extends StatelessWidget {
  const _MessageSheet(this.vault, this.c, this.d);
  final Vault vault;
  final Contact c;
  final Decrypted d;

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Avatar(c.name),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    d.outgoing ? l.toContact(c.name) : l.fromContact(c.name),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                TrustChip(c),
              ],
            ),
            const SizedBox(height: 16),
            // The "unseal" moment: plaintext fades and lifts in.
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 420),
              curve: Curves.easeOutCubic,
              builder: (_, t, child) => Opacity(
                opacity: t,
                child: Transform.translate(
                  offset: Offset(0, 12 * (1 - t)),
                  child: child,
                ),
              ),
              child: Container(
                padding: const EdgeInsets.all(18),
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height * .5,
                ),
                decoration: BoxDecoration(
                  color: Palette.raised,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Palette.mint.withValues(alpha: .35),
                  ),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    d.text,
                    style: const TextStyle(fontSize: 17, height: 1.6),
                  ),
                ),
              ),
            ),
            if (!c.verified) ...[
              const SizedBox(height: 12),
              Text(
                l.unverifiedWarn(c.name),
                style: const TextStyle(color: Palette.amber, fontSize: 13),
              ),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(l.close),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    icon: const Icon(Icons.reply_rounded),
                    onPressed: () {
                      Navigator.pop(context);
                      openContact(context, vault, c);
                    },
                    label: Text(l.reply),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

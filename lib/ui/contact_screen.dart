import 'package:flutter/material.dart';

import '../crypto/sms_crypto.dart';
import '../data/sms_box.dart';
import '../data/vault.dart';
import 'common.dart';
import 'theme.dart';

void openContact(BuildContext context, Vault vault, Contact c) =>
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ContactScreen(vault: vault, contact: c),
      ),
    );

class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key, required this.vault, required this.contact});
  final Vault vault;
  final Contact contact;
  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  final _text = TextEditingController();
  Contact get c => widget.contact;
  Vault get v => widget.vault;
  List<int>? _snKey;
  late Future<String> _sn;

  // Recompute only when the key changes, so rebuilds don't flash a placeholder.
  Future<String> get _safety {
    if (!identical(_snKey, c.key))
      _sn = safetyNumber(v.me.publicKey, (_snKey = c.key)!);
    return _sn;
  }

  bool? _granted;
  List<Message> _msgs = const [];

  @override
  void initState() {
    super.initState();
    smsBox.addListener(_load);
    _load();
  }

  @override
  void dispose() {
    smsBox.removeListener(_load);
    _text.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final ok = await smsBox.granted();
    final msgs = ok && c.key != null
        ? await thread(v.me, c, await smsBox.list())
        : const <Message>[];
    if (!mounted) return;
    setState(() {
      _granted = ok;
      _msgs = msgs;
    });
    // A contact made from a received key has no number yet: take it from their first message.
    if (c.phone.isEmpty) {
      for (final m in msgs) {
        if (!m.outgoing && m.address.isNotEmpty)
          return v.edit(c, c.name, m.address);
      }
    }
  }

  Future<void> _allow() async {
    if (await smsBox.request()) return _load();
    if (mounted) context.toast(context.l.smsDenied);
  }

  Future<void> _menu(String action) async {
    final l = context.l;
    switch (action) {
      case 'edit':
        final r = await askContact(context, initial: c);
        if (r != null) await v.edit(c, r.$1, r.$2);
      case 'secret':
        final s = await showDialog<String>(
          context: context,
          builder: (_) => _SecretDialog(c),
        );
        if (s != null) {
          await v.setSecret(c, s);
          await _load();
        }
      case 'key':
        if (mounted) await sendInvite(context, v, c.phone);
      case 'delete':
        if (await confirm(
          context,
          l.delete,
          l.deleteConfirm(c.name),
          l.delete,
          danger: true,
        )) {
          await v.remove(c);
          if (mounted) Navigator.pop(context);
        }
    }
  }

  Future<void> _send({required bool viaSms}) async {
    final body = await v.encryptFor(c, _text.text);
    if (!mounted) return;
    if (!viaSms) return copyText(context, body);
    if (c.phone.isNotEmpty &&
        _granted == true &&
        await smsBox.send(c.phone, body)) {
      _text.clear();
      // shortcut: the system writes the sent row a moment later and doesn't always notify the observer; re-read once.
      await Future<void>.delayed(const Duration(seconds: 2));
      return _load();
    }
    if (!mounted) return;
    // Clear only once the SMS app has the ciphertext, so nothing is lost.
    if (await sendSms(context, c.phone, body)) _text.clear();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    return ListenableBuilder(
      listenable: v,
      builder: (context, _) => Scaffold(
        appBar: AppBar(
          titleSpacing: 0,
          title: Row(
            children: [
              Hero(tag: 'avatar-${c.id}', child: Avatar(c.name, size: 36)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c.name, overflow: TextOverflow.ellipsis),
                    if (c.phone.isNotEmpty)
                      Text(
                        c.phone,
                        textDirection: TextDirection.ltr,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Palette.muted,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            PopupMenuButton<String>(
              onSelected: _menu,
              itemBuilder: (_) => [
                PopupMenuItem(value: 'edit', child: Text(l.edit)),
                PopupMenuItem(value: 'key', child: Text(l.sendMyKey)),
                PopupMenuItem(value: 'secret', child: Text(l.sharedPhrase)),
                PopupMenuItem(
                  value: 'delete',
                  child: Text(
                    l.delete,
                    style: const TextStyle(color: Palette.danger),
                  ),
                ),
              ],
            ),
          ],
        ),
        body: SafeArea(
          child: c.key == null
              ? _Waiting(c: c, onInvite: () => sendInvite(context, v, c.phone))
              : Column(
                  children: [
                    Expanded(
                      // Reversed so the newest message sits above the composer.
                      child: ListView(
                        reverse: true,
                        padding: const EdgeInsets.all(16),
                        children: [
                          for (final m in _msgs.reversed) _Bubble(m),
                          if (_granted == false) _AllowSms(onAllow: _allow),
                          if (_granted == true && _msgs.isEmpty)
                            Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                l.noMessages,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Palette.muted),
                              ),
                            ),
                          _Safety(v: v, c: c, number: _safety),
                        ],
                      ),
                    ),
                    _Composer(text: _text, onSend: _send),
                  ],
                ),
        ),
      ),
    );
  }
}

class _Waiting extends StatelessWidget {
  const _Waiting({required this.c, required this.onInvite});
  final Contact c;
  final VoidCallback onInvite;
  @override
  Widget build(BuildContext context) {
    final l = context.l;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.hourglass_top_rounded,
              size: 56,
              color: Palette.muted,
            ),
            const SizedBox(height: 16),
            Text(l.waitingKey, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              l.waitingBody(c.name),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Palette.muted, height: 1.6),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onInvite,
              icon: const Icon(Icons.send_rounded),
              label: Text(l.sendInvite),
            ),
          ],
        ),
      ),
    );
  }
}

class _Safety extends StatelessWidget {
  const _Safety({required this.v, required this.c, required this.number});
  final Vault v;
  final Contact c;
  final Future<String> number;
  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final accent = c.verified ? Palette.mint : Palette.amber;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Palette.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: accent.withValues(alpha: .4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.fingerprint_rounded, color: accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l.safetyNumber,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              TrustChip(c),
            ],
          ),
          const SizedBox(height: 16),
          FutureBuilder(
            future: number,
            builder: (_, s) => Center(
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: SelectableText(
                  s.data ?? '···· ···· ···· ···· ····',
                  semanticsLabel: s.data?.split('').join(' '),
                  style: Palette.mono.copyWith(
                    fontSize: 22,
                    color: Palette.text,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            l.safetyHint(c.name),
            style: const TextStyle(
              color: Palette.muted,
              fontSize: 13,
              height: 1.6,
            ),
          ),
          if (c.secret.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.password_rounded,
                  size: 18,
                  color: Palette.mint,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    l.sharedPhraseOn,
                    style: const TextStyle(color: Palette.mint, fontSize: 13),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: c.verified
                ? OutlinedButton(
                    onPressed: () => v.setVerified(c, false),
                    child: Text(l.unmarkVerified),
                  )
                : FilledButton.icon(
                    onPressed: () => v.setVerified(c, true),
                    icon: const Icon(Icons.verified_user_rounded),
                    label: Text(l.markVerified),
                  ),
          ),
        ],
      ),
    );
  }
}

class _SecretDialog extends StatefulWidget {
  const _SecretDialog(this.c);
  final Contact c;
  @override
  State<_SecretDialog> createState() => _SecretDialogState();
}

class _SecretDialogState extends State<_SecretDialog> {
  late final _t = TextEditingController(text: widget.c.secret);

  @override
  void dispose() {
    _t.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    return AlertDialog(
      title: Text(l.sharedPhrase),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l.sharedPhraseBody(widget.c.name),
            style: const TextStyle(height: 1.6, fontSize: 13),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _t,
            autofocus: true,
            onSubmitted: (s) => Navigator.pop(context, s),
            decoration: InputDecoration(labelText: l.sharedPhrase),
          ),
        ],
      ),
      actions: [
        if (widget.c.secret.isNotEmpty)
          TextButton(
            onPressed: () => Navigator.pop(context, ''),
            child: Text(
              l.delete,
              style: const TextStyle(color: Palette.danger),
            ),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _t.text),
          child: Text(l.save),
        ),
      ],
    );
  }
}

class _AllowSms extends StatelessWidget {
  const _AllowSms({required this.onAllow});
  final VoidCallback onAllow;
  @override
  Widget build(BuildContext context) {
    final l = context.l;
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: ListTile(
        tileColor: Palette.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        leading: const Icon(Icons.forum_rounded, color: Palette.mint),
        title: Text(
          l.allowSmsTitle,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(l.allowSmsBody, style: const TextStyle(height: 1.5)),
        trailing: TextButton(onPressed: onAllow, child: Text(l.allowSms)),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble(this.m);
  final Message m;
  @override
  Widget build(BuildContext context) {
    final loc = MaterialLocalizations.of(context);
    final time =
        '${loc.formatShortDate(m.date)} ${loc.formatTimeOfDay(TimeOfDay.fromDateTime(m.date))}';
    return Align(
      alignment: m.outgoing
          ? AlignmentDirectional.centerEnd
          : AlignmentDirectional.centerStart,
      child: Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * .78,
        ),
        decoration: BoxDecoration(
          color: m.outgoing
              ? Palette.mint.withValues(alpha: .16)
              : Palette.raised,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            SelectableText(
              m.text,
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 4),
            Text(
              time,
              style: const TextStyle(fontSize: 11, color: Palette.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({required this.text, required this.onSend});
  final TextEditingController text;
  final Future<void> Function({required bool viaSms}) onSend;
  @override
  Widget build(BuildContext context) {
    final l = context.l;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: const BoxDecoration(
        color: Palette.surface,
        border: Border(top: BorderSide(color: Palette.line)),
      ),
      child: ListenableBuilder(
        listenable: text,
        builder: (context, _) {
          final empty = text.text.trim().isEmpty;
          final len = cipherLength(text.text);
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: text,
                minLines: 1,
                maxLines: 6,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(hintText: l.composeHint),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: AnimatedOpacity(
                      opacity: empty ? 0 : 1,
                      duration: const Duration(milliseconds: 200),
                      child: Text(
                        l.smsCount('$len', '${smsParts(len)}'),
                        style: TextStyle(
                          color: smsParts(len) > 3
                              ? Palette.amber
                              : Palette.muted,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: l.copyEncrypted,
                    onPressed: empty ? null : () => onSend(viaSms: false),
                    icon: const Icon(Icons.copy_rounded),
                  ),
                  const SizedBox(width: 4),
                  FilledButton.icon(
                    onPressed: empty ? null : () => onSend(viaSms: true),
                    icon: const Icon(Icons.lock_rounded, size: 18),
                    label: Text(l.sendSms),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

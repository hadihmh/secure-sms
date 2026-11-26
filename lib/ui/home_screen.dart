import 'package:flutter/material.dart';

import '../crypto/sms_crypto.dart';
import '../data/vault.dart';
import 'app_lock.dart';
import 'backup.dart';
import 'common.dart';
import 'contact_screen.dart';
import 'inbound.dart';
import 'theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.vault});
  final Vault vault;

  Future<void> _invite(BuildContext context) async {
    final r = await askContact(context);
    if (r == null || !context.mounted) return;
    final c = await vault.add(r.$1, r.$2, null);
    if (!context.mounted) return;
    openContact(context, vault, c);
    await sendInvite(context, vault, c.phone);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    return ListenableBuilder(
      listenable: vault,
      builder: (context, _) => Scaffold(
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => pasteInbound(context, vault),
          icon: const Icon(Icons.lock_open_rounded),
          label: Text(l.openMessage),
        ),
        body: CustomScrollView(
          slivers: [
            SliverAppBar.large(
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l.appTitle,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  Text(
                    l.tagline,
                    style: const TextStyle(fontSize: 12, color: Palette.mint),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  tooltip: l.invite,
                  onPressed: () => _invite(context),
                  icon: const Icon(Icons.person_add_alt_1_rounded),
                ),
                PopupMenuButton<VoidCallback>(
                  onSelected: (f) => f(),
                  itemBuilder: (_) => [
                    CheckedPopupMenuItem(
                      checked: vault.lock,
                      value: () => toggleLock(context, vault),
                      child: Text(l.appLock),
                    ),
                    PopupMenuItem(
                      value: () => exportBackup(context, vault),
                      child: Text(l.backup),
                    ),
                    PopupMenuItem(
                      value: () => pasteInbound(context, vault),
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(l.restoreBackup),
                        subtitle: Text(l.restoreHint),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              sliver: SliverToBoxAdapter(child: _MyKeyCard(vault)),
            ),
            if (vault.contacts.isEmpty)
              const SliverFillRemaining(hasScrollBody: false, child: _Empty())
            else ...[
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    l.contacts,
                    style: const TextStyle(
                      color: Palette.muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              SliverList.builder(
                itemCount: vault.contacts.length,
                itemBuilder: (context, i) {
                  final c = vault.contacts[i];
                  return ListTile(
                    leading: Hero(tag: 'avatar-${c.id}', child: Avatar(c.name)),
                    title: Text(
                      c.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: c.phone.isEmpty
                        ? null
                        : Text(
                            c.phone,
                            textDirection: TextDirection.ltr,
                            textAlign: TextAlign.start,
                            style: const TextStyle(color: Palette.muted),
                          ),
                    trailing: TrustChip(c),
                    onTap: () => openContact(context, vault, c),
                  );
                },
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 96)),
            ],
          ],
        ),
      ),
    );
  }
}

class _MyKeyCard extends StatelessWidget {
  const _MyKeyCard(this.vault);
  final Vault vault;
  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final k = b64(vault.me.publicKey);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [Palette.mint.withValues(alpha: .16), Palette.surface],
        ),
        border: Border.all(color: Palette.mint.withValues(alpha: .35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.key_rounded, color: Palette.mint),
              const SizedBox(width: 8),
              Text(
                l.myKey,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              // Short visual fingerprint; the full key travels in the invite.
              Directionality(
                textDirection: TextDirection.ltr,
                child: Text(
                  '${k.substring(0, 4)} ${k.substring(4, 8)}',
                  style: Palette.mono.copyWith(
                    color: Palette.mint,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            l.myKeyHint,
            style: const TextStyle(color: Palette.muted, height: 1.6),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => sendInvite(context, vault, ''),
                  icon: const Icon(Icons.send_rounded, size: 18),
                  label: Text(l.shareKey),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () => copyText(context, inviteText(context, vault)),
                icon: const Icon(Icons.copy_rounded, size: 18),
                label: Text(l.copy),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();
  @override
  Widget build(BuildContext context) {
    final l = context.l;
    return Padding(
      padding: const EdgeInsets.fromLTRB(40, 24, 40, 120),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Palette.raised,
              border: Border.all(color: Palette.line, width: 8),
            ),
            child: const Icon(
              Icons.forum_outlined,
              size: 40,
              color: Palette.muted,
            ),
          ),
          const SizedBox(height: 20),
          Text(l.noContacts, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            l.noContactsHint,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Palette.muted, height: 1.6),
          ),
        ],
      ),
    );
  }
}

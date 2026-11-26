import 'package:flutter/material.dart';

import '../data/vault.dart';
import 'common.dart';
import 'theme.dart';

/// First run: three cards (send key → compare number → chat). Shown once.
class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key, required this.vault});
  final Vault vault;
  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  final _pages = PageController();
  int _i = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final cards = [
      (Icons.key_rounded, l.introTitle1, l.introBody1),
      (Icons.verified_user_rounded, l.introTitle2, l.introBody2),
      (Icons.forum_rounded, l.introTitle3, l.introBody3),
    ];
    final last = _i == cards.length - 1;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: AnimatedOpacity(
                opacity: last ? 0 : 1,
                duration: const Duration(milliseconds: 200),
                child: TextButton(
                  onPressed: last ? null : widget.vault.finishIntro,
                  child: Text(l.skip),
                ),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pages,
                onPageChanged: (i) => setState(() => _i = i),
                children: [
                  for (final (icon, title, body) in cards)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 36),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Palette.mint.withValues(alpha: .12),
                              border: Border.all(
                                color: Palette.mint.withValues(alpha: .35),
                                width: 2,
                              ),
                            ),
                            child: Icon(icon, size: 52, color: Palette.mint),
                          ),
                          const SizedBox(height: 36),
                          Text(
                            title,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            body,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Palette.muted,
                              fontSize: 15,
                              height: 1.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Row(
                children: [
                  for (var k = 0; k < cards.length; k++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsetsDirectional.only(end: 6),
                      width: k == _i ? 22 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: k == _i ? Palette.mint : Palette.line,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  const Spacer(),
                  FilledButton(
                    onPressed: last
                        ? widget.vault.finishIntro
                        : () => _pages.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOutCubic,
                          ),
                    child: Text(last ? l.start : l.next),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

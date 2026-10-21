import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/auth_providers.dart';

/// The paywall shown to a signed-in reader who does not have premium access.
class UpgradeScreen extends ConsumerWidget {
  const UpgradeScreen({
    super.key,
    this.articleTitle,
    this.articlePriceCents,
  });

  final String? articleTitle;
  final int? articlePriceCents;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final session = ref.watchSession();

    if (!session.signedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go('/login');
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final isArticlePurchase =
        articlePriceCents != null && articlePriceCents! > 0;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        title: const Text('Upgrade'),
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          children: [
            Icon(
              Icons.workspace_premium,
              size: 56,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              isArticlePurchase ? 'Unlock this article' : 'Upgrade to Premium',
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              isArticlePurchase
                  ? 'Buy this article, or subscribe to Premium for full '
                      'access to every story on CIO Africa.'
                  : 'Get unlimited access to every CIO Africa story, the '
                      'daily mobile edition, and the digital magazine.',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            if (articleTitle != null && articleTitle!.isNotEmpty) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.article_outlined, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        articleTitle!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            const _Benefit(
              icon: Icons.all_inclusive,
              title: 'Every article, unlocked',
              subtitle:
                  'No metered limits. No per-article purchases. Read everything.',
            ),
            const _Benefit(
              icon: Icons.newspaper,
              title: 'Daily mobile edition',
              subtitle: 'Curated by CIO Africa editors every morning.',
            ),
            const _Benefit(
              icon: Icons.menu_book_outlined,
              title: 'Digital magazine',
              subtitle: 'Full issues, offline-ready when you travel.',
            ),
            const _Benefit(
              icon: Icons.bookmark_outline,
              title: 'Read on any device',
              subtitle: 'Your subscription works across app and web.',
            ),
            const SizedBox(height: 28),
            if (isArticlePurchase) ...[
              FilledButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Purchases will be enabled in a future update.',
                      ),
                    ),
                  );
                },
                child: const Text('Buy this article only'),
              ),
              const SizedBox(height: 12),
              Text(
                'One-off purchase. Access to this single story.',
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text('or', style: theme.textTheme.labelSmall),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 24),
            ],
            FilledButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Premium subscription will be enabled in a future update.',
                    ),
                  ),
                );
              },
              child: const Text('Upgrade to Premium'),
            ),
            const SizedBox(height: 12),
            Text(
              'You will be redirected to a secure checkout. Your subscription '
              'renews annually and can be cancelled at any time.',
              textAlign: TextAlign.center,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Benefit extends StatelessWidget {
  const _Benefit({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: theme.colorScheme.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
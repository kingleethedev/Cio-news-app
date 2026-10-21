import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/auth_providers.dart';

/// Banner shown above the feed for readers who are not premium subscribers.
///
/// - Premium subscribers see nothing.
/// - Signed-in free subscribers see an "Upgrade" prompt.
/// - Anonymous readers see a "Sign in" prompt.
///
/// Hidden entirely once the reader is a premium subscriber.
class SubscriberBanner extends ConsumerWidget {
  const SubscriberBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authControllerProvider);

    // Premium subscribers have full access — no banner.
    if (session.signedIn && session.premium) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final isSignedIn = session.signedIn;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.workspace_premium_outlined,
            color: theme.colorScheme.onPrimaryContainer,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isSignedIn
                      ? 'You are on the free plan'
                      : 'Subscribe to CIO Africa',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isSignedIn
                      ? 'Upgrade to Premium to unlock every story.'
                      : 'Sign in or subscribe to unlock premium stories.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () {
              context.push(isSignedIn ? '/profile' : '/login');
            },
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.onPrimaryContainer,
            ),
            child: Text(isSignedIn ? 'Upgrade' : 'Sign in'),
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/auth_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watchSession();
    final theme = Theme.of(context);

    if (!session.signedIn) {
      return Scaffold(
        appBar: AppBar(title: const Text('Account')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.person_outline, size: 56),
                const SizedBox(height: 16),
                Text('You are not signed in.',
                    style: theme.textTheme.titleMedium),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => context.push('/login'),
                  child: const Text('Sign in'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          ListTile(
            leading: const Icon(Icons.account_circle, size: 40),
            title: Text(session.userName ?? 'Reader'),
            subtitle: Text(session.userEmail ?? ''),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: Icon(
                session.premium
                    ? Icons.workspace_premium
                    : Icons.verified_user_outlined,
              ),
              title: Text(session.premium
                  ? 'Premium subscriber'
                  : 'Free subscriber'),
              subtitle: Text(session.premium
                  ? 'You have full access to all articles.'
                  : 'You can read metered articles each month.'),
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: () async {
              await ref.read(authControllerProvider.notifier).signOut();
              if (context.mounted && context.canPop()) context.pop();
            },
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
  }
}
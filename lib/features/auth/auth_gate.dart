import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/api_config.dart';
import '../home/home_screen.dart';
import 'auth_providers.dart';
import 'sign_in_screen.dart';

/// Root of the app. When [ApiConfig.requireLoginForAllContent] is true,
/// anonymous users see the sign-in screen and signed-in users see the feed.
/// When false, everyone sees the feed; login is triggered on demand.
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ApiConfig.requireLoginForAllContent) {
      return const HomeScreen();
    }
    final session = ref.watchSession();
    return session.signedIn ? const HomeScreen() : const SignInScreen();
  }
}
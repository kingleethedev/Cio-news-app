import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'features/articles/article_reader_screen.dart';
import 'features/auth/auth_gate.dart';
import 'features/auth/auth_providers.dart';
import 'features/auth/register_screen.dart';
import 'features/auth/sign_in_screen.dart';
import 'features/home/home_screen.dart';
import 'features/payments/upgrade_screen.dart';
import 'features/profile/profile_screen.dart';

final router = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (_, __) => const AuthGate()),
    GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
    GoRoute(
      path: '/article/:slug',
      builder: (_, state) =>
          ArticleReaderScreen(slug: state.pathParameters['slug']!),
    ),
    GoRoute(
      path: '/login',
      builder: (_, __) => const SignInScreen(),
      redirect: (context, state) {
        final container = ProviderScope.containerOf(context, listen: false);
        final session = container.read(authControllerProvider).valueOrNull ??
            SessionState.anonymous;
        return session.signedIn ? '/profile' : null;
      },
    ),
    GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
    GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
    GoRoute(
      path: '/upgrade',
      builder: (_, state) {
        final extra = state.extra is Map ? state.extra as Map : const {};
        return UpgradeScreen(
          articleTitle: extra['articleTitle'] as String?,
          articlePriceCents: extra['articlePriceCents'] as int?,
        );
      },
    ),
  ],
);

class CioAfricaApp extends ConsumerStatefulWidget {
  const CioAfricaApp({super.key});

  @override
  ConsumerState<CioAfricaApp> createState() => _CioAfricaAppState();
}

class _CioAfricaAppState extends ConsumerState<CioAfricaApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authControllerProvider.notifier).refreshStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'CIO Africa',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0B5FFF),
        ),
        scaffoldBackgroundColor: Colors.white,
      ),
      routerConfig: router,
    );
  }
}
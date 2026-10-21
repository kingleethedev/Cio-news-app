import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../core/network/nonce_store.dart';
import '../home/home_providers.dart';
import 'data/auth_repository.dart';
import 'data/models/auth_result.dart';
import 'data/models/reader_status.dart';
import 'session_manager.dart';

final sessionManagerProvider = Provider<SessionManager>((ref) {
  return SessionManager();
});

final authRepositoryProvider = FutureProvider<AuthRepository>((ref) async {
  final client = await ref.watch(apiClientProvider.future);
  return AuthRepository(client);
});

class SessionState {
  final bool signedIn;
  final bool premium;
  final String? userName;
  final String? userEmail;

  const SessionState({
    required this.signedIn,
    required this.premium,
    this.userName,
    this.userEmail,
  });

  static const anonymous = SessionState(signedIn: false, premium: false);
}

class AuthController extends AsyncNotifier<SessionState> {
  @override
  Future<SessionState> build() async {
    final session = ref.read(sessionManagerProvider);

    debugPrint('[auth] build() started');
    await session.restore();

    final storedUser = session.currentUser;
    debugPrint('[auth] restored user=${storedUser?.email}');
    debugPrint('[auth] restored isPremium=${session.isPremium}');

    if (storedUser == null) {
      debugPrint('[auth] no stored user → anonymous');
      return SessionState.anonymous;
    }

    try {
      final repo = await ref.watch(authRepositoryProvider.future);
      final s = await repo.status();
      debugPrint(
          '[auth] /access/status signedIn=${s.signedIn} premium=${s.premium}');

      if (!s.signedIn) {
        debugPrint('[auth] server says signed-out → clearing storage');
        await session.clear();
        return SessionState.anonymous;
      }

      session.setSession(
        user: storedUser,
        isPremium: s.premium,
        nonce: s.nonce,
      );
      await session.persist();

      return SessionState(
        signedIn: true,
        premium: s.premium,
        userName: storedUser.name,
        userEmail: storedUser.email,
      );
    } catch (e) {
      debugPrint('[auth] /access/status failed: $e');
      // Network error — trust the persisted user. The next successful
      // request will reconcile with the server.
      return SessionState(
        signedIn: true,
        premium: session.isPremium,
        userName: storedUser.name,
        userEmail: storedUser.email,
      );
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    final repo = await ref.read(authRepositoryProvider.future);
    final result = await repo.submitCredentials(
      action: 'login',
      email: email,
      password: password,
    );
    await _applyResult(result);
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final repo = await ref.read(authRepositoryProvider.future);
    final result = await repo.submitCredentials(
      action: 'register',
      email: email,
      password: password,
      name: name,
    );
    await _applyResult(result);
  }

  Future<void> signInWithGoogle(String idToken) async {
    final repo = await ref.read(authRepositoryProvider.future);
    final result = await repo.submitGoogleCredential(idToken);
    await _applyResult(result);
  }

  Future<void> signOut() async {
    try {
      await GoogleSignIn(scopes: const ['email']).signOut();
    } catch (_) {}

    final session = ref.read(sessionManagerProvider);
    await session.clear();
    await NonceStore.clear();

    state = const AsyncData(SessionState.anonymous);
    ref.invalidate(feedProvider);
    ref.invalidate(articleProvider);
  }

  Future<void> _applyResult(AuthResult result) async {
    final user = result.user;
    if (user == null) {
      throw StateError('Auth succeeded but no user was returned.');
    }

    final session = ref.read(sessionManagerProvider);
    session.setSession(
      user: user,
      isPremium: result.isPremium,
      nonce: result.nonce,
    );

    debugPrint('[auth] persisting user=${user.email} premium=${result.isPremium}');
    await session.persist();
    debugPrint('[auth] persist complete');

    state = AsyncData(SessionState(
      signedIn: true,
      premium: result.isPremium,
      userName: user.name,
      userEmail: user.email,
    ));

    ref.invalidate(feedProvider);
    ref.invalidate(articleProvider);
  }

  Future<void> refreshStatus() async {
    try {
      final repo = await ref.read(authRepositoryProvider.future);
      final ReaderStatus s = await repo.status();
      final session = ref.read(sessionManagerProvider);

      if (!s.signedIn) {
        await session.clear();
        state = const AsyncData(SessionState.anonymous);
        return;
      }

      final user = session.currentUser;
      if (user == null) {
        await session.clear();
        state = const AsyncData(SessionState.anonymous);
        return;
      }

      session.setSession(
        user: user,
        isPremium: s.premium,
        nonce: s.nonce,
      );
      await session.persist();

      state = AsyncData(SessionState(
        signedIn: true,
        premium: s.premium,
        userName: user.name,
        userEmail: user.email,
      ));
    } catch (_) {}
  }
}

final authControllerProvider =
    AsyncNotifierProvider<AuthController, SessionState>(AuthController.new);

extension AuthSessionX on WidgetRef {
  SessionState watchSession() {
    return watch(authControllerProvider).valueOrNull ??
        SessionState.anonymous;
  }

  SessionState readSession() {
    return read(authControllerProvider).valueOrNull ??
        SessionState.anonymous;
  }
}
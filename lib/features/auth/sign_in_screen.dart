import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'auth_providers.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  late final GoogleSignIn _googleSignIn;

  bool _isRegisterMode = false;
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  static const String _webClientId =
      '827570943506-ifevf0hei6gqf6op6vkhbhg0eid6spft.apps.googleusercontent.com';

  @override
  void initState() {
    super.initState();

    _googleSignIn = GoogleSignIn(
      scopes: const ['email'],
      serverClientId: _webClientId,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _switchMode(bool registerMode) {
    if (_isLoading || _isGoogleLoading) return;

    setState(() {
      _isRegisterMode = registerMode;
      _errorMessage = null;
      _formKey.currentState?.reset();
    });
  }

  Future<void> _submitEmail() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final auth = ref.read(authControllerProvider.notifier);

      if (_isRegisterMode) {
        await auth.register(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      } else {
        await auth.signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      }

      if (!mounted) return;
      context.go('/');
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _errorMessage = _friendlyError(error);
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    FocusScope.of(context).unfocus();

    setState(() {
      _isGoogleLoading = true;
      _errorMessage = null;
    });

    try {
      // Clear the previously selected Google account in this app.
      await _googleSignIn.signOut();

      final GoogleSignInAccount? account = await _googleSignIn.signIn();

      // The user may cancel the account picker.
      if (account == null) return;

      final GoogleSignInAuthentication authentication =
          await account.authentication;

      final String? idToken = authentication.idToken;

      if (idToken == null || idToken.isEmpty) {
        throw Exception(
          'Google did not return an ID token. '
          'Please check your Google OAuth configuration.',
        );
      }

      // The WordPress endpoint handles both existing and new users.
      await ref
          .read(authControllerProvider.notifier)
          .signInWithGoogle(idToken);

      if (!mounted) return;
      context.go('/');
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _errorMessage = _friendlyError(error);
      });
    } finally {
      if (mounted) {
        setState(() => _isGoogleLoading = false);
      }
    }
  }

  String _friendlyError(Object error) {
    final message = error.toString();

    if (message.contains('ApiException: 10') ||
        message.contains('DEVELOPER_ERROR')) {
      return 'Google Sign-In configuration error. '
          'Check the Android package name, SHA-1 and OAuth client IDs.';
    }

    if (message.contains('network') || message.contains('SocketException')) {
      return 'Network error. Check your internet connection and try again.';
    }

    return message
        .replaceFirst('Exception: ', '')
        .replaceFirst('Bad state: ', '');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final busy = _isLoading || _isGoogleLoading;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // CIO Africa branding
                    Center(
                      child: Image.asset(
                        'assets/images/cio_africa_logo.png',
                        height: 96,
                        fit: BoxFit.contain,
                        semanticLabel: 'CIO Africa',
                      ),
                    ),
                    const SizedBox(height: 24),

                    Text(
                      _isRegisterMode
                          ? 'Create your account'
                          : 'Welcome back',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),

                    Text(
                      _isRegisterMode
                          ? 'Join CIO Africa and stay informed.'
                          : 'Sign in to continue to CIO Africa.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Switch between sign-in and registration.
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: colors.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _modeButton(
                              label: 'Sign in',
                              selected: !_isRegisterMode,
                              onTap: () => _switchMode(false),
                            ),
                          ),
                          Expanded(
                            child: _modeButton(
                              label: 'Create account',
                              selected: _isRegisterMode,
                              onTap: () => _switchMode(true),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: colors.errorContainer,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: colors.onErrorContainer,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(
                                  color: colors.onErrorContainer,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    if (_isRegisterMode) ...[
                      TextFormField(
                        controller: _nameController,
                        textCapitalization: TextCapitalization.words,
                        autofillHints: const [AutofillHints.name],
                        decoration: const InputDecoration(
                          labelText: 'Full name',
                          hintText: 'Your full name',
                          prefixIcon: Icon(Icons.person_outline),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (_isRegisterMode &&
                              (value?.trim().isEmpty ?? true)) {
                            return 'Please enter your name.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                    ],

                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      autofillHints: const [AutofillHints.email],
                      decoration: const InputDecoration(
                        labelText: 'Email address',
                        hintText: 'you@example.com',
                        prefixIcon: Icon(Icons.email_outlined),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        final email = value?.trim() ?? '';

                        if (email.isEmpty) {
                          return 'Please enter your email address.';
                        }

                        if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                            .hasMatch(email)) {
                          return 'Enter a valid email address.';
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      autofillHints: _isRegisterMode
                          ? const [AutofillHints.newPassword]
                          : const [AutofillHints.password],
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          tooltip: _obscurePassword
                              ? 'Show password'
                              : 'Hide password',
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password.';
                        }

                        if (_isRegisterMode && value.length < 8) {
                          return 'Use at least 8 characters.';
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 22),

                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: busy ? null : _submitEmail,
                        child: _isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                _isRegisterMode
                                    ? 'Create account'
                                    : 'Sign in',
                              ),
                      ),
                    ),
                    const SizedBox(height: 22),

                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                          ),
                          child: Text(
                            'OR CONTINUE WITH',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colors.onSurfaceVariant,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 22),

                    SizedBox(
                      height: 52,
                      child: OutlinedButton.icon(
                        onPressed: busy ? null : _signInWithGoogle,
                        icon: _isGoogleLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Image.asset(
                                'assets/images/g-logo.png',
                                height: 18,
                                width: 18,
                              ),
                        label: Flexible(
                          child: Text(
                            _isGoogleLoading
                                ? 'Connecting to Google...'
                                : 'Continue with Google',
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),

                    Text(
                      _isRegisterMode
                          ? 'Already have an account?'
                          : 'New to CIO Africa?',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium,
                    ),
                    TextButton(
                      onPressed: busy
                          ? null
                          : () => _switchMode(!_isRegisterMode),
                      child: Text(
                        _isRegisterMode
                            ? 'Sign in instead'
                            : 'Create an account',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _modeButton({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return Material(
      color: selected ? theme.colorScheme.surface : Colors.transparent,
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        borderRadius: BorderRadius.circular(9),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              color: selected
                  ? theme.colorScheme.onSurface
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
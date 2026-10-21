// lib/main_prod.dart
//
// Production entry point. Build with:
//   flutter build apk -t lib/main_prod.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'features/auth/auth_providers.dart';
import 'features/home/home_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Guard: refuse to run if the API base is still the staging default.
  // This prevents shipping a production build that accidentally hits
  // staging. If you see this assertion, pass
  //   --dart-define=CIO_API_BASE=https://cioafrica.co/wp-json/cio/v1
  assert(
    !_looksLikeStaging(apiBase),
    'main_prod.dart was built with the staging API base. '
    'Pass --dart-define=CIO_API_BASE=https://cioafrica.co/wp-json/cio/v1',
  );

  final container = ProviderContainer();
  try {
    await container.read(apiClientProvider.future);
    await container.read(authControllerProvider.future);
  } catch (_) {}

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const CioAfricaApp(),
    ),
  );
}

bool _looksLikeStaging(String url) {
  return url.contains('staging') || url.contains('ngrok');
}

// apiBase is exposed via the top-level getter for the assert above.
String get apiBase => const String.fromEnvironment(
      'CIO_API_BASE',
      defaultValue: 'https://staging.cioafrica.co/wp-json/cio/v1',
    );
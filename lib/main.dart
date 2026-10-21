import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'features/auth/auth_providers.dart';
import 'features/home/home_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  debugPrint('[startup] main() entered');

  final container = ProviderContainer();

  try {
    await container.read(apiClientProvider.future);
    debugPrint('[startup] apiClient ready');

    final session = await container.read(authControllerProvider.future);
    debugPrint('[startup] auth build complete: signedIn=${session.signedIn}');
  } catch (e, st) {
    debugPrint('[startup] init failed: $e');
    debugPrint('[startup] stack: $st');
  }

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const CioAfricaApp(),
    ),
  );
}
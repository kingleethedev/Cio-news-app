import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../home/home_providers.dart';
import 'data/payments_repository.dart';

final paymentsRepositoryProvider =
    FutureProvider<PaymentsRepository>((ref) async {
  final client = await ref.watch(apiClientProvider.future);
  return PaymentsRepository(client);
});
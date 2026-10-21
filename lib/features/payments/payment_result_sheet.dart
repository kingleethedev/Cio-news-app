import 'package:flutter/material.dart';

class PaymentResultSheet extends StatelessWidget {
  const PaymentResultSheet._({
    required this.title,
    required this.message,
    required this.icon,
    required this.iconColor,
    this.primaryLabel,
    this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
  });

  final String title;
  final String message;
  final IconData icon;
  final Color iconColor;
  final String? primaryLabel;
  final VoidCallback? onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  factory PaymentResultSheet.success({
    required String message,
    VoidCallback? onDone,
  }) {
    return PaymentResultSheet._(
      title: 'Payment successful',
      message: message,
      icon: Icons.check_circle_outline,
      iconColor: const Color(0xFF2E7D32),
      primaryLabel: 'Done',
      onPrimary: onDone,
    );
  }

  factory PaymentResultSheet.pending({VoidCallback? onRetry, VoidCallback? onLater}) {
    return PaymentResultSheet._(
      title: 'Awaiting confirmation',
      message:
          'We have not received confirmation from the payment provider yet. '
          'This sometimes takes a minute. You can retry or continue browsing '
          'and come back later.',
      icon: Icons.hourglass_top,
      iconColor: const Color(0xFFEF6C00),
      primaryLabel: 'Check again',
      onPrimary: onRetry,
      secondaryLabel: 'Later',
      onSecondary: onLater,
    );
  }

  factory PaymentResultSheet.failed({
    String message = 'The payment did not complete.',
    VoidCallback? onRetry,
    VoidCallback? onClose,
  }) {
    return PaymentResultSheet._(
      title: 'Payment failed',
      message: message,
      icon: Icons.error_outline,
      iconColor: const Color(0xFFC62828),
      primaryLabel: 'Try again',
      onPrimary: onRetry,
      secondaryLabel: 'Close',
      onSecondary: onClose,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(icon, size: 56, color: iconColor),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            if (primaryLabel != null)
              FilledButton(
                onPressed: onPrimary ?? () => Navigator.of(context).pop(),
                child: Text(primaryLabel!),
              ),
            if (secondaryLabel != null) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: onSecondary ?? () => Navigator.of(context).pop(),
                child: Text(secondaryLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

Future<void> showPaymentResult(
  BuildContext context, {
  required PaymentResultSheet sheet,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isDismissible: false,
    enableDrag: false,
    builder: (_) => sheet,
  );
}
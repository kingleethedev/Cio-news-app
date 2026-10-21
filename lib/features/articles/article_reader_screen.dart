import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/config/api_config.dart';
import '../../core/network/api_exception.dart';
import '../auth/auth_providers.dart';
import '../home/home_providers.dart';
import '../payments/checkout_screen.dart';
import '../payments/payment_result_sheet.dart';
import '../payments/payments_providers.dart';
import 'data/models/article_block.dart';
import 'data/models/article_detail.dart';

class ArticleReaderScreen extends ConsumerWidget {
  const ArticleReaderScreen({super.key, required this.slug});
  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final article = ref.watch(articleProvider(slug));
    return Scaffold(
      appBar: AppBar(
        actions: [
          article.whenOrNull(
                data: (a) => IconButton(
                  icon: const Icon(Icons.share_outlined),
                  onPressed: () => _share(a),
                ),
              ) ??
              const SizedBox.shrink(),
        ],
      ),
      body: article.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ReaderError(
          error: e,
          onRetry: () => ref.invalidate(articleProvider(slug)),
        ),
        data: (a) => _ReaderBody(article: a),
      ),
    );
  }

  void _share(ArticleDetail a) {
    final url = ApiConfig.shareUrl(a.canonicalUrl, a.id);
    Share.share('${a.title}\n\nRead more on CIO Africa:\n$url');
  }
}

class _ReaderBody extends StatelessWidget {
  const _ReaderBody({required this.article});
  final ArticleDetail article;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hero = article.hero?.forHero;
    final heroUrl = hero == null ? null : ApiConfig.resolveUrl(hero.url);
    final date = DateFormat.yMMMMd().format(article.publishedAt.toLocal());

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        if (article.section != null)
          Text(
            article.section!.name.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.primary,
              letterSpacing: 1.2,
            ),
          ),
        const SizedBox(height: 8),
        Text(
          article.title,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            height: 1.2,
          ),
        ),
        if (article.dek.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            article.dek,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        const SizedBox(height: 12),
        Text(
          '$date · ${article.readingTimeMin} min read',
          style: theme.textTheme.labelMedium,
        ),
        if (heroUrl != null) ...[
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: heroUrl,
              fit: BoxFit.cover,
              placeholder: (_, __) => const AspectRatio(
                aspectRatio: 16 / 9,
                child: ColoredBox(color: Colors.black12),
              ),
              errorWidget: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
          if (article.hero?.caption?.isNotEmpty == true) ...[
            const SizedBox(height: 6),
            Text(article.hero!.caption!, style: theme.textTheme.bodySmall),
          ],
        ],
        const SizedBox(height: 20),
        ...article.blocks.map((b) => _BlockView(block: b)),
        if (article.truncated || !article.access.allowed) ...[
          const SizedBox(height: 24),
          _PaywallCard(article: article),
        ],
      ],
    );
  }
}

class _BlockView extends StatelessWidget {
  const _BlockView({required this.block});
  final ArticleBlock block;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    switch (block) {
      case HtmlBlock(:final html):
        final text = html
            .replaceAll(RegExp(r'<br\s*/?>'), '\n')
            .replaceAll(RegExp(r'</p>\s*<p>'), '\n\n')
            .replaceAll(RegExp(r'<[^>]+>'), '')
            .trim();
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(
            text,
            style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
          ),
        );
      case HeadingBlock(:final text):
        return Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 8),
          child: Text(
            text,
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
        );
      case PullQuoteBlock(:final text, :final attribution):
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.only(left: 16),
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(
                      color: theme.colorScheme.primary,
                      width: 4,
                    ),
                  ),
                ),
                child: Text(
                  text,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                    height: 1.4,
                  ),
                ),
              ),
              if (attribution != null && attribution.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('— $attribution', style: theme.textTheme.labelMedium),
              ],
            ],
          ),
        );
      case ListBlock(:final ordered, :final items):
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < items.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 28,
                        child: Text(ordered ? '${i + 1}.' : '•'),
                      ),
                      Expanded(
                        child: Text(
                          items[i],
                          style: theme.textTheme.bodyLarge
                              ?.copyWith(height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      case ImageBlock(:final url, :final alt, :final caption):
        final resolved = ApiConfig.resolveUrl(url);
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: resolved,
                  fit: BoxFit.cover,
                ),
              ),
              if (caption != null && caption.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(caption, style: theme.textTheme.bodySmall),
              ] else if (alt != null && alt.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(alt, style: theme.textTheme.bodySmall),
              ],
            ],
          ),
        );
      case UnknownBlock():
        return const SizedBox.shrink();
    }
  }
}

class _PaywallCard extends ConsumerStatefulWidget {
  const _PaywallCard({required this.article});
  final ArticleDetail article;

  @override
  ConsumerState<_PaywallCard> createState() => _PaywallCardState();
}

class _PaywallCardState extends ConsumerState<_PaywallCard> {
  static const Color _ctaRed = Color(0xFFD32F2F);

  bool _busy = false;

  ArticleDetail get article => widget.article;

  /// Refresh the WordPress REST nonce before an authenticated POST.
  /// Nonces rotate server-side; the one we hold may be stale.
  /// Failure here is non-fatal — the POST will proceed with the last
  /// known nonce, and if the server rejects it we surface the error.
  Future<void> _refreshNonceQuietly() async {
    try {
      final repo = await ref.read(authRepositoryProvider.future);
      await repo.refreshNonce();
    } catch (_) {
      // Ignored on purpose.
    }
  }

  Future<void> _onSubscribe() async {
    final session = ref.readSession();
    if (!session.signedIn) {
      context.push('/login');
      return;
    }
    if (!ApiConfig.enablePayments) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Premium subscription is not enabled in this build.'),
        ),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      await _refreshNonceQuietly();

      final repo = await ref.read(paymentsRepositoryProvider.future);
      final init = await repo.purchaseSubscription(
        email: session.userEmail ?? '',
        phone: '',
        firstName: session.userName ?? '',
        lastName: '',
        returnUrl: ApiConfig.paymentReturnUrl,
      );

      if (!mounted) return;

      if (init.needsNoRedirect) {
        ref.invalidate(articleProvider(article.slug));
        return;
      }

      final result = await Navigator.of(context).push<CheckoutResult>(
        MaterialPageRoute(
          builder: (_) => CheckoutScreen(
            url: init.url!,
            reference: init.reference ?? '',
          ),
        ),
      );

      if (!mounted) return;
      if (result == CheckoutResult.completed ||
          result == CheckoutResult.cancelled) {
        await _pollUntilSettled(
          merchantRef: init.reference ?? '',
          premium: true,
        );
      }
    } on WordPressApiException catch (e) {
      if (mounted) {
        await showPaymentResult(
          context,
          sheet: PaymentResultSheet.failed(message: e.message),
        );
      }
    } on NetworkException catch (e) {
      if (mounted) {
        await showPaymentResult(
          context,
          sheet: PaymentResultSheet.failed(message: e.message),
        );
      }
    } catch (e) {
      if (mounted) {
        await showPaymentResult(
          context,
          sheet: PaymentResultSheet.failed(
            message: 'Unexpected error: $e',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _onBuyArticle() async {
    final session = ref.readSession();
    if (!session.signedIn) {
      context.push('/login');
      return;
    }
    if (!ApiConfig.enablePayments) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Single-article purchase is not enabled in this build.'),
        ),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      await _refreshNonceQuietly();

      final repo = await ref.read(paymentsRepositoryProvider.future);
      final init = await repo.purchaseArticle(
        postId: article.id,
        email: session.userEmail ?? '',
        phone: '',
        firstName: session.userName ?? '',
        lastName: '',
      );

      if (!mounted) return;

      if (init.needsNoRedirect) {
        ref.invalidate(articleProvider(article.slug));
        return;
      }

      final result = await Navigator.of(context).push<CheckoutResult>(
        MaterialPageRoute(
          builder: (_) => CheckoutScreen(
            url: init.url!,
            reference: init.reference ?? '',
          ),
        ),
      );

      if (!mounted) return;
      if (result == CheckoutResult.completed ||
          result == CheckoutResult.cancelled) {
        await _pollUntilSettled(
          merchantRef: init.reference ?? '',
          postId: article.id,
        );
      }
    } on WordPressApiException catch (e) {
      if (mounted) {
        await showPaymentResult(
          context,
          sheet: PaymentResultSheet.failed(message: e.message),
        );
      }
    } on NetworkException catch (e) {
      if (mounted) {
        await showPaymentResult(
          context,
          sheet: PaymentResultSheet.failed(message: e.message),
        );
      }
    } catch (e) {
      if (mounted) {
        await showPaymentResult(
          context,
          sheet: PaymentResultSheet.failed(
            message: 'Unexpected error: $e',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pollUntilSettled({
    required String merchantRef,
    int? postId,
    bool premium = false,
  }) async {
    final repo = await ref.read(paymentsRepositoryProvider.future);
    for (var i = 0; i < ApiConfig.paymentPollMaxAttempts; i++) {
      await Future.delayed(ApiConfig.paymentPollInterval);
      try {
        final status = await repo.orderStatus(
          ref: merchantRef,
          postId: postId,
          premium: premium,
        );
        if (status.settled) {
          if (!mounted) return;
          ref.invalidate(articleProvider(article.slug));
          await showPaymentResult(
            context,
            sheet: PaymentResultSheet.success(
              message: premium
                  ? 'Your Premium subscription is active. '
                      'Every article is now unlocked.'
                  : 'You now have access to this article.',
              onDone: () => Navigator.of(context).pop(),
            ),
          );
          return;
        }
        if (status.failed) {
          if (!mounted) return;
          await showPaymentResult(
            context,
            sheet: PaymentResultSheet.failed(
              message: status.message ??
                  'The payment was declined or failed.',
              onRetry: () {
                Navigator.of(context).pop();
                _onSubscribe();
              },
            ),
          );
          return;
        }
        // Pending — keep polling.
      } catch (_) {
        // Transient — keep polling.
      }
    }
    if (!mounted) return;
    await showPaymentResult(
      context,
      sheet: PaymentResultSheet.pending(
        onRetry: () {
          Navigator.of(context).pop();
          _pollUntilSettled(
            merchantRef: merchantRef,
            postId: postId,
            premium: premium,
          );
        },
        onLater: () => Navigator.of(context).pop(),
      ),
    );
  }

  void _onLogIn() {
    final session = ref.readSession();
    context.push(session.signedIn ? '/profile' : '/login');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final annualPrice = ApiConfig.formatPriceCompact(
      ApiConfig.premiumAnnualPriceMinorUnits,
    );
    final articlePriceCents = article.access.price;
    final showBuyArticle = articlePriceCents > 0;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Text(
              'CIO AFRICA',
              style: theme.textTheme.labelSmall?.copyWith(
                letterSpacing: 2.4,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              'PREMIUM ARTICLE',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontFamily: 'serif',
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              'This article is available to Premium Members.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color:
                    theme.colorScheme.onSurface.withValues(alpha: 0.6),
                width: 1.5,
              ),
            ),
            child: Column(
              children: [
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: theme.colorScheme.onSurface,
                    ),
                    children: [
                      TextSpan(text: annualPrice),
                      TextSpan(
                        text: ' / year',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: _ctaRed,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: _busy ? null : _onSubscribe,
                    child: _busy
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Subscribe to Premium',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Divider(color: theme.colorScheme.outlineVariant),
          const SizedBox(height: 20),
          if (showBuyArticle) ...[
            Center(
              child: Text(
                'Just want this article?',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Center(
              child: Text(
                'Buy access for '
                '${ApiConfig.formatPrice(articlePriceCents)}.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 48,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.colorScheme.onSurface,
                  side: BorderSide(
                    color: theme.colorScheme.onSurface
                        .withValues(alpha: 0.7),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: _busy ? null : _onBuyArticle,
                child: const Text(
                  'Buy This Article',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
          Consumer(
            builder: (context, ref, _) {
              final session = ref.watchSession();
              final isSignedIn = session.signedIn;
              final isPremium = session.premium;

              if (isPremium) return const SizedBox.shrink();

              if (isSignedIn) {
                return Center(
                  child: Text(
                    'You are signed in as a Free member.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                );
              }

              return Center(
                child: Text.rich(
                  TextSpan(
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    children: [
                      const TextSpan(
                          text: 'Already a Premium member? '),
                      WidgetSpan(
                        alignment: PlaceholderAlignment.baseline,
                        baseline: TextBaseline.alphabetic,
                        child: GestureDetector(
                          onTap: _onLogIn,
                          child: Text(
                            'Log in',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w700,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ReaderError extends StatelessWidget {
  const _ReaderError({required this.error, required this.onRetry});
  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: 16),
              Text(error.toString(), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ),
        ),
      );
}
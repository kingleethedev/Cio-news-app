import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/config/api_config.dart';
import '../../core/network/api_exception.dart';
import '../articles/data/models/article.dart';
import '../auth/auth_providers.dart';
import 'home_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = ref.watch(feedProvider);
    final session = ref.watchSession();

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        title: Image.asset(
          'assets/images/cio_africa_logo.png',
          height: 36,
          fit: BoxFit.contain,
          semanticLabel: 'CIO Africa',
        ),
        actions: [
          IconButton(
            icon: Icon(
              session.signedIn ? Icons.account_circle : Icons.person_outline,
            ),
            tooltip: session.signedIn ? 'Account' : 'Sign in',
            onPressed: () => context.push(
              session.signedIn ? '/profile' : '/login',
            ),
          ),
        ],
      ),
      body: feed.when(
        loading: () => const _FeedSkeleton(),
        error: (e, _) => _FeedError(
          error: e,
          onRetry: () => ref.read(feedProvider.notifier).refresh(),
        ),
        data: (state) {
          if (state.items.isEmpty) {
            return const _EmptyState();
          }
          return RefreshIndicator(
            onRefresh: () => ref.read(feedProvider.notifier).refresh(),
            child: NotificationListener<ScrollNotification>(
              onNotification: (n) {
                if (n.metrics.pixels >= n.metrics.maxScrollExtent - 400) {
                  ref.read(feedProvider.notifier).loadMore();
                }
                return false;
              },
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: state.items.length + (state.loadingMore ? 1 : 0),
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  if (i >= state.items.length) {
                    return const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  return _ArticleCard(article: state.items[i]);
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Thumbnail size used across the feed. Keep these in one place so the
/// placeholder and the loaded image match exactly.
const double _thumbWidth = 110;
const double _thumbHeight = 80;

/// Neutral grey used for the placeholder when no image is available.
/// Picked to look like a soft paper tone rather than a system grey, so
/// it blends with the editorial feel of the rest of the app.
const Color _thumbPlaceholderColor = Color(0xFFE8E8E8);

class _ArticleCard extends ConsumerWidget {
  const _ArticleCard({required this.article});
  final Article article;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final session = ref.watchSession();

    final card = article.hero?.forCard;
    final imgUrl = card == null ? null : ApiConfig.resolveUrl(card.url);
    final date = DateFormat.yMMMd().format(article.publishedAt.toLocal());

    return InkWell(
      onTap: () {
        if (!session.signedIn && ApiConfig.requireLoginForAllContent) {
          context.push('/login');
          return;
        }
        context.push('/article/${article.slug}');
      },
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail — always occupies the same space, whether or not
            // the article has an image. Missing image = plain grey box.
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: _thumbWidth,
                height: _thumbHeight,
                child: imgUrl == null
                    ? const ColoredBox(color: _thumbPlaceholderColor)
                    : CachedNetworkImage(
                        imageUrl: imgUrl,
                        width: _thumbWidth,
                        height: _thumbHeight,
                        fit: BoxFit.cover,
                        // Grey placeholder while loading, grey on error,
                        // no icons anywhere.
                        placeholder: (_, __) =>
                            const ColoredBox(color: _thumbPlaceholderColor),
                        errorWidget: (_, __, ___) =>
                            const ColoredBox(color: _thumbPlaceholderColor),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (article.section != null)
                    Text(
                      article.section!.name.toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        letterSpacing: 1.2,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    article.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                  if (article.dek.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      article.dek,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(date, style: theme.textTheme.labelSmall),
                      const SizedBox(width: 8),
                      Text(
                        '${article.readingTimeMin} min read',
                        style: theme.textTheme.labelSmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeedSkeleton extends StatelessWidget {
  const _FeedSkeleton();

  @override
  Widget build(BuildContext context) => ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: 6,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (_, __) => Row(
          children: [
            // Match the real thumbnail size so the skeleton is a true
            // preview of the loaded layout.
            Container(
              width: _thumbWidth,
              height: _thumbHeight,
              color: _thumbPlaceholderColor,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 12, color: Colors.black12),
                  const SizedBox(height: 8),
                  Container(height: 12, width: 180, color: Colors.black12),
                  const SizedBox(height: 8),
                  Container(height: 12, width: 120, color: Colors.black12),
                ],
              ),
            ),
          ],
        ),
      );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) => const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text('No articles yet. Pull to refresh.'),
        ),
      );
}

class _FeedError extends StatelessWidget {
  const _FeedError({required this.error, required this.onRetry});
  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final message = switch (error) {
      NgrokInterstitialException _ =>
        'ngrok is showing a browser-warning page. Rebuild with '
            '--dart-define=CIO_BYPASS_NGROK=true and --dart-define=CIO_DEV=true.',
      NetworkException _ => 'Could not reach the server. Pull to retry.',
      WordPressApiException _ => 'The server returned an error.',
      _ => 'Something went wrong.',
    };
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../articles/data/articles_repository.dart';
import '../articles/data/models/article.dart';

/// ApiClient is now created asynchronously (cookie jar init).
final apiClientProvider = FutureProvider<ApiClient>((ref) async {
  return ApiClient.create();
});

final articlesRepositoryProvider = FutureProvider<ArticlesRepository>((ref) async {
  final client = await ref.watch(apiClientProvider.future);
  return ArticlesRepository(client);
});

class FeedState {
  final List<Article> items;
  final String? cursor;
  final bool hasMore;
  final bool loadingMore;
  final Object? error;
  const FeedState({
    this.items = const [],
    this.cursor,
    this.hasMore = true,
    this.loadingMore = false,
    this.error,
  });
  FeedState copyWith({
    List<Article>? items,
    String? cursor,
    bool? hasMore,
    bool? loadingMore,
    Object? error,
    bool clearError = false,
  }) =>
      FeedState(
        items: items ?? this.items,
        cursor: cursor ?? this.cursor,
        hasMore: hasMore ?? this.hasMore,
        loadingMore: loadingMore ?? this.loadingMore,
        error: clearError ? null : (error ?? this.error),
      );
}

class FeedNotifier extends AsyncNotifier<FeedState> {
  @override
  Future<FeedState> build() async {
    final repo = await ref.watch(articlesRepositoryProvider.future);
    final page = await repo.feed();
    return FeedState(
      items: page.items,
      cursor: page.nextCursor,
      hasMore: page.hasMore,
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = await ref.read(articlesRepositoryProvider.future);
      final page = await repo.feed();
      return FeedState(
        items: page.items,
        cursor: page.nextCursor,
        hasMore: page.hasMore,
      );
    });
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore || current.loadingMore) return;
    state = AsyncData(current.copyWith(loadingMore: true, clearError: true));
    try {
      final repo = await ref.read(articlesRepositoryProvider.future);
      final page = await repo.feed(cursor: current.cursor);
      final seen = current.items.map((a) => a.id).toSet();
      final merged = [
        ...current.items,
        ...page.items.where((a) => !seen.contains(a.id)),
      ];
      state = AsyncData(FeedState(
        items: merged,
        cursor: page.nextCursor,
        hasMore: page.hasMore,
        loadingMore: false,
      ));
    } catch (e) {
      state = AsyncData(current.copyWith(loadingMore: false, error: e));
    }
  }
}

final feedProvider =
    AsyncNotifierProvider<FeedNotifier, FeedState>(FeedNotifier.new);

final articleProvider = FutureProvider.family((ref, String slug) async {
  final repo = await ref.watch(articlesRepositoryProvider.future);
  return repo.article(slug);
});
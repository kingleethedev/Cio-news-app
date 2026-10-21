import '../../../core/config/api_config.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import 'models/article_detail.dart';
import 'models/feed_page.dart';

class ArticlesRepository {
  ArticlesRepository(this._client);
  final ApiClient _client;

  Future<FeedPage> feed({
    int limit = 20,
    String? cursor,
    String? since,
    String? section,
    String? tag,
  }) async {
    final json = await _client.getJson('/feed', query: {
      'limit': limit,
      if (cursor != null) 'cursor': cursor,
      if (since != null) 'since': since,
      if (section != null) 'section': section,
      if (tag != null) 'tag': tag,
    });
    final page = FeedPage.fromJson(json);
    if (page.items.isEmpty && (cursor == null || cursor.isEmpty)) {
      throw const EmptyFeedException();
    }
    return page;
  }

  Future<ArticleDetail> article(String slug) async {
    final json = await _client.getJson('/article/$slug');
    return ArticleDetail.fromJson(json);
  }
}

/// Convenience for the UI: rewrite rendition URLs through the dev-only mapper.
extension RenditionUrlX on String {
  String get resolved => ApiConfig.resolveUrl(this);
}
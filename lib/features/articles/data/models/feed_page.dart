import 'article.dart';

class FeedPage {
  final List<Article> items;
  final String? nextCursor;
  final bool hasMore;
  final String? feedVersion;
  final DateTime? generatedAt;

  const FeedPage({
    required this.items,
    required this.nextCursor,
    required this.hasMore,
    required this.feedVersion,
    required this.generatedAt,
  });

  factory FeedPage.fromJson(Map<String, dynamic> j) => FeedPage(
        items: (j['items'] as List? ?? const [])
            .whereType<Map>()
            .map((m) => Article.fromJson(Map<String, dynamic>.from(m)))
            .toList(),
        nextCursor: j['next_cursor'] as String?,
        hasMore: j['has_more'] == true,
        feedVersion: j['feed_version']?.toString(),
        generatedAt: DateTime.tryParse(j['generated_at'] as String? ?? ''),
      );
}
import 'access_info.dart';
import 'article_block.dart';
import 'article.dart';
import 'hero.dart';

class ArticleDetail {
  final int id;
  final String slug;
  final String type;
  final String title;
  final String dek;
  final String canonicalUrl;
  final DateTime publishedAt;
  final DateTime? updatedAt;
  final int readingTimeMin;
  final SectionRef? section;
  final List<Author> authors;
  final List<String> tags;
  final Hero? hero;
  final bool isSponsored;
  final ArticleAccess access;
  final bool truncated;
  final List<ArticleBlock> blocks;

  const ArticleDetail({
    required this.id,
    required this.slug,
    required this.type,
    required this.title,
    required this.dek,
    required this.canonicalUrl,
    required this.publishedAt,
    required this.updatedAt,
    required this.readingTimeMin,
    required this.section,
    required this.authors,
    required this.tags,
    required this.hero,
    required this.isSponsored,
    required this.access,
    required this.truncated,
    required this.blocks,
  });

  factory ArticleDetail.fromJson(Map<String, dynamic> j) => ArticleDetail(
        id: (j['id'] as num).toInt(),
        slug: (j['slug'] as String?) ?? '',
        type: (j['type'] as String?) ?? 'news',
        title: (j['title'] as String?) ?? '',
        dek: (j['dek'] as String?) ?? '',
        canonicalUrl: (j['canonical_url'] as String?) ?? '',
        publishedAt: DateTime.tryParse(j['published_at'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
        updatedAt: DateTime.tryParse(j['updated_at'] as String? ?? ''),
        readingTimeMin: (j['reading_time_min'] as num?)?.toInt() ?? 1,
        section: j['section'] is Map
            ? SectionRef.fromJson(Map<String, dynamic>.from(j['section'] as Map))
            : null,
        authors: (j['authors'] as List?)
                ?.whereType<Map>()
                .map((m) => Author.fromJson(Map<String, dynamic>.from(m)))
                .toList() ??
            const [],
        tags: (j['tags'] as List?)?.whereType<String>().toList() ?? const [],
        hero: Hero.fromJson(j['hero']),
        isSponsored: j['is_sponsored'] == true,
        access: j['access'] is Map
            ? ArticleAccess.fromJson(Map<String, dynamic>.from(j['access'] as Map))
            : const ArticleAccess(
                mode: AccessMode.unknown, price: 0, allowed: false, reason: ''),
        truncated: j['truncated'] == true,
        blocks: (j['blocks'] as List? ?? const [])
            .whereType<Map>()
            .map((m) => ArticleBlock.fromJson(Map<String, dynamic>.from(m)))
            .toList(),
      );
}
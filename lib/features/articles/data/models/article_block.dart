/// Sealed hierarchy of structured content blocks.
/// Unknown types render nothing (never crash).
sealed class ArticleBlock {
  const ArticleBlock();

  static ArticleBlock fromJson(Map<String, dynamic> j) {
    final type = (j['type'] as String?) ?? '';
    switch (type) {
      case 'paragraph':
      case 'html':
        return HtmlBlock((j['html'] as String?) ?? '');
      case 'heading':
        return HeadingBlock(
          level: (j['level'] as num?)?.toInt() ?? 2,
          text: (j['text'] as String?) ?? '',
        );
      case 'pullquote':
      case 'quote':
        return PullQuoteBlock(
          text: (j['text'] as String?) ?? '',
          attribution: j['attribution'] as String?,
        );
      case 'list':
        return ListBlock(
          ordered: j['ordered'] == true,
          items: (j['items'] as List?)?.whereType<String>().toList() ?? const [],
        );
      case 'image':
        return ImageBlock(
          url: (j['url'] as String?) ?? '',
          alt: j['alt'] as String?,
          caption: j['caption'] as String?,
          credit: j['credit'] as String?,
        );
      default:
        return const UnknownBlock();
    }
  }
}

class HtmlBlock extends ArticleBlock {
  final String html;
  const HtmlBlock(this.html);
}

class HeadingBlock extends ArticleBlock {
  final int level;
  final String text;
  const HeadingBlock({required this.level, required this.text});
}

class PullQuoteBlock extends ArticleBlock {
  final String text;
  final String? attribution;
  const PullQuoteBlock({required this.text, this.attribution});
}

class ListBlock extends ArticleBlock {
  final bool ordered;
  final List<String> items;
  const ListBlock({required this.ordered, required this.items});
}

class ImageBlock extends ArticleBlock {
  final String url;
  final String? alt;
  final String? caption;
  final String? credit;
  const ImageBlock({required this.url, this.alt, this.caption, this.credit});
}

class UnknownBlock extends ArticleBlock {
  const UnknownBlock();
}
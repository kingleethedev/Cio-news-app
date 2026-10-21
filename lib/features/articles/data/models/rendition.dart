/// Parses a rendition that may be either a plain URL string (per current docs)
/// or a {url,w,h} object (as seen in the live local API). Both shapes are supported.
class Rendition {
  final String url;
  final int? width;
  final int? height;

  const Rendition({required this.url, this.width, this.height});

  static Rendition? parse(dynamic value) {
    if (value == null) return null;
    if (value is String) {
      return value.isEmpty ? null : Rendition(url: value);
    }
    if (value is Map) {
      final url = value['url'];
      if (url is! String || url.isEmpty) return null;
      return Rendition(
        url: url,
        width: value['w'] is int ? value['w'] as int : null,
        height: value['h'] is int ? value['h'] as int : null,
      );
    }
    return null;
  }
}
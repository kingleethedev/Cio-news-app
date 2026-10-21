import 'rendition.dart';

class Hero {
  final int? mediaId;
  final String? alt;
  final String? caption;
  final String? credit;
  final double? focalX;
  final double? focalY;
  final Rendition? heroWeb;
  final Rendition? card;
  final Rendition? thumb;

  const Hero({
    this.mediaId,
    this.alt,
    this.caption,
    this.credit,
    this.focalX,
    this.focalY,
    this.heroWeb,
    this.card,
    this.thumb,
  });

  static Hero? fromJson(dynamic json) {
    if (json is! Map) return null;
    final rends = json['renditions'];
    Rendition? pick(String k) => (rends is Map) ? Rendition.parse(rends[k]) : null;
    final focal = json['focal'];
    return Hero(
      mediaId: json['media_id'] is int ? json['media_id'] as int : null,
      alt: json['alt'] as String?,
      caption: json['caption'] as String?,
      credit: json['credit'] as String?,
      focalX: (focal is Map && focal['x'] is num)
          ? (focal['x'] as num).toDouble()
          : null,
      focalY: (focal is Map && focal['y'] is num)
          ? (focal['y'] as num).toDouble()
          : null,
      heroWeb: pick('hero-web'),
      card: pick('card'),
      thumb: pick('thumb'),
    );
  }

  /// Best rendition for list cards.
  Rendition? get forCard => card ?? heroWeb ?? thumb;

  /// Best rendition for the reader hero.
  Rendition? get forHero => heroWeb ?? card ?? thumb;
}
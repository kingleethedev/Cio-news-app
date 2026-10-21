enum AccessMode { free, metered, paid, subscriber, unknown }

AccessMode parseAccessMode(String? s) {
  switch (s) {
    case 'free': return AccessMode.free;
    case 'metered': return AccessMode.metered;
    case 'paid': return AccessMode.paid;
    case 'subscriber': return AccessMode.subscriber;
    default: return AccessMode.unknown;
  }
}

/// Feed-level summary.
class AccessInfo {
  final AccessMode mode;
  final int price; // minor units (cents)
  final bool open;
  const AccessInfo({required this.mode, required this.price, required this.open});

  factory AccessInfo.fromJson(Map<String, dynamic> json) => AccessInfo(
        mode: parseAccessMode(json['mode'] as String?),
        price: (json['price'] as num?)?.toInt() ?? 0,
        open: json['open'] == true,
      );

  static AccessInfo empty() =>
      const AccessInfo(mode: AccessMode.unknown, price: 0, open: false);
}

/// Article-level detailed access. Fields are additive to the feed summary.
class ArticleAccess {
  final AccessMode mode;
  final int price;
  final bool allowed;
  final String reason; // free-form; mapped defensively by the UI
  final int? remaining;
  final bool purchasable;
  final bool signIn;

  const ArticleAccess({
    required this.mode,
    required this.price,
    required this.allowed,
    required this.reason,
    this.remaining,
    this.purchasable = false,
    this.signIn = false,
  });

  factory ArticleAccess.fromJson(Map<String, dynamic> json) => ArticleAccess(
        mode: parseAccessMode(json['mode'] as String?),
        price: (json['price'] as num?)?.toInt() ?? 0,
        allowed: json['allowed'] == true,
        reason: (json['reason'] as String?) ?? '',
        remaining: (json['remaining'] as num?)?.toInt(),
        purchasable: json['purchasable'] == true,
        signIn: json['sign_in'] == true,
      );
}
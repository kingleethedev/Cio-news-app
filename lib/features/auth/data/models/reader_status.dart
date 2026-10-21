class ReaderStatus {
  final bool signedIn;
  final bool subscriber;
  final bool premium;
  final int remaining;
  final bool canBuy;
  final String? nonce;

  const ReaderStatus({
    required this.signedIn,
    required this.subscriber,
    required this.premium,
    required this.remaining,
    required this.canBuy,
    required this.nonce,
  });

  factory ReaderStatus.fromJson(Map<String, dynamic> j) => ReaderStatus(
        signedIn: j['signed_in'] == true,
        subscriber: j['subscriber'] == true,
        premium: j['premium'] == true,
        remaining: (j['remaining'] as num?)?.toInt() ?? 0,
        canBuy: j['can_buy'] == true,
        nonce: j['nonce'] as String?,
      );

  static const ReaderStatus anonymous = ReaderStatus(
    signedIn: false,
    subscriber: false,
    premium: false,
    remaining: 0,
    canBuy: false,
    nonce: null,
  );
}

/// Response from POST /access/purchase or /access/purchase-subscription.
///
/// Two shapes are possible, per the plugin docs:
///   1. {ok:true, action:"redirect", reference:"...", url:"...", message:"...", nonce:"..."}
///   2. {already_entitled:true}
///
/// Any response that carries no [url] and is not already_entitled is treated
/// as an error by the caller.
class PurchaseInitiation {
  final bool ok;
  final String? action;
  final String? reference;
  final String? url;
  final String? message;
  final String? nonce;
  final bool alreadyEntitled;

  const PurchaseInitiation({
    required this.ok,
    required this.action,
    required this.reference,
    required this.url,
    required this.message,
    required this.nonce,
    required this.alreadyEntitled,
  });

  factory PurchaseInitiation.fromJson(Map<String, dynamic> j) {
    return PurchaseInitiation(
      ok: j['ok'] == true,
      action: j['action'] as String?,
      reference: j['reference'] as String?,
      url: j['url'] as String?,
      message: j['message'] as String?,
      nonce: j['nonce'] as String?,
      alreadyEntitled: j['already_entitled'] == true,
    );
  }

  /// The caller should skip the checkout WebView and just refresh the
  /// article when this is true.
  bool get needsNoRedirect => alreadyEntitled || (url == null || url!.isEmpty);

  /// The checkout URL is present and ready to open.
  bool get hasCheckoutUrl => url != null && url!.isNotEmpty;
}
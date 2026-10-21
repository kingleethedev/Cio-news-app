/// Response from GET /access/order-status?ref=...&post_id=...&sub=premium
class OrderStatus {
  final bool ok;
  final bool settled;
  final bool failed;
  final String? message;
  final String? articleUrl;

  const OrderStatus({
    required this.ok,
    required this.settled,
    required this.failed,
    required this.message,
    required this.articleUrl,
  });

  factory OrderStatus.fromJson(Map<String, dynamic> j) => OrderStatus(
        ok: j['ok'] == true,
        settled: j['settled'] == true,
        failed: j['failed'] == true,
        message: j['message'] as String?,
        articleUrl: j['article_url'] as String?,
      );

  bool get isPending => ok && !settled && !failed;
}
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import 'models/order_status.dart';
import 'models/purchase_initiation.dart';

/// Wraps the plugin's purchase endpoints. The server is the sole authority
/// on entitlement — this class never grants access client-side.
class PaymentsRepository {
  PaymentsRepository(this._client);
  final ApiClient _client;

  /// POST /wp-json/cio/v1/access/purchase
  Future<PurchaseInitiation> purchaseArticle({
    required int postId,
    required String email,
    required String phone,
    required String firstName,
    required String lastName,
  }) async {
    final json = await _client.postJson('/access/purchase', body: {
      'post_id': postId,
      'email': email,
      'phone': phone,
      'first_name': firstName,
      'last_name': lastName,
    });
    return PurchaseInitiation.fromJson(json);
  }

  /// POST /wp-json/cio/v1/access/purchase-subscription
  Future<PurchaseInitiation> purchaseSubscription({
    required String email,
    required String phone,
    required String firstName,
    required String lastName,
    required String returnUrl,
  }) async {
    final json = await _client.postJson(
      '/access/purchase-subscription',
      body: {
        'email': email,
        'phone': phone,
        'first_name': firstName,
        'last_name': lastName,
        'return_url': returnUrl,
      },
    );
    return PurchaseInitiation.fromJson(json);
  }

  /// GET /wp-json/cio/v1/access/order-status
  Future<OrderStatus> orderStatus({
    required String ref,
    int? postId,
    bool premium = false,
  }) async {
    if (ref.isEmpty) {
      throw const WordPressApiException(
        'missing_ref',
        'No merchant reference available to poll.',
      );
    }
    final json = await _client.getJson('/access/order-status', query: {
      'ref': ref,
      if (postId != null) 'post_id': postId,
      if (premium) 'sub': 'premium',
    });
    return OrderStatus.fromJson(json);
  }
}
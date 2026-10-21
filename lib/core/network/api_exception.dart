/// Typed exceptions so the UI can distinguish ngrok / WP / network / parse issues.
sealed class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? body;
  const ApiException(this.message, {this.statusCode, this.body});
  @override
  String toString() => '$runtimeType($statusCode): $message';
}

/// The ngrok free-tier interstitial page was returned instead of JSON.
/// Body contains "ERR_NGROK_" — that's the reliable signal.
class NgrokInterstitialException extends ApiException {
  const NgrokInterstitialException({int? statusCode, String? body})
      : super(
          'ngrok interstitial page received. Set --dart-define=CIO_BYPASS_NGROK=true '
          'and rebuild, or upgrade ngrok.',
          statusCode: statusCode,
          body: body,
        );
}

/// The tunnel is down, DNS failed, or we timed out.
class NetworkException extends ApiException {
  const NetworkException(String message, {super.statusCode, super.body})
      : super(message);
}

/// WordPress returned a structured JSON error ({code, message, data:{status}}).
class WordPressApiException extends ApiException {
  final String code;
  const WordPressApiException(this.code, String message, {int? statusCode, String? body})
      : super(message, statusCode: statusCode, body: body);
}

/// JSON could not be parsed, or a required field was missing.
class MalformedResponseException extends ApiException {
  const MalformedResponseException(String message, {super.statusCode, super.body})
      : super(message);
}

/// Valid JSON, valid schema, but the feed is empty.
class EmptyFeedException extends ApiException {
  const EmptyFeedException([String message = 'No articles yet.']) : super(message);
}
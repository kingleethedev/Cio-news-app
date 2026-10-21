/// Central API configuration.
///
/// Defaults are set for DEVELOPMENT (staging, dev logging, login required,
/// payments enabled). To build for production, override at build time:
///
///   flutter build apk \
///     --dart-define=CIO_API_BASE=https://cioafrica.co/wp-json/cio/v1 \
///     --dart-define=CIO_DEV=false \
///     --dart-define=CIO_REQUIRE_LOGIN=true \
///     --dart-define=CIO_ENABLE_PAYMENTS=true
///
/// Plain `flutter run` during development uses staging automatically.
class ApiConfig {
  ApiConfig._();

  // ── Endpoints ─────────────────────────────────────────────────────────

  /// REST API base. Must NOT include a trailing slash.
  /// Defaults to staging for development. Override for production.
  static const String apiBase = String.fromEnvironment(
    'CIO_API_BASE',
    defaultValue: 'https://staging.cioafrica.co/wp-json/cio/v1',
  );

  /// Canonical website base, used for sharing.
  static const String shareBase = String.fromEnvironment(
    'CIO_SHARE_BASE',
    defaultValue: 'https://cioafrica.co',
  );

  /// Return URL passed to the plugin after a Pesapal checkout.
  static const String paymentReturnUrl =
      'https://cioafrica.co/premium-confirmation';

  // ── Environment flags ─────────────────────────────────────────────────

  /// True when running in development. Default true so `flutter run`
  /// turns Dio debug logging on without extra flags.
  static const bool isDev =
      bool.fromEnvironment('CIO_DEV', defaultValue: true);

  /// ngrok interstitial bypass. Inert on staging and production.
  static const bool bypassNgrokInterstitial =
      bool.fromEnvironment('CIO_BYPASS_NGROK', defaultValue: false);

  /// Local host rewrite. Inert when the API base is a public HTTPS host.
  static const bool rewriteLocalHost =
      bool.fromEnvironment('CIO_REWRITE_LOCAL_HOST', defaultValue: false);
  static const String localHostToRewrite = 'news-site-test.local';
  static const String devHost =
      String.fromEnvironment('CIO_DEV_HOST', defaultValue: '');

  /// Require sign-in before showing any content. Default true so
  /// `flutter run` opens on the login screen.
  static const bool requireLoginForAllContent =
      bool.fromEnvironment('CIO_REQUIRE_LOGIN', defaultValue: true);

  /// Master switch for payments. Default true so `flutter run` enables
  /// the paywall buttons without extra flags.
  static const bool enablePayments =
      bool.fromEnvironment('CIO_ENABLE_PAYMENTS', defaultValue: true);

  // ── Pricing ───────────────────────────────────────────────────────────

  static const String currencyCode = 'KES';
  static const int priceMinorUnits = 100;
  static const int premiumAnnualPriceMinorUnits = 120000;

  // ── Payment polling ───────────────────────────────────────────────────

  static const Duration paymentPollInterval = Duration(seconds: 3);
  static const int paymentPollMaxAttempts = 40;

  // ── URL helpers ───────────────────────────────────────────────────────

  static String resolveUrl(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    if (!rewriteLocalHost || devHost.isEmpty) return raw;
    final uri = Uri.tryParse(raw);
    if (uri == null || uri.host != localHostToRewrite) return raw;
    return uri.replace(host: devHost, scheme: 'https', port: null).toString();
  }

  static String shareUrl(String canonicalUrl, int articleId) {
    final base = canonicalUrl.isNotEmpty ? canonicalUrl : shareBase;
    final uri = Uri.parse(base);
    final merged = Map<String, String>.from(uri.queryParameters)
      ..addAll({
        'utm_source': 'app',
        'utm_medium': 'share',
        'utm_campaign': 'mobile_share',
        'utm_content': articleId.toString(),
      });
    return uri.replace(queryParameters: merged).toString();
  }

  // ── Price formatting ──────────────────────────────────────────────────

  static String formatPrice(int minorUnits) {
    final major = minorUnits / priceMinorUnits;
    if (major == major.roundToDouble()) {
      final whole = major.toInt().toString();
      final buf = StringBuffer();
      for (var i = 0; i < whole.length; i++) {
        if (i > 0 && (whole.length - i) % 3 == 0) buf.write(',');
        buf.write(whole[i]);
      }
      return '$currencyCode $buf';
    }
    return '$currencyCode ${major.toStringAsFixed(2)}';
  }

  static String formatPriceCompact(int minorUnits) => formatPrice(minorUnits);

  // ── Environment safety net ────────────────────────────────────────────

  /// True when pointed at a non-production API base. Used for a visible
  /// "STAGING" banner so nobody forgets which backend they're on.
  static bool get isNonProduction {
    return apiBase.contains('staging') ||
        apiBase.contains('ngrok') ||
        apiBase.contains('localhost') ||
        apiBase.contains('news-site-test');
  }
}
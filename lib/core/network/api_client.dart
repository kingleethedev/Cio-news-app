import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../config/api_config.dart';
import 'api_exception.dart';
import 'nonce_store.dart';

class ApiClient {
  ApiClient._(this._dio);
  final Dio _dio;

  static Future<ApiClient> create({String? baseUrl}) async {
    final headers = <String, dynamic>{
      'Accept': 'application/json',
      'User-Agent': 'CIOAfricaApp/1.0 (Flutter)',
    };

    if (ApiConfig.isDev && ApiConfig.bypassNgrokInterstitial) {
      headers['ngrok-skip-browser-warning'] = 'true';
    }

    final dio = Dio(BaseOptions(
      baseUrl: baseUrl ?? ApiConfig.apiBase,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      headers: headers,
      validateStatus: (_) => true,
      responseType: ResponseType.json,
    ));

    // ── Persistent cookie jar ─────────────────────────────────────────
    // `ignoreExpires: true` is critical: WordPress may set session-scoped
    // cookies, and PersistCookieJar would otherwise DELETE them on
    // startup. With ignoreExpires, every cookie is written to and read
    // from disk regardless of expiry.
    final dir = await getApplicationSupportDirectory();
    final cookieStorage = FileStorage('${dir.path}/cookies/');
    final cookieJar = PersistCookieJar(
      ignoreExpires: true,
      storage: cookieStorage,
    );
    dio.interceptors.add(CookieManager(cookieJar));

    if (kDebugMode) {
      debugPrint('[cookiejar] storage dir = ${dir.path}/cookies/');
      final uri = Uri.parse(ApiConfig.apiBase);
      cookieJar.loadForRequest(uri).then((cookies) {
        debugPrint(
            '[cookiejar] loaded ${cookies.length} cookies for ${uri.host}');
        for (final c in cookies) {
          debugPrint('[cookiejar]  name=${c.name} expires=${c.expires}');
        }
      });
    }

    // ── Nonce interceptor ─────────────────────────────────────────────
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final nonce = await NonceStore.get();
        if (nonce != null && nonce.isNotEmpty) {
          options.headers['X-WP-Nonce'] = nonce;
        }
        handler.next(options);
      },
    ));

    // ── Retry interceptor for transient network failures ──────────────
    dio.interceptors.add(InterceptorsWrapper(
      onError: (error, handler) async {
        final isGet = error.requestOptions.method.toUpperCase() == 'GET';
        final isConnectionError =
            error.type == DioExceptionType.connectionError;
        final attempt =
            (error.requestOptions.extra['retry_attempt'] as int?) ?? 0;

        if (isGet && isConnectionError && attempt < 2) {
          await Future.delayed(Duration(milliseconds: 400 * (attempt + 1)));
          final opts = error.requestOptions;
          opts.extra['retry_attempt'] = attempt + 1;
          try {
            final response = await dio.fetch(opts);
            return handler.resolve(response);
          } on DioException catch (e) {
            return handler.next(e);
          }
        }
        return handler.next(error);
      },
    ));

    if (kDebugMode) {
      dio.interceptors.add(LogInterceptor(
        requestBody: false,
        responseBody: false,
        logPrint: (o) => debugPrint('[dio] $o'),
      ));
    }

    return ApiClient._(dio);
  }

  Dio get raw => _dio;

  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, dynamic>? query,
    CancelToken? cancelToken,
  }) async {
    Response<dynamic> res;
    try {
      res = await _dio.get(path,
          queryParameters: query, cancelToken: cancelToken);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
    return _unwrap(res);
  }

  Future<Map<String, dynamic>> postJson(
    String path, {
    Object? body,
    Map<String, dynamic>? query,
    CancelToken? cancelToken,
  }) async {
    Response<dynamic> res;
    try {
      res = await _dio.post(path,
          data: body, queryParameters: query, cancelToken: cancelToken);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
    return _unwrap(res);
  }

  Map<String, dynamic> _unwrap(Response<dynamic> res) {
    final status = res.statusCode ?? 0;
    final data = res.data;

    if (data is String && data.contains('ERR_NGROK_')) {
      throw NgrokInterstitialException(statusCode: status, body: data);
    }

    if (data is Map && data['code'] is String && data['message'] is String) {
      final statusFromBody =
          (data['data'] is Map) ? data['data']['status'] : null;
      throw WordPressApiException(
        data['code'] as String,
        data['message'] as String,
        statusCode: statusFromBody is int ? statusFromBody : status,
        body: data.toString(),
      );
    }

    if (data is Map<String, dynamic>) {
      if (status >= 200 && status < 300) return data;
      throw NetworkException('HTTP $status',
          statusCode: status, body: data.toString());
    }

    throw MalformedResponseException(
      'Expected a JSON object, got ${data.runtimeType}.',
      statusCode: status,
      body: data?.toString(),
    );
  }

  ApiException _mapDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.transformTimeout:
        return const NetworkException(
            'The request timed out. Please try again.');
      case DioExceptionType.connectionError:
        return const NetworkException(
          'Could not reach the server. If you are using ngrok, '
          'the tunnel may have expired.',
        );
      case DioExceptionType.badCertificate:
        return const NetworkException('TLS certificate error.');
      case DioExceptionType.cancel:
        return const NetworkException('Request cancelled.');
      case DioExceptionType.badResponse:
      case DioExceptionType.unknown:
        final body = e.response?.data;
        if (body is String && body.contains('ERR_NGROK_')) {
          return NgrokInterstitialException(
            statusCode: e.response?.statusCode,
            body: body,
          );
        }
        return NetworkException(
          e.message ?? 'Network error',
          statusCode: e.response?.statusCode,
          body: body?.toString(),
        );
      default:
        return NetworkException(
          e.message ?? 'Network error',
          statusCode: e.response?.statusCode,
          body: e.response?.data?.toString(),
        );
    }
  }
}
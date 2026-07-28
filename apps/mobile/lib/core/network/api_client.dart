import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import '../constants/env.dart';
import '../errors/app_exception.dart';
import 'token_storage.dart';
import 'auth_session_events.dart';
import '../security/security_config.dart';

class ApiClient {
  ApiClient._() {
    _dio = Dio(
      BaseOptions(
        baseUrl: Env.apiBaseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(_AuthInterceptor());
    _dio.interceptors.add(_LoggingInterceptor());
    _dio.interceptors.add(_RefreshInterceptor(_dio));
    SecurityConfig.applyCertificatePinning(_dio);
  }

  static final ApiClient instance = ApiClient._();

  late final Dio _dio;

  Dio get dio => _dio;

  // GET
  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? queryParams,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final response = await _dio.get(path, queryParameters: queryParams);
      return _parseResponse<T>(response, fromJson);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // POST
  Future<T> post<T>(
    String path, {
    dynamic data,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final response = await _dio.post(path, data: data);
      return _parseResponse<T>(response, fromJson);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // PATCH
  Future<T> patch<T>(
    String path, {
    dynamic data,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final response = await _dio.patch(path, data: data);
      return _parseResponse<T>(response, fromJson);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // DELETE
  Future<void> delete(String path) async {
    try {
      await _dio.delete(path);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  T _parseResponse<T>(Response response, T Function(dynamic)? fromJson) {
    final data = response.data;
    if (fromJson != null) return fromJson(data);
    return data as T;
  }

  AppException _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return const NetworkException(
          'Connection timed out. Check your internet.',
        );
      case DioExceptionType.connectionError:
        return const NetworkException('No connection. Check your internet.');
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final message = _extractErrorMessage(e.response?.data);
        if (statusCode == 401) return UnauthorizedException(message);
        if (statusCode == 422 || statusCode == 400) {
          return ValidationException(message);
        }
        return NetworkException(message, statusCode: statusCode);
      default:
        return const ServerException();
    }
  }

  String _extractErrorMessage(dynamic data) {
    if (data == null) return 'Something went wrong.';
    if (data is Map) {
      // NestJS standard error format
      final message = data['message'];
      if (message is String) return message;
      if (message is List && message.isNotEmpty) {
        return message.first.toString();
      }
      return data['error']?.toString() ?? 'Something went wrong.';
    }
    return 'Something went wrong.';
  }
}

// Interceptor: attach Bearer token to every request
class _AuthInterceptor extends Interceptor {
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await TokenStorage.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}

// Interceptor: log requests and responses in debug
class _LoggingInterceptor extends Interceptor {
  final _logger = Logger();

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _logger.d('[API] ${options.method} ${options.uri}');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _logger.d('[API] ${response.statusCode} ${response.requestOptions.path}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _logger.e(
'[API] Error ${err.response?.statusCode} ${err.requestOptions.uri}'    );
    handler.next(err);
  }
}

// Interceptor: on a 401, refresh the Supabase session via POST /auth/refresh
// (through NestJS), then retry the original request once. If refresh fails,
// clear tokens and signal the auth layer to route back to login.
class _RefreshInterceptor extends Interceptor {
  _RefreshInterceptor(this._dio);

  final Dio _dio;

  // Public auth endpoints whose 401 means "bad credentials", NOT "expired
  // session" — they must never trigger a refresh attempt.
 static const _noRefreshPaths = [
  'auth/login',
  'auth/register',
  'auth/refresh',
  'auth/forgot-password',
];

  // Single-flight guard so concurrent 401s trigger only one refresh call.
  Future<bool>? _inFlightRefresh;

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;
    final isAuthEndpoint = _noRefreshPaths.any(options.path.contains);
    final alreadyRetried = options.extra['retried'] == true;

    if (err.response?.statusCode != 401 || isAuthEndpoint || alreadyRetried) {
      return handler.next(err);
    }

    final refreshed = await (_inFlightRefresh ??= _refreshTokens());
    _inFlightRefresh = null;

    if (!refreshed) {
      await TokenStorage.clearTokens();
      AuthSessionEvents.instance.notifySignedOut();
      return handler.next(err);
    }

    try {
      final token = await TokenStorage.getAccessToken();
      options.headers['Authorization'] = 'Bearer $token';
      options.extra['retried'] = true;
      final response = await _dio.fetch(options);
      return handler.resolve(response);
    } on DioException catch (retryError) {
      return handler.next(retryError);
    }
  }

  Future<bool> _refreshTokens() async {
    final refreshToken = await TokenStorage.getRefreshToken();
    if (refreshToken == null) return false;

    try {
      // Bare client: no auth/refresh interceptors, so this can't recurse.
      final bareDio = Dio(
        BaseOptions(
          baseUrl: Env.apiBaseUrl,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );
      final response = await bareDio.post(
  'auth/refresh',
        data: {'refresh_token': refreshToken},
      );
      final data = (response.data as Map)['data'] as Map<String, dynamic>;
      final newAccess = data['access_token'] as String?;
      if (newAccess == null) return false;
      await TokenStorage.saveTokens(
        accessToken: newAccess,
        refreshToken: data['refresh_token'] as String?,
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}

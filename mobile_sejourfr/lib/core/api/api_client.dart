import 'dart:async';
import 'package:dio/dio.dart';

import '../auth/token_storage.dart';
import '../models/auth_models.dart';
import 'api_config.dart';
import 'api_exception.dart';

/// Construit le client Dio avec :
///  - en-tête Authorization auto si access token présent
///  - refresh automatique sur 401 + rejeu de la requête
///  - mapping des erreurs vers [ApiException]
class ApiClient {
  ApiClient({required TokenStorage tokenStorage}) : _tokenStorage = tokenStorage {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: ApiConfig.connectTimeout,
      receiveTimeout: ApiConfig.receiveTimeout,
      headers: {'Accept': 'application/json'},
      validateStatus: (status) => status != null && status < 500,
    ));

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: _onRequest,
        onResponse: _onResponse,
        onError: _onError,
      ),
    );
  }

  late final Dio _dio;
  final TokenStorage _tokenStorage;

  /// Callback déclenché si le refresh échoue → déconnexion globale.
  void Function()? onUnauthorized;

  Dio get dio => _dio;

  // ---------------------------------------------------------------------------
  // Interceptors
  // ---------------------------------------------------------------------------

  Future<void> _onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.extra['skipAuth'] != true) {
      final token = await _tokenStorage.readAccess();
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }

  void _onResponse(Response response, ResponseInterceptorHandler handler) {
    final status = response.statusCode ?? 0;
    if (status >= 400) {
      handler.reject(_toDioException(response));
      return;
    }
    handler.next(response);
  }

  Future<void> _onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final status = err.response?.statusCode ?? 0;

    if (status == 401 &&
        err.requestOptions.extra['retry'] != true &&
        err.requestOptions.extra['skipRefresh'] != true) {
      final refreshed = await _tryRefresh();
      if (refreshed) {
        try {
          final newAccess = await _tokenStorage.readAccess();
          final retried = await _dio.fetch(
            err.requestOptions
              ..headers['Authorization'] = 'Bearer $newAccess'
              ..extra['retry'] = true,
          );
          handler.resolve(retried);
          return;
        } on DioException catch (e) {
          handler.reject(e);
          return;
        }
      } else {
        await _tokenStorage.clear();
        onUnauthorized?.call();
      }
    }

    handler.next(err);
  }

  // ---------------------------------------------------------------------------
  // Refresh token (avec mutex pour éviter les appels parallèles)
  // ---------------------------------------------------------------------------

  Future<bool>? _refreshing;

  Future<bool> _tryRefresh() {
    _refreshing ??= _doRefresh().whenComplete(() {
      Timer(const Duration(milliseconds: 50), () => _refreshing = null);
    });
    return _refreshing!;
  }

  Future<bool> _doRefresh() async {
    final refresh = await _tokenStorage.readRefresh();
    if (refresh == null) return false;
    try {
      final res = await Dio(BaseOptions(baseUrl: ApiConfig.baseUrl)).post(
        '/api/auth/refresh',
        data: {'refreshToken': refresh},
      );
      if (res.statusCode != 200) return false;
      final data = res.data as Map<String, dynamic>;
      await _tokenStorage.save(
        accessToken: data['accessToken'] as String,
        refreshToken: data['refreshToken'] as String,
        user: AuthUser.fromJson(data['user'] as Map<String, dynamic>),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Mapping erreurs
  // ---------------------------------------------------------------------------

  DioException _toDioException(Response response) {
    final status = response.statusCode ?? 0;
    String message = 'Erreur HTTP $status';
    Map<String, String>? fieldErrors;

    final data = response.data;
    if (data is Map<String, dynamic>) {
      message = (data['message'] as String?) ?? message;
      final raw = data['fieldErrors'];
      if (raw is List) {
        fieldErrors = {
          for (final e in raw)
            if (e is Map<String, dynamic>)
              (e['field'] as String): (e['message'] as String),
        };
      }
    }

    return DioException(
      requestOptions: response.requestOptions,
      response: response,
      error: ApiException(
        statusCode: status,
        message: message,
        fieldErrors: fieldErrors,
      ),
      type: DioExceptionType.badResponse,
    );
  }

  /// Convertit n'importe quelle erreur Dio en ApiException prête à présenter dans l'UI.
  static ApiException toApiException(Object error) {
    if (error is ApiException) return error;
    if (error is DioException) {
      if (error.error is ApiException) return error.error as ApiException;
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.connectionError) {
        return ApiException(
          statusCode: 0,
          message: 'Connexion au serveur impossible. Vérifiez votre réseau.',
        );
      }
      return ApiException(
        statusCode: error.response?.statusCode ?? 0,
        message: error.message ?? 'Erreur réseau',
      );
    }
    return ApiException(statusCode: -1, message: error.toString());
  }
}

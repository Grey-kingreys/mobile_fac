import 'dart:async';

import 'package:dio/dio.dart';
import 'package:djoulagest_mobile/core/network/api_endpoints.dart';
import 'package:djoulagest_mobile/core/storage/secure_storage.dart';

class AuthInterceptor extends Interceptor {
  final SecureStorageService _storage;
  final Future<void> Function()? onLogout;

  // Protège contre les refreshes parallèles : un seul Completer actif à la fois.
  Completer<bool>? _refreshCompleter;

  AuthInterceptor(this._storage, {this.onLogout});

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storage.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) {
      // Si un refresh est déjà en cours, attendre son résultat.
      if (_refreshCompleter != null) {
        final refreshed = await _refreshCompleter!.future;
        if (refreshed) {
          final newToken = await _storage.getAccessToken();
          final opts = err.requestOptions;
          opts.headers['Authorization'] = 'Bearer $newToken';
          final retryDio = Dio(BaseOptions(baseUrl: ApiEndpoints.baseUrl));
          final response = await retryDio.fetch(opts);
          return handler.resolve(response);
        }
        return handler.next(err);
      }

      _refreshCompleter = Completer<bool>();
      try {
        final refreshed = await _tryRefreshToken();
        _refreshCompleter!.complete(refreshed);

        if (refreshed) {
          final newToken = await _storage.getAccessToken();
          final opts = err.requestOptions;
          opts.headers['Authorization'] = 'Bearer $newToken';
          final retryDio = Dio(BaseOptions(baseUrl: ApiEndpoints.baseUrl));
          final response = await retryDio.fetch(opts);
          _refreshCompleter = null;
          return handler.resolve(response);
        }
      } catch (_) {
        _refreshCompleter?.complete(false);
      }
      _refreshCompleter = null;
      await onLogout?.call();
      await _storage.clearTokens();
    }
    handler.next(err);
  }

  Future<bool> _tryRefreshToken() async {
    final refreshToken = await _storage.getRefreshToken();
    if (refreshToken == null) return false;
    try {
      final dio = Dio(BaseOptions(baseUrl: ApiEndpoints.baseUrl));
      final response = await dio.post(
        ApiEndpoints.refreshToken,
        data: {'refresh': refreshToken},
      );
      final data = response.data as Map<String, dynamic>;
      await _storage.saveAccessToken(data['access'] as String);
      if (data['refresh'] != null) {
        await _storage.saveRefreshToken(data['refresh'] as String);
      }
      return true;
    } catch (_) {
      return false;
    }
  }
}

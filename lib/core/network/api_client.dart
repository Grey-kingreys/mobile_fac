import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:djoulagest_mobile/core/network/api_endpoints.dart';
import 'package:djoulagest_mobile/core/network/interceptors/auth_interceptor.dart';
import 'package:djoulagest_mobile/core/network/interceptors/error_interceptor.dart';
import 'package:djoulagest_mobile/core/storage/secure_storage.dart';

// Réponse wrappée {success, data, message} — utilisée par accounts/companies
class ApiResponse<T> {
  final bool success;
  final T? data;
  final String message;

  const ApiResponse({required this.success, this.data, required this.message});

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic) fromData,
  ) {
    return ApiResponse(
      success: json['success'] as bool? ?? true,
      data: json['data'] != null ? fromData(json['data']) : null,
      message: json['message'] as String? ?? '',
    );
  }
}

// Réponse paginée DRF — utilisée par la plupart des endpoints
class PaginatedResponse<T> {
  final int count;
  final String? next;
  final String? previous;
  final List<T> results;

  const PaginatedResponse({
    required this.count,
    this.next,
    this.previous,
    required this.results,
  });

  bool get hasNext => next != null;
  bool get hasPrevious => previous != null;

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromItem,
  ) {
    return PaginatedResponse(
      count: json['count'] as int? ?? 0,
      next: json['next'] as String?,
      previous: json['previous'] as String?,
      results: (json['results'] as List<dynamic>? ?? [])
          .map((e) => fromItem(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ApiClient {
  late final Dio _dio;

  ApiClient(SecureStorageService storage, {Future<void> Function()? onLogout}) {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.addAll([
      AuthInterceptor(storage, onLogout: onLogout),
      ErrorInterceptor(),
      if (kDebugMode)
        PrettyDioLogger(
          requestHeader: false,
          requestBody: true,
          responseBody: true,
          error: true,
          compact: true,
        ),
    ]);
  }

  Dio get dio => _dio;

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.get<T>(path, queryParameters: queryParameters, options: options);
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.post<T>(path, data: data, queryParameters: queryParameters, options: options);
  }

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.put<T>(path, data: data, queryParameters: queryParameters, options: options);
  }

  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.patch<T>(path, data: data, queryParameters: queryParameters, options: options);
  }

  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.delete<T>(path, data: data, queryParameters: queryParameters, options: options);
  }
}

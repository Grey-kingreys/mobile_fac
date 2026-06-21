import 'package:dio/dio.dart';
import 'package:djoulagest_mobile/core/errors/app_exception.dart';

class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final exception = _parseError(err);
    handler.next(
      err.copyWith(
        error: exception,
        message: exception.message,
      ),
    );
  }

  AppException _parseError(DioException err) {
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const TimeoutException();

      case DioExceptionType.connectionError:
        return const NetworkException();

      case DioExceptionType.badResponse:
        return _parseResponseError(err.response);

      default:
        return AppException(err.message ?? 'Erreur inconnue.');
    }
  }

  AppException _parseResponseError(Response? response) {
    if (response == null) return const NetworkException();
    final statusCode = response.statusCode ?? 0;
    final data = response.data;

    // Extraire le message d'erreur du backend
    String message = _extractMessage(data, statusCode);
    final hasBackendMessage = !message.startsWith('Erreur ');

    switch (statusCode) {
      case 400:
        final fieldErrors = _extractFieldErrors(data);
        return ValidationException(message, fieldErrors: fieldErrors);
      case 401:
        return hasBackendMessage
            ? UnauthorizedException(message)
            : const UnauthorizedException();
      case 403:
        return hasBackendMessage
            ? ForbiddenException(message)
            : const ForbiddenException();
      case 404:
        return const NotFoundException();
      case >= 500:
        return ServerException(message, statusCode);
      default:
        return AppException(message, statusCode: statusCode);
    }
  }

  String _extractMessage(dynamic data, int statusCode) {
    if (data is Map<String, dynamic>) {
      if (data.containsKey('message')) return data['message'] as String;
      if (data.containsKey('detail')) return data['detail'] as String;
      if (data.containsKey('non_field_errors')) {
        final errors = data['non_field_errors'];
        if (errors is List && errors.isNotEmpty) return errors.first.toString();
      }
    }
    return 'Erreur $statusCode.';
  }

  Map<String, List<String>> _extractFieldErrors(dynamic data) {
    final result = <String, List<String>>{};
    if (data is! Map<String, dynamic>) return result;
    data.forEach((key, value) {
      if (key == 'message' || key == 'detail') return;
      if (value is List) {
        result[key] = value.map((e) => e.toString()).toList();
      } else if (value is String) {
        result[key] = [value];
      }
    });
    return result;
  }
}

class AppException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  const AppException(this.message, {this.statusCode, this.data});

  @override
  String toString() => 'AppException($statusCode): $message';
}

class NetworkException extends AppException {
  const NetworkException([super.message = 'Erreur réseau.']);
}

class UnauthorizedException extends AppException {
  const UnauthorizedException([super.message = 'Non autorisé.']) : super(statusCode: 401);
}

class ForbiddenException extends AppException {
  const ForbiddenException([super.message = 'Accès refusé.']) : super(statusCode: 403);
}

class NotFoundException extends AppException {
  const NotFoundException([super.message = 'Introuvable.']) : super(statusCode: 404);
}

class ValidationException extends AppException {
  final Map<String, List<String>> fieldErrors;

  const ValidationException(super.message, {required this.fieldErrors}) : super(statusCode: 400);

  String get firstError {
    if (fieldErrors.isEmpty) return message;
    final first = fieldErrors.entries.first;
    return '${first.key}: ${first.value.first}';
  }
}

class ServerException extends AppException {
  const ServerException([super.message = 'Erreur serveur.', int statusCode = 500])
      : super(statusCode: statusCode);
}

class TimeoutException extends AppException {
  const TimeoutException([super.message = 'Délai d\'attente dépassé.']);
}

class CacheException extends AppException {
  const CacheException([super.message = 'Erreur de stockage.']);
}

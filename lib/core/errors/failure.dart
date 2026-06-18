import 'package:equatable/equatable.dart';

sealed class Failure extends Equatable {
  final String message;
  const Failure(this.message);

  @override
  List<Object?> get props => [message];
}

final class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Erreur réseau.']);
}

final class ServerFailure extends Failure {
  final int? statusCode;
  const ServerFailure(super.message, {this.statusCode});

  @override
  List<Object?> get props => [message, statusCode];
}

final class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure([super.message = 'Session expirée.']);
}

final class ForbiddenFailure extends Failure {
  const ForbiddenFailure([super.message = 'Accès refusé.']);
}

final class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'Ressource introuvable.']);
}

final class ValidationFailure extends Failure {
  final Map<String, List<String>>? fieldErrors;
  const ValidationFailure(super.message, {this.fieldErrors});

  @override
  List<Object?> get props => [message, fieldErrors];
}

final class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Erreur de stockage local.']);
}

final class TimeoutFailure extends Failure {
  const TimeoutFailure([super.message = 'Délai d\'attente dépassé.']);
}

final class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'Erreur inconnue.']);
}

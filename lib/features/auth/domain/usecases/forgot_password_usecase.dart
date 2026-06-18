import 'package:djoulagest_mobile/features/auth/domain/repositories/auth_repository.dart';

class ForgotPasswordUseCase {
  final AuthRepository _repository;
  const ForgotPasswordUseCase(this._repository);

  Future<void> call(String email) => _repository.forgotPassword(email);
}

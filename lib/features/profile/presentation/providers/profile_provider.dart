import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:djoulagest_mobile/core/di/providers.dart';
import 'package:djoulagest_mobile/core/network/api_endpoints.dart';

class ProfileNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  /// Retourne null si succès, sinon le message d'erreur.
  Future<String?> changePassword({
    required String currentPassword,
    required String newPassword,
    required String newPasswordConfirm,
  }) async {
    try {
      await ref.read(apiClientProvider).post<void>(
        ApiEndpoints.changePassword,
        data: {
          'current_password': currentPassword,
          'new_password': newPassword,
          'new_password_confirm': newPasswordConfirm,
        },
      );
      return null;
    } catch (e) {
      final msg = e.toString();
      if (msg.startsWith('Exception: ')) return msg.substring(11);
      return msg;
    }
  }
}

final profileProvider =
    AsyncNotifierProvider<ProfileNotifier, void>(ProfileNotifier.new);

abstract class AppValidators {
  static String? required(String? value, [String? fieldName]) {
    if (value == null || value.trim().isEmpty) {
      return fieldName != null ? '$fieldName est obligatoire.' : 'Ce champ est obligatoire.';
    }
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email obligatoire.';
    final regex = RegExp(r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$');
    if (!regex.hasMatch(value.trim())) return 'Email invalide.';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Mot de passe obligatoire.';
    if (value.length < 8) return 'Minimum 8 caractères.';
    return null;
  }

  static String? confirmPassword(String? value, String? original) {
    if (value == null || value.isEmpty) return 'Confirmez le mot de passe.';
    if (value != original) return 'Les mots de passe ne correspondent pas.';
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) return null; // optionnel
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 9) return 'Numéro trop court.';
    return null;
  }

  static String? positiveNumber(String? value, [String? fieldName]) {
    if (value == null || value.trim().isEmpty) {
      return fieldName != null ? '$fieldName obligatoire.' : 'Valeur obligatoire.';
    }
    final num = double.tryParse(value.replaceAll(',', '.'));
    if (num == null) return 'Valeur numérique invalide.';
    if (num <= 0) return 'La valeur doit être positive.';
    return null;
  }

  static String? nonNegativeNumber(String? value) {
    if (value == null || value.trim().isEmpty) return 'Valeur obligatoire.';
    final num = double.tryParse(value.replaceAll(',', '.'));
    if (num == null) return 'Valeur numérique invalide.';
    if (num < 0) return 'La valeur ne peut pas être négative.';
    return null;
  }

  static String? minLength(String? value, int min) {
    if (value == null || value.length < min) return 'Minimum $min caractères.';
    return null;
  }

  static String? maxLength(String? value, int max) {
    if (value != null && value.length > max) return 'Maximum $max caractères.';
    return null;
  }

  // Combine plusieurs validateurs
  static String? compose(String? value, List<String? Function(String?)> validators) {
    for (final v in validators) {
      final error = v(value);
      if (error != null) return error;
    }
    return null;
  }
}

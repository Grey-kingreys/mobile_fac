import 'package:intl/intl.dart';

abstract class AppFormatters {
  // Monnaie GNF (Franc Guinéen) — format : 1 250 000 GNF
  static String gnf(num amount) {
    final formatted = NumberFormat('#,##0', 'fr_FR').format(amount);
    return '$formatted GNF';
  }

  // Monnaie avec devise personnalisée
  static String currency(num amount, String currency) {
    final formatted = NumberFormat('#,##0', 'fr_FR').format(amount);
    return '$formatted $currency';
  }

  // Nombre sans devise
  static String number(num value, {int decimals = 0}) {
    return NumberFormat('#,##0${decimals > 0 ? '.${'0' * decimals}' : ''}', 'fr_FR').format(value);
  }

  // Pourcentage
  static String percent(num value, {int decimals = 1}) {
    return '${value.toStringAsFixed(decimals)} %';
  }

  // Date française : 12 juin 2026
  static String dateLong(DateTime date) {
    return DateFormat('d MMMM yyyy', 'fr_FR').format(date);
  }

  // Date courte : 12/06/2026
  static String dateShort(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  // Date + heure : 12/06/2026 à 14:30
  static String dateTime(DateTime date) {
    return DateFormat('dd/MM/yyyy \'à\' HH:mm').format(date);
  }

  // Heure seule : 14:30
  static String time(DateTime date) {
    return DateFormat('HH:mm').format(date);
  }

  // Heure relative : il y a 5 min, hier, etc.
  static String timeAgo(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inSeconds < 60) return 'à l\'instant';
    if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'il y a ${diff.inHours} h';
    if (diff.inDays == 1) return 'hier';
    if (diff.inDays < 7) return 'il y a ${diff.inDays} jours';
    return dateShort(date);
  }

  // Numéro de téléphone guinéen : +224 621 00 00 00
  static String phone(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 9) {
      return '+224 ${digits.substring(0, 3)} ${digits.substring(3, 5)} ${digits.substring(5, 7)} ${digits.substring(7)}';
    }
    if (digits.startsWith('224') && digits.length == 12) {
      return '+${digits.substring(0, 3)} ${digits.substring(3, 6)} ${digits.substring(6, 8)} ${digits.substring(8, 10)} ${digits.substring(10)}';
    }
    return phone;
  }

  // Taille de fichier
  static String fileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

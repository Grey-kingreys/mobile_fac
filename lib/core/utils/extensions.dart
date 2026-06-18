import 'package:flutter/material.dart';
import 'package:djoulagest_mobile/core/utils/formatters.dart';

extension StringExtensions on String {
  String get capitalize => isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
  String get titleCase => split(' ').map((w) => w.capitalize).join(' ');
  bool get isValidEmail {
    return RegExp(r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$').hasMatch(this);
  }
  bool get isBlank => trim().isEmpty;
  bool get isNotBlank => trim().isNotEmpty;
  String truncate(int maxLength, {String ellipsis = '…'}) {
    return length > maxLength ? '${substring(0, maxLength)}$ellipsis' : this;
  }
}

extension NullableStringExtensions on String? {
  bool get isNullOrBlank => this == null || this!.trim().isEmpty;
  String get orEmpty => this ?? '';
  String orDefault(String defaultValue) => (this == null || this!.isEmpty) ? defaultValue : this!;
}

extension NumExtensions on num {
  String toGnf() => AppFormatters.gnf(this);
  String toCurrency(String currency) => AppFormatters.currency(this, currency);
  String toPercent({int decimals = 1}) => AppFormatters.percent(this, decimals: decimals);
  bool get isPositive => this > 0;
  bool get isNegative => this < 0;
  bool get isZero => this == 0;
}

extension DateTimeExtensions on DateTime {
  String toDateLong() => AppFormatters.dateLong(this);
  String toDateShort() => AppFormatters.dateShort(this);
  String toDateTime() => AppFormatters.dateTime(this);
  String toTime() => AppFormatters.time(this);
  String toTimeAgo() => AppFormatters.timeAgo(this);

  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year && month == yesterday.month && day == yesterday.day;
  }

  bool isSameDay(DateTime other) =>
      year == other.year && month == other.month && day == other.day;
}

extension ContextExtensions on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  TextTheme get textTheme => Theme.of(this).textTheme;
  MediaQueryData get mediaQuery => MediaQuery.of(this);
  double get screenWidth => mediaQuery.size.width;
  double get screenHeight => mediaQuery.size.height;
  bool get isDarkMode => theme.brightness == Brightness.dark;

  void showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? colorScheme.error : colorScheme.secondary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

extension ListExtensions<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
  T? get lastOrNull => isEmpty ? null : last;
  List<T> get nonNull => whereType<T>().toList();
}

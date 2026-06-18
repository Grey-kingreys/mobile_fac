import 'package:flutter/material.dart';

enum AlertLevel { info, warning, danger }

class KpiEntity {
  const KpiEntity({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
    this.trendPercent,
    this.trendLabel,
    this.higherIsBetter = true,
    this.route,
  });

  final String title;
  final String value;
  final String? subtitle;
  final double? trendPercent;
  final String? trendLabel;
  final bool higherIsBetter;
  final IconData icon;
  final Color color;
  final String? route;
}

class AlertEntity {
  const AlertEntity({
    required this.message,
    required this.level,
    required this.icon,
    this.route,
  });

  final String message;
  final AlertLevel level;
  final IconData icon;
  final String? route;
}

class DashboardDataEntity {
  const DashboardDataEntity({
    this.kpis = const [],
    this.alerts = const [],
  });

  final List<KpiEntity> kpis;
  final List<AlertEntity> alerts;
}

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:djoulagest_mobile/core/constants/app_colors.dart';
import 'package:djoulagest_mobile/core/utils/formatters.dart';
import 'package:djoulagest_mobile/shared/widgets/chart_card.dart';

// ============================================================
// DASHBOARD CHARTS — graphiques fl_chart du tableau de bord
//
// ⚠️ Données codées en dur pour l'instant (cf. demande).
// À brancher plus tard sur les endpoints /analytics/*.
// Palette alignée sur AppColors (identique au front ngx-charts).
// ============================================================

/// Palette commune (même ordre que le front Angular).
const List<Color> kChartPalette = [
  AppColors.primary, // bleu
  AppColors.secondary, // vert
  AppColors.accent, // ambre
  AppColors.danger, // rouge
  AppColors.purple, // violet
  AppColors.cyan, // cyan
];

/// Point de donnée générique (libellé + valeur).
class ChartDatum {
  const ChartDatum(this.label, this.value);
  final String label;
  final double value;
}

// ─── Courbe : évolution du CA (7 derniers jours) ───────────────────────────────

class RevenueLineChart extends StatelessWidget {
  const RevenueLineChart({super.key, required this.data});

  /// 7 points (lun → dim), valeurs en milliers de GNF.
  final List<ChartDatum> data;

  @override
  Widget build(BuildContext context) {
    final maxY = data.map((d) => d.value).reduce((a, b) => a > b ? a : b);
    final step = (maxY / 3).ceilToDouble().clamp(1.0, double.infinity).toDouble();

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: maxY * 1.2,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: step,
          getDrawingHorizontalLine: (_) =>
              const FlLine(color: AppColors.gray100, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= data.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    data[i].label,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.gray400,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => AppColors.gray900,
            getTooltipItems: (spots) => spots
                .map((s) => LineTooltipItem(
                      AppFormatters.gnf(s.y * 1000),
                      const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ))
                .toList(),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: [
              for (var i = 0; i < data.length; i++)
                FlSpot(i.toDouble(), data[i].value),
            ],
            isCurved: true,
            curveSmoothness: 0.3,
            color: AppColors.primary,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.primary.withValues(alpha: 0.22),
                  AppColors.primary.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Barres : valeurs par catégorie (top produits, ventes par dépôt…) ──────────

class CategoryBarChart extends StatelessWidget {
  const CategoryBarChart({
    super.key,
    required this.data,
    this.color = AppColors.primary,
  });

  final List<ChartDatum> data;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final maxY = data.map((d) => d.value).reduce((a, b) => a > b ? a : b);

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY * 1.2,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= data.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    data[i].label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.gray400,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => AppColors.gray900,
            getTooltipItem: (group, _, rod, __) => BarTooltipItem(
              rod.toY.toInt().toString(),
              const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ),
        ),
        barGroups: [
          for (var i = 0; i < data.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: data[i].value,
                  width: 18,
                  color: color,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(6),
                  ),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: maxY * 1.2,
                    color: AppColors.gray100,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

// ─── Donut : répartition (modes de paiement, statuts…) ─────────────────────────

class DonutChart extends StatelessWidget {
  const DonutChart({super.key, required this.data, this.showPercent = true});

  final List<ChartDatum> data;
  final bool showPercent;

  @override
  Widget build(BuildContext context) {
    final total = data.fold<double>(0, (s, d) => s + d.value);

    return PieChart(
      PieChartData(
        sectionsSpace: 2,
        centerSpaceRadius: 38,
        startDegreeOffset: -90,
        sections: [
          for (var i = 0; i < data.length; i++)
            PieChartSectionData(
              value: data[i].value,
              color: kChartPalette[i % kChartPalette.length],
              radius: 46,
              title: showPercent && total > 0
                  ? '${(data[i].value / total * 100).round()}%'
                  : '',
              titleStyle: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
        ],
      ),
    );
  }
}

/// Construit la légende (pastilles couleur) pour un donut.
List<ChartLegendItem> legendFor(List<ChartDatum> data, {bool percent = true}) {
  final total = data.fold<double>(0, (s, d) => s + d.value);
  return [
    for (var i = 0; i < data.length; i++)
      ChartLegendItem(
        data[i].label,
        kChartPalette[i % kChartPalette.length],
        value: percent && total > 0
            ? '${(data[i].value / total * 100).round()}%'
            : data[i].value.toInt().toString(),
      ),
  ];
}

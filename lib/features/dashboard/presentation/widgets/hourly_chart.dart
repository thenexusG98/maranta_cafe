import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/daily_stats.dart';

/// Gráfico de barras de ventas por hora del día
class HourlyChart extends StatelessWidget {
  final List<HourlySales> hourlySales;

  const HourlyChart({super.key, required this.hourlySales});

  @override
  Widget build(BuildContext context) {
    if (hourlySales.isEmpty) return const SizedBox.shrink();

    final maxAmount = hourlySales
      .map((h) => h.amount)
      .fold(0.0, (a, b) => a > b ? a : b);

    final peakHour = maxAmount > 0
      ? hourlySales.reduce((a, b) => a.amount > b.amount ? a : b)
      : null;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.coffeeBrown.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (peakHour != null && peakHour.amount > 0) ...[
            Row(
              children: [
                const Icon(Icons.local_fire_department,
                  color: AppColors.caramel, size: 18),
                const SizedBox(width: 6),
                Text(
                  'Hora pico: ${peakHour.label} — \$${peakHour.amount.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.caramel,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],

          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxAmount > 0 ? maxAmount * 1.3 : 100,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    tooltipBgColor: AppColors.coffeeDark.withOpacity(0.85),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final h = hourlySales[group.x.toInt()];
                      return BarTooltipItem(
                        '${h.label}\n\$${h.amount.toStringAsFixed(0)}',
                        const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        if (i < 0 || i >= hourlySales.length) {
                          return const SizedBox.shrink();
                        }
                        final h = hourlySales[i].hour;
                        // Solo mostrar cada 2 horas
                        if (h % 2 != 0) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '${h}h',
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 44,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return const SizedBox.shrink();
                        return Text(
                          '\$${value.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: AppColors.creamDark,
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(hourlySales.length, (i) {
                  final h = hourlySales[i];
                  final isPeak = peakHour != null && h.hour == peakHour.hour;

                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: h.amount,
                        color: isPeak ? AppColors.caramel : AppColors.coffeeBrown.withOpacity(0.6),
                        width: 12,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(6)),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: maxAmount > 0 ? maxAmount * 1.3 : 100,
                          color: AppColors.creamDark,
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

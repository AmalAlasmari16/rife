import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Bar chart of new nursery signups per month for the last 6 months.
class SignupsChart extends StatelessWidget {
  const SignupsChart({super.key, required this.byMonth});

  /// Map of `YYYY-MM` → count.
  final Map<String, int> byMonth;

  List<({String month, int count})> _last6Months() {
    final now = DateTime.now();
    final out = <({String month, int count})>[];
    for (var i = 5; i >= 0; i--) {
      final m = DateTime(now.year, now.month - i, 1);
      final key =
          '${m.year.toString().padLeft(4, "0")}-${m.month.toString().padLeft(2, "0")}';
      out.add((month: _monthLabel(m.month), count: byMonth[key] ?? 0));
    }
    return out;
  }

  static String _monthLabel(int month) {
    const names = [
      'ينا', 'فبر', 'مار', 'أبر', 'ماي', 'يون',
      'يول', 'أغس', 'سبت', 'أكت', 'نوف', 'ديس',
    ];
    return names[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    final data = _last6Months();
    final maxY = data.map((e) => e.count).fold<int>(0, (a, b) => a > b ? a : b);
    final yMax = (maxY < 4 ? 4 : maxY + 2).toDouble();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'الاشتراكات الجديدة — آخر 6 أشهر',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: yMax,
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, _) {
                        final i = value.toInt();
                        if (i < 0 || i >= data.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            data[i].month,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: [
                  for (var i = 0; i < data.length; i++)
                    BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: data[i].count.toDouble(),
                          color: AppColors.primary,
                          width: 18,
                          borderRadius:
                              const BorderRadius.all(Radius.circular(6)),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/measurement.dart';
import '../utils/constants.dart';

class MeasurementChart extends StatelessWidget {
  final List<Measurement> measurements;
  final String metric; // 'icc' or 'weight'

  const MeasurementChart({
    super.key,
    required this.measurements,
    required this.metric,
  });

  List<Measurement> get _sorted => List.of(measurements)
    ..sort((a, b) => a.date.compareTo(b.date));

  List<FlSpot> get _spots {
    final sorted = _sorted;
    return [
      for (int i = 0; i < sorted.length; i++)
        if (_value(sorted[i]) != null)
          FlSpot(i.toDouble(), _value(sorted[i])!)
    ];
  }

  double? _value(Measurement m) =>
      metric == 'icc' ? m.icc : m.weightKg;

  String get _label => metric == 'icc' ? 'ICC' : 'Peso (kg)';

  Color get _color =>
      metric == 'icc' ? AppColors.primary : AppColors.secondary;

  @override
  Widget build(BuildContext context) {
    final spots = _spots;
    if (spots.isEmpty) {
      return const Center(
        child: Text('Sin datos suficientes para graficar'),
      );
    }

    final sorted = _sorted;
    final minY = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final padding = (maxY - minY) * 0.15 + 0.5;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 180,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                drawVerticalLine: false,
                getDrawingHorizontalLine: (_) => FlLine(
                  color: Colors.grey.withOpacity(0.2),
                  strokeWidth: 1,
                ),
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (val, _) => Text(
                      metric == 'icc'
                          ? val.toStringAsFixed(1)
                          : val.toStringAsFixed(0),
                      style: const TextStyle(
                          fontSize: 10, color: AppColors.textSecondary),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (val, _) {
                      final i = val.toInt();
                      if (i < 0 || i >= sorted.length) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          DateFormat('dd/MM').format(sorted[i].date),
                          style: const TextStyle(
                              fontSize: 9, color: AppColors.textSecondary),
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
              borderData: FlBorderData(show: false),
              minY: (minY - padding).clamp(
                  metric == 'icc' ? 1.0 : 0.0, double.infinity),
              maxY: maxY + padding,
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: _color,
                  barWidth: 2.5,
                  dotData: FlDotData(
                    getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                      radius: 4,
                      color: _color,
                      strokeColor: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    color: _color.withOpacity(0.12),
                  ),
                ),
              ],
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  tooltipBgColor: _color.withOpacity(0.85),
                  getTooltipItems: (spots) => spots
                      .map((s) => LineTooltipItem(
                            metric == 'icc'
                                ? s.y.toStringAsFixed(1)
                                : '${s.y.toStringAsFixed(0)} kg',
                            const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ))
                      .toList(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class HeartRateGraph extends StatelessWidget {
  final List<double> heartRates;

  const HeartRateGraph({super.key, required this.heartRates});

  @override
  Widget build(BuildContext context) {
    return LineChart(
      LineChartData(
        minY: 40,
        maxY: 140,
        lineBarsData: [
          LineChartBarData(
            spots: List.generate(
              heartRates.length,
                  (index) => FlSpot(index.toDouble(), heartRates[index]),
            ),
            isCurved: true,
            color: Colors.white,
            barWidth: 3,
            dotData: FlDotData(show: true),
            belowBarData: BarAreaData(show: false),
          ),
        ],
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: 20,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                );
              },
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          drawHorizontalLine: true,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.white.withAlpha(102),
            strokeWidth: 1,
          ),
          getDrawingVerticalLine: (value) => FlLine(
            color: Colors.white.withAlpha(102),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: const Border(
            left: BorderSide(color: Colors.white),
            bottom: BorderSide(color: Colors.white),
          ),
        ),
      ),
    );
  }
}

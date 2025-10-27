import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:unfold_ai/core/core.dart';
import 'package:unfold_ai/features/features.dart';
import 'package:unfold_ai/utils/data_decimator.dart';

class BiometricChart extends StatelessWidget {
  final List<BiometricData> data;
  final List<JournalEntry> journalEntries;
  final DataRange selectedRange;
  final DateTime? selectedDate;
  final bool isLargeDataset;
  final ChartType chartType;
  final Function(DateTime?) onDateSelected;
  final Function(JournalEntry?)? onJournalTapped;

  const BiometricChart({
    super.key,
    required this.data,
    required this.journalEntries,
    required this.selectedRange,
    required this.selectedDate,
    required this.isLargeDataset,
    required this.chartType,
    required this.onDateSelected,
    this.onJournalTapped,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (data.isEmpty) {
      return _buildEmptyChart(theme);
    }

    final processedData = _processData();
    final spots = _createSpots(processedData);
    final annotations = _createAnnotations(processedData);
    final bandData = _getBandData(processedData);

    return Container(
      height: 280,
      padding: const EdgeInsets.all(16),
      child: InteractiveViewer(
        minScale: 0.8,
        maxScale: 3.0,
        child: LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: _getHorizontalInterval(),
              getDrawingHorizontalLine: (value) {
                return FlLine(
                  color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                  strokeWidth: 1,
                );
              },
            ),
            titlesData: FlTitlesData(
              show: true,
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  interval: _getBottomInterval(),
                  getTitlesWidget: (value, meta) {
                    return _buildBottomTitle(value, meta);
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  interval: _getLeftInterval(),
                  getTitlesWidget: (value, meta) {
                    return _buildLeftTitle(value, meta);
                  },
                ),
              ),
            ),
            borderData: FlBorderData(
              show: true,
              border: Border.all(
                color: isDark ? Colors.grey[700]! : Colors.grey[400]!,
                width: 1,
              ),
            ),
            minX: processedData.isNotEmpty
                ? processedData.first.dateTime.millisecondsSinceEpoch.toDouble()
                : DateTime.now().millisecondsSinceEpoch.toDouble(),
            maxX: processedData.isNotEmpty
                ? processedData.last.dateTime.millisecondsSinceEpoch.toDouble()
                : DateTime.now().millisecondsSinceEpoch.toDouble(),
            minY: _getMinY(processedData),
            maxY: _getMaxY(processedData),
            lineBarsData: [
              // Add band area if HRV chart
              if (bandData.isNotEmpty) ...bandData,
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: _getChartColor(),
                barWidth: 2,
                isStrokeCapRound: true,
                dotData: FlDotData(
                  show: false,
                  getDotPainter: (spot, percent, barData, index) {
                    if (selectedDate != null &&
                        spot.x ==
                            selectedDate!.millisecondsSinceEpoch.toDouble()) {
                      return FlDotCirclePainter(
                        radius: 4,
                        color: _getChartColor(),
                        strokeWidth: 2,
                        strokeColor: theme.colorScheme.surface,
                      );
                    }
                    return FlDotCirclePainter(
                      radius: 2,
                      color: _getChartColor(),
                    );
                  },
                ),
                belowBarData: BarAreaData(
                  show: true,
                  color: _getChartColor().withValues(alpha: 0.1),
                ),
              ),
            ],
            lineTouchData: LineTouchData(
              enabled: true,
              touchTooltipData: LineTouchTooltipData(
                tooltipRoundedRadius: 8,
                tooltipPadding: const EdgeInsets.all(8),
                getTooltipItems: (touchedSpots) {
                  return touchedSpots
                      .where((spot) => spot.spotIndex < processedData.length)
                      .map((touchedSpot) {
                        final index = touchedSpot.spotIndex;
                        final dataPoint = processedData[index];
                        return LineTooltipItem(
                          _getTooltipText(dataPoint),
                          TextStyle(
                            color: isDark ? Colors.white : Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      })
                      .toList();
                },
              ),
              touchCallback: (event, response) {
                if (response?.lineBarSpots?.isNotEmpty == true) {
                  final spot = response!.lineBarSpots!.first;
                  final index = spot.spotIndex;
                  if (index < processedData.length) {
                    final selectedDate = processedData[index].dateTime;
                    onDateSelected(selectedDate);

                    // Check if tapped on a journal entry
                    if (onJournalTapped != null) {
                      final journalEntry = _getJournalEntryForDate(
                        selectedDate,
                      );
                      if (journalEntry != null) {
                        onJournalTapped!(journalEntry);
                      } else {
                        onJournalTapped!(null);
                      }
                    }
                  }
                } else {
                  // Clear selection when tapping empty space
                  onDateSelected(null);
                  onJournalTapped?.call(null);
                }
              },
            ),
            extraLinesData: ExtraLinesData(
              horizontalLines: _getHorizontalLines(processedData, isDark),
              verticalLines: annotations,
            ),
          ),
        ),
      ),
    );
  }

  List<BiometricData> _processData() {
    if (data.isEmpty) {
      return [];
    }

    // Filter by date range
    // For demo purposes, use the last date in the data as "now"
    final lastDate = data
        .map((d) => d.dateTime)
        .reduce((a, b) => a.isAfter(b) ? a : b);
    DateTime startDate;
    switch (selectedRange) {
      case DataRange.sevenDays:
        startDate = lastDate.subtract(const Duration(days: 7));
        break;
      case DataRange.thirtyDays:
        startDate = lastDate.subtract(const Duration(days: 30));
        break;
      case DataRange.ninetyDays:
        startDate = lastDate.subtract(const Duration(days: 90));
        break;
    }

    var filteredData = data
        .where((d) => d.dateTime.isAfter(startDate))
        .toList();

    // Remove any duplicate dates to prevent overlapping labels
    filteredData = filteredData.fold<List<BiometricData>>([], (acc, current) {
      if (acc.isEmpty || acc.last.dateTime != current.dateTime) {
        acc.add(current);
      }
      return acc;
    });

    // Apply decimation for large datasets and extended date ranges
    if (filteredData.isNotEmpty) {
      int targetPoints;
      if (isLargeDataset) {
        // Large dataset mode: more aggressive decimation
        targetPoints = selectedRange == DataRange.sevenDays ? 50 : 100;
      } else if (selectedRange == DataRange.thirtyDays &&
          filteredData.length > 150) {
        // 30d range: target ~100 points for smooth rendering
        targetPoints = 100;
      } else if (selectedRange == DataRange.ninetyDays &&
          filteredData.length > 200) {
        // 90d range: target ~150 points for smooth rendering
        targetPoints = 150;
      } else if (filteredData.length > 150) {
        // Default: decimate if over 150 points
        targetPoints = 100;
      } else {
        // No decimation needed
        targetPoints = filteredData.length;
      }

      if (targetPoints < filteredData.length) {
        filteredData = DataDecimator.decimateData(filteredData, targetPoints);
      }
    }

    return filteredData;
  }

  List<FlSpot> _createSpots(List<BiometricData> processedData) {
    return processedData.map((d) {
      return FlSpot(
        d.dateTime.millisecondsSinceEpoch.toDouble(),
        _getYValue(d),
      );
    }).toList();
  }

  List<VerticalLine> _createAnnotations(List<BiometricData> processedData) {
    final annotations = <VerticalLine>[];

    // Add selected date crosshair (green line without label)
    if (selectedDate != null) {
      annotations.add(
        VerticalLine(
          x: selectedDate!.millisecondsSinceEpoch.toDouble(),
          color: Colors.green,
          strokeWidth: 2,
          dashArray: [5, 5],
          label: VerticalLineLabel(show: false),
        ),
      );
    }

    // Add journal entry annotations
    for (final entry in journalEntries) {
      final entryDate = entry.dateTime;
      if (processedData.any(
        (d) => d.dateTime.difference(entryDate).inDays.abs() <= 1,
      )) {
        annotations.add(
          VerticalLine(
            x: entryDate.millisecondsSinceEpoch.toDouble(),
            color: _getAnnotationColor(entry.mood),
            strokeWidth: 2,
            dashArray: [5, 5],
            label: VerticalLineLabel(show: false),
          ),
        );
      }
    }

    return annotations;
  }

  JournalEntry? _getJournalEntryForDate(DateTime date) {
    for (final entry in journalEntries) {
      if (entry.dateTime.difference(date).inDays.abs() <= 1) {
        return entry;
      }
    }
    return null;
  }

  double _getYValue(BiometricData data) {
    switch (chartType) {
      case ChartType.hrv:
        return data.hrv;
      case ChartType.rhr:
        return data.rhr.toDouble();
      case ChartType.steps:
        return data.steps.toDouble();
    }
  }

  Color _getChartColor() {
    switch (chartType) {
      case ChartType.hrv:
        return Colors.blue;
      case ChartType.rhr:
        return Colors.red;
      case ChartType.steps:
        return Colors.green;
    }
  }

  Color _getAnnotationColor(int mood) {
    switch (mood) {
      case 1:
        return Colors.red;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.yellow;
      case 4:
        return Colors.lightGreen;
      case 5:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  double _getMinY(List<BiometricData> data) {
    if (data.isEmpty) return 0;
    final values = data.map(_getYValue).toList();
    final minValue = values.reduce((a, b) => a < b ? a : b);

    // For steps, ensure clean intervals
    if (chartType == ChartType.steps) {
      return (minValue * 0.85).floor() / 1000 * 1000;
    }

    return minValue * 0.9;
  }

  double _getMaxY(List<BiometricData> data) {
    if (data.isEmpty) return 100;
    final values = data.map(_getYValue).toList();
    final maxValue = values.reduce((a, b) => a > b ? a : b);

    // For steps, ensure clean intervals
    if (chartType == ChartType.steps) {
      return (maxValue * 1.15).ceil() / 1000 * 1000;
    }

    return maxValue * 1.1;
  }

  double _getHorizontalInterval() {
    switch (chartType) {
      case ChartType.hrv:
        return 10;
      case ChartType.rhr:
        return 10;
      case ChartType.steps:
        return 2000;
    }
  }

  double _getLeftInterval() {
    switch (chartType) {
      case ChartType.hrv:
        return 15; // Increased to prevent overlapping
      case ChartType.rhr:
        return 15; // Increased to prevent overlapping
      case ChartType.steps:
        return 4000; // Increased to prevent overlapping
    }
  }

  double _getBottomInterval() {
    switch (selectedRange) {
      case DataRange.sevenDays:
        return 259200000; // 3 days in milliseconds
      case DataRange.thirtyDays:
        return 1209600000; // 14 days in milliseconds
      case DataRange.ninetyDays:
        return 2419200000; // 28 days in milliseconds
    }
  }

  Widget _buildBottomTitle(double value, TitleMeta meta) {
    final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
    String format;

    switch (selectedRange) {
      case DataRange.sevenDays:
        format = 'MMM dd';
        break;
      case DataRange.thirtyDays:
        format = 'MMM dd';
        break;
      case DataRange.ninetyDays:
        format = 'MMM';
        break;
    }

    return Text(
      DateFormat(format).format(date),
      style: const TextStyle(fontSize: 10),
    );
  }

  Widget _buildLeftTitle(double value, TitleMeta meta) {
    String text;
    switch (chartType) {
      case ChartType.hrv:
        text = value.toInt().toString();
        break;
      case ChartType.rhr:
        text = value.toInt().toString();
        break;
      case ChartType.steps:
        text = '${(value / 1000).toStringAsFixed(0)}k';
        break;
    }

    return Text(text, style: const TextStyle(fontSize: 10));
  }

  String _getTooltipText(BiometricData data) {
    final date = DateFormat('MMM dd, yyyy').format(data.dateTime);
    switch (chartType) {
      case ChartType.hrv:
        return 'HRV: ${data.hrv.toStringAsFixed(1)}\n$date';
      case ChartType.rhr:
        return 'RHR: ${data.rhr} bpm\n$date';
      case ChartType.steps:
        return 'Steps: ${data.steps}\n$date';
    }
  }

  List<LineChartBarData> _getBandData(List<BiometricData> data) {
    if (chartType != ChartType.hrv || data.isEmpty) return [];

    // Calculate 7-day rolling statistics
    final stats = DataDecimator.calculateRollingStats(data, 7);
    final upperBounds = stats['upper']!;
    final lowerBounds = stats['lower']!;

    if (upperBounds.isEmpty || lowerBounds.isEmpty) return [];

    // Create upper and lower bound spots
    final upperSpots = <FlSpot>[];
    final lowerSpots = <FlSpot>[];

    for (int i = 0; i < data.length; i++) {
      final x = data[i].dateTime.millisecondsSinceEpoch.toDouble();
      upperSpots.add(FlSpot(x, upperBounds[i]));
      lowerSpots.add(FlSpot(x, lowerBounds[i]));
    }

    // Create band area using gradient fill
    return [
      LineChartBarData(
        spots: upperSpots + lowerSpots.reversed.toList(),
        isCurved: true,
        color: Colors.blue.withValues(alpha: 0.15),
        barWidth: 0,
        dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(
          show: true,
          color: Colors.blue.withValues(alpha: 0.1),
        ),
      ),
    ];
  }

  List<HorizontalLine> _getHorizontalLines(
    List<BiometricData> data,
    bool isDark,
  ) {
    if (chartType != ChartType.hrv) return [];

    // Add mean line for HRV using 7-day rolling mean
    final stats = DataDecimator.calculateRollingStats(data, 7);
    final means = stats['mean']!;

    if (means.isEmpty) return [];

    final mean = means.reduce((a, b) => a + b) / means.length;

    return [
      HorizontalLine(
        y: mean,
        color: Colors.blue.withValues(alpha: 0.5),
        strokeWidth: 1,
        dashArray: [5, 5],
        label: HorizontalLineLabel(
          show: true,
          alignment: Alignment.topRight,
          padding: const EdgeInsets.only(right: 5),
          style: TextStyle(
            color: Colors.blue.withValues(alpha: 0.7),
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    ];
  }

  Widget _buildEmptyChart(ThemeData theme) {
    return Container(
      height: 280,
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Text(
          'No data available',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }
}

enum ChartType { hrv, rhr, steps }

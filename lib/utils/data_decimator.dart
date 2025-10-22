import 'dart:math';
import 'package:unfold_ai/core/core.dart';

/// Data decimation utility for performance optimization
/// Implements LTTB (Largest Triangle Three Buckets) algorithm
class DataDecimator {
  /// Decimates data using LTTB algorithm to maintain visual fidelity
  /// while reducing the number of data points for performance
  static List<BiometricData> decimateData(
    List<BiometricData> data,
    int targetPoints,
  ) {
    if (data.length <= targetPoints) return data;

    final result = <BiometricData>[];
    final bucketSize = (data.length - 2) / (targetPoints - 2);

    // Always include first point
    result.add(data[0]);

    for (int i = 1; i < targetPoints - 1; i++) {
      final bucketStart = (i * bucketSize).floor();
      final bucketEnd = min(((i + 1) * bucketSize).floor(), data.length);

      // Calculate average point for the bucket
      double avgX = 0, avgY = 0;
      for (int j = bucketStart; j < bucketEnd; j++) {
        avgX += data[j].dateTime.millisecondsSinceEpoch.toDouble();
        avgY += data[j].hrv;
      }
      avgX /= (bucketEnd - bucketStart);
      avgY /= (bucketEnd - bucketStart);

      // Find point with largest triangle area
      double maxArea = -1;
      int maxIndex = bucketStart;

      for (int j = bucketStart; j < bucketEnd; j++) {
        final area = _calculateTriangleArea(
          result.last.dateTime.millisecondsSinceEpoch.toDouble(),
          result.last.hrv,
          avgX,
          avgY,
          data[j].dateTime.millisecondsSinceEpoch.toDouble(),
          data[j].hrv,
        );

        if (area > maxArea) {
          maxArea = area;
          maxIndex = j;
        }
      }

      result.add(data[maxIndex]);
    }

    // Always include last point
    result.add(data.last);

    return result;
  }

  /// Calculates triangle area for LTTB algorithm
  static double _calculateTriangleArea(
    double x1,
    double y1,
    double x2,
    double y2,
    double x3,
    double y3,
  ) {
    return ((x2 - x1) * (y3 - y1) - (x3 - x1) * (y2 - y1)).abs() / 2;
  }

  /// Bucket aggregation for simpler decimation
  static List<BiometricData> bucketAggregate(
    List<BiometricData> data,
    int targetPoints,
  ) {
    if (data.length <= targetPoints) return data;

    final result = <BiometricData>[];
    final bucketSize = data.length / targetPoints;

    for (int i = 0; i < targetPoints; i++) {
      final start = (i * bucketSize).floor();
      final end = ((i + 1) * bucketSize).floor();

      if (start >= data.length) break;

      final bucket = data.sublist(start, min(end, data.length));

      // Calculate aggregated values
      final avgHrv =
          bucket.map((d) => d.hrv).reduce((a, b) => a + b) / bucket.length;
      final avgRhr =
          bucket.map((d) => d.rhr).reduce((a, b) => a + b) / bucket.length;
      final avgSteps =
          bucket.map((d) => d.steps).reduce((a, b) => a + b) / bucket.length;
      final avgSleepScore =
          bucket.map((d) => d.sleepScore).reduce((a, b) => a + b) /
          bucket.length;

      // Use middle date from bucket
      final middleIndex = bucket.length ~/ 2;
      final middleDate = bucket[middleIndex].date;

      result.add(
        BiometricData(
          date: middleDate,
          hrv: avgHrv,
          rhr: avgRhr.round(),
          steps: avgSteps.round(),
          sleepScore: avgSleepScore.round(),
        ),
      );
    }

    return result;
  }

  /// Filters data by date range
  static List<BiometricData> filterByRange(
    List<BiometricData> data,
    DateTime startDate,
    DateTime endDate,
  ) {
    return data.where((d) {
      final date = d.dateTime;
      return date.isAfter(startDate.subtract(const Duration(days: 1))) &&
          date.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();
  }

  /// Calculates rolling statistics for bands
  static Map<String, List<double>> calculateRollingStats(
    List<BiometricData> data,
    int windowSize,
  ) {
    final means = <double>[];
    final upperBounds = <double>[];
    final lowerBounds = <double>[];

    for (int i = 0; i < data.length; i++) {
      final start = max(0, i - windowSize + 1);
      final window = data.sublist(start, i + 1);

      final values = window.map((d) => d.hrv).toList();
      final mean = values.reduce((a, b) => a + b) / values.length;

      // Calculate standard deviation
      final variance =
          values.map((v) => pow(v - mean, 2)).reduce((a, b) => a + b) /
          values.length;
      final stdDev = sqrt(variance);

      means.add(mean);
      upperBounds.add(mean + stdDev);
      lowerBounds.add(mean - stdDev);
    }

    return {'mean': means, 'upper': upperBounds, 'lower': lowerBounds};
  }
}

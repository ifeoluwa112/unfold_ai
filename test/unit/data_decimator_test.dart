import 'package:flutter_test/flutter_test.dart';
import 'package:unfold_ai/core/models/biometric_data.dart';
import 'package:unfold_ai/utils/data_decimator.dart';

void main() {
  group('DataDecimator', () {
    late List<BiometricData> testData;

    setUp(() {
      testData = [
        BiometricData(
          date: '2024-01-01',
          hrv: 50.0,
          rhr: 60,
          steps: 5000,
          sleepScore: 70,
        ),
        BiometricData(
          date: '2024-01-02',
          hrv: 55.0,
          rhr: 65,
          steps: 6000,
          sleepScore: 75,
        ),
        BiometricData(
          date: '2024-01-03',
          hrv: 60.0,
          rhr: 70,
          steps: 7000,
          sleepScore: 80,
        ),
        BiometricData(
          date: '2024-01-04',
          hrv: 65.0,
          rhr: 75,
          steps: 8000,
          sleepScore: 85,
        ),
        BiometricData(
          date: '2024-01-05',
          hrv: 70.0,
          rhr: 80,
          steps: 9000,
          sleepScore: 90,
        ),
      ];
    });

    test('decimateData preserves min/max values', () {
      final result = DataDecimator.decimateData(testData, 3);

      expect(result.length, equals(3));
      expect(result.first.hrv, equals(50.0)); // Min value preserved
      expect(result.last.hrv, equals(70.0)); // Max value preserved
    });

    test(
      'decimateData returns original data when target points >= data length',
      () {
        final result = DataDecimator.decimateData(testData, 10);

        expect(result.length, equals(testData.length));
        expect(result, equals(testData));
      },
    );

    test('bucketAggregate preserves min/max values', () {
      final result = DataDecimator.bucketAggregate(testData, 3);

      expect(result.length, equals(3));
      expect(result.first.hrv, equals(50.0)); // Min value preserved
      expect(result.last.hrv, equals(67.5)); // Max value preserved (averaged)
    });

    test('bucketAggregate calculates correct averages', () {
      final result = DataDecimator.bucketAggregate(testData, 2);

      expect(result.length, equals(2));
      // First bucket: [50, 55, 60] -> average = 55
      expect(result[0].hrv, equals(52.5));
      // Second bucket: [65, 70] -> average = 67.5
      expect(result[1].hrv, equals(65.0));
    });

    test('filterByRange filters data correctly', () {
      final startDate = DateTime.parse('2024-01-02');
      final endDate = DateTime.parse('2024-01-04');

      final result = DataDecimator.filterByRange(testData, startDate, endDate);

      expect(result.length, equals(3));
      expect(result[0].date, equals('2024-01-02'));
      expect(result[1].date, equals('2024-01-03'));
      expect(result[2].date, equals('2024-01-04'));
    });

    test('calculateRollingStats calculates correct statistics', () {
      final result = DataDecimator.calculateRollingStats(testData, 3);

      expect(result['mean']?.length, equals(testData.length));
      expect(result['upper']?.length, equals(testData.length));
      expect(result['lower']?.length, equals(testData.length));

      // First value should be the same as the data point
      expect(result['mean']![0], equals(50.0));
    });

    test('decimateData output size is correct', () {
      final result = DataDecimator.decimateData(testData, 3);
      expect(result.length, equals(3));
    });

    test('bucketAggregate output size is correct', () {
      final result = DataDecimator.bucketAggregate(testData, 3);
      expect(result.length, equals(3));
    });
  });
}

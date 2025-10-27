import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:unfold_ai/core/core.dart';
import 'dashboard_state.dart';

class DashboardBloc extends Cubit<DashboardState> {
  DashboardBloc() : super(const DashboardState());

  Future<void> loadData() async {
    emit(state.copyWith(isLoading: true, error: null));

    try {
      // Simulate network latency (700-1200ms)
      final latency = 700 + Random().nextInt(500);
      await Future.delayed(Duration(milliseconds: latency));

      // Simulate ~10% failure rate
      if (Random().nextDouble() < 0.1) {
        throw Exception('Network request failed');
      }

      // Load biometric data
      final biometricJson = await rootBundle.loadString(
        'assets/biometrics_90d.json',
      );
      var biometricList = (jsonDecode(biometricJson) as List)
          .map((json) => BiometricData.fromJson(json))
          .toList();

      // Simulate large dataset by duplicating and interpolating data
      if (state.isLargeDataset) {
        biometricList = _simulateLargeDataset(biometricList);
      }

      // Load journal entries
      final journalJson = await rootBundle.loadString('assets/journals.json');
      final journalList = (jsonDecode(journalJson) as List)
          .map((json) => JournalEntry.fromJson(json))
          .toList();

      emit(
        state.copyWith(
          biometricData: biometricList,
          journalEntries: journalList,
          isLoading: false,
        ),
      );
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  List<BiometricData> _simulateLargeDataset(List<BiometricData> originalData) {
    if (originalData.isEmpty) return originalData;

    final expandedData = <BiometricData>[];
    final random = Random();

    for (int i = 0; i < originalData.length; i++) {
      final current = originalData[i];
      final next = i < originalData.length - 1 ? originalData[i + 1] : current;

      // Add original point
      expandedData.add(current);

      // Generate 5-10 interpolated points between each original point
      final numPoints = 5 + random.nextInt(6); // 5 to 10 points
      for (int j = 1; j < numPoints; j++) {
        final ratio = j / numPoints;
        final interpolatedDate = DateTime(
          current.dateTime.year,
          current.dateTime.month,
          current.dateTime.day,
          current.dateTime.hour,
          current.dateTime.minute +
              (next.dateTime.minute - current.dateTime.minute) * ratio.toInt(),
        );

        final interpolatedData = BiometricData(
          date: interpolatedDate.toIso8601String().split('T')[0],
          hrv:
              current.hrv +
              (next.hrv - current.hrv) * ratio +
              (random.nextDouble() - 0.5) * 2,
          rhr:
              (current.rhr + (next.rhr - current.rhr) * ratio).toInt() +
              random.nextInt(3) -
              1,
          steps:
              (current.steps + (next.steps - current.steps) * ratio).toInt() +
              random.nextInt(200) -
              100,
          sleepScore:
              (current.sleepScore +
                      (next.sleepScore - current.sleepScore) * ratio)
                  .toInt() +
              random.nextInt(5) -
              2,
        );

        expandedData.add(interpolatedData);
      }
    }

    return expandedData;
  }

  void selectRange(DataRange range) {
    emit(state.copyWith(selectedRange: range));
  }

  void selectDate(DateTime? date) {
    emit(state.copyWith(selectedDate: date));
  }

  void toggleLargeDataset() {
    final newState = !state.isLargeDataset;
    emit(state.copyWith(isLargeDataset: newState));
    // Reload data to apply the large dataset simulation
    loadData();
  }

  void selectJournalEntry(JournalEntry? entry) {
    emit(state.copyWith(selectedJournalEntry: entry));
  }

  void retry() {
    loadData();
  }
}

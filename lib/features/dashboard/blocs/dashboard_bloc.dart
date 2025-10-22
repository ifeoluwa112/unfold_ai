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
      final biometricList = (jsonDecode(biometricJson) as List)
          .map((json) => BiometricData.fromJson(json))
          .toList();

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

  void selectRange(DataRange range) {
    emit(state.copyWith(selectedRange: range));
  }

  void selectDate(DateTime? date) {
    emit(state.copyWith(selectedDate: date));
  }

  void toggleLargeDataset() {
    emit(state.copyWith(isLargeDataset: !state.isLargeDataset));
  }

  void retry() {
    loadData();
  }
}

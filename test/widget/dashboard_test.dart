import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:unfold_ai/core/models/biometric_data.dart';
import 'package:unfold_ai/core/models/journal_entry.dart';
import 'package:unfold_ai/ui/ui.dart';

void main() {
  group('Dashboard Widget Tests', () {
    testWidgets('Range switch updates all charts x-axis domains', (
      tester,
    ) async {
      // Create test data
      final testData = [
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
      ];

      final testJournals = [
        JournalEntry(date: '2024-01-01', mood: 3, note: 'Test note'),
      ];

      // Create a mock bloc
      final mockBloc = MockDashboardBloc();

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<DashboardBloc>(
            create: (context) => mockBloc,
            child: const DashboardView(),
          ),
        ),
      );

      // Set initial state
      mockBloc.emit(
        DashboardState(
          biometricData: testData,
          journalEntries: testJournals,
          selectedRange: DataRange.sevenDays,
        ),
      );

      await tester.pump();

      // Verify charts are rendered
      expect(find.byType(BiometricChart), findsNWidgets(3));

      // Switch to 30-day range
      mockBloc.emit(
        DashboardState(
          biometricData: testData,
          journalEntries: testJournals,
          selectedRange: DataRange.thirtyDays,
        ),
      );

      await tester.pump();

      // Verify charts are still rendered with new range
      expect(find.byType(BiometricChart), findsNWidgets(3));
    });

    testWidgets('Tooltips remain synced across charts', (tester) async {
      final testData = [
        BiometricData(
          date: '2024-01-01',
          hrv: 50.0,
          rhr: 60,
          steps: 5000,
          sleepScore: 70,
        ),
      ];

      final mockBloc = MockDashboardBloc();

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<DashboardBloc>(
            create: (context) => mockBloc,
            child: const DashboardView(),
          ),
        ),
      );

      mockBloc.emit(
        DashboardState(
          biometricData: testData,
          journalEntries: [],
          selectedRange: DataRange.sevenDays,
          selectedDate: DateTime.parse('2024-01-01'),
        ),
      );

      await tester.pump();

      // Verify charts are rendered
      expect(find.byType(BiometricChart), findsNWidgets(3));
    });

    testWidgets('Loading state shows loading widget', (tester) async {
      final mockBloc = MockDashboardBloc();

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<DashboardBloc>(
            create: (context) => mockBloc,
            child: const DashboardView(),
          ),
        ),
      );

      mockBloc.emit(const DashboardState(isLoading: true));

      await tester.pump();

      expect(find.byType(LoadingWidget), findsOneWidget);
    });

    testWidgets('Error state shows error widget', (tester) async {
      final mockBloc = MockDashboardBloc();

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<DashboardBloc>(
            create: (context) => mockBloc,
            child: const DashboardView(),
          ),
        ),
      );

      mockBloc.emit(
        const DashboardState(isLoading: false, error: 'Test error'),
      );

      await tester.pumpAndSettle();

      expect(find.byType(CustomErrorWidget), findsOneWidget);
    });

    testWidgets('Empty state shows empty widget', (tester) async {
      final mockBloc = MockDashboardBloc();

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<DashboardBloc>(
            create: (context) => mockBloc,
            child: const DashboardView(),
          ),
        ),
      );

      mockBloc.emit(const DashboardState(isLoading: false, biometricData: []));

      await tester.pumpAndSettle();

      expect(find.byType(EmptyStateWidget), findsOneWidget);
    });
  });
}

class MockDashboardBloc extends DashboardBloc {
  MockDashboardBloc() : super();
}

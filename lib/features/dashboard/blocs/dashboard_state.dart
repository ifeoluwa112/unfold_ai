import 'package:equatable/equatable.dart';
import '../../../core/models/biometric_data.dart';
import '../../../core/models/journal_entry.dart';

enum DataRange { sevenDays, thirtyDays, ninetyDays }

class DashboardState extends Equatable {
  final List<BiometricData> biometricData;
  final List<JournalEntry> journalEntries;
  final DataRange selectedRange;
  final bool isLoading;
  final String? error;
  final DateTime? selectedDate;
  final bool isLargeDataset;

  const DashboardState({
    this.biometricData = const [],
    this.journalEntries = const [],
    this.selectedRange = DataRange.sevenDays,
    this.isLoading = false,
    this.error,
    this.selectedDate,
    this.isLargeDataset = false,
  });

  DashboardState copyWith({
    List<BiometricData>? biometricData,
    List<JournalEntry>? journalEntries,
    DataRange? selectedRange,
    bool? isLoading,
    String? error,
    DateTime? selectedDate,
    bool? isLargeDataset,
  }) {
    return DashboardState(
      biometricData: biometricData ?? this.biometricData,
      journalEntries: journalEntries ?? this.journalEntries,
      selectedRange: selectedRange ?? this.selectedRange,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      selectedDate: selectedDate ?? this.selectedDate,
      isLargeDataset: isLargeDataset ?? this.isLargeDataset,
    );
  }

  @override
  List<Object?> get props => [
    biometricData,
    journalEntries,
    selectedRange,
    isLoading,
    error,
    selectedDate,
    isLargeDataset,
  ];
}

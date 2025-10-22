import 'package:json_annotation/json_annotation.dart';

part 'journal_entry.g.dart';

@JsonSerializable()
class JournalEntry {
  final String date;
  final int mood;
  final String note;

  const JournalEntry({
    required this.date,
    required this.mood,
    required this.note,
  });

  factory JournalEntry.fromJson(Map<String, dynamic> json) =>
      _$JournalEntryFromJson(json);

  Map<String, dynamic> toJson() => _$JournalEntryToJson(this);

  DateTime get dateTime => DateTime.parse(date);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is JournalEntry &&
          runtimeType == other.runtimeType &&
          date == other.date &&
          mood == other.mood &&
          note == other.note;

  @override
  int get hashCode => date.hashCode ^ mood.hashCode ^ note.hashCode;

  @override
  String toString() {
    return 'JournalEntry{date: $date, mood: $mood, note: $note}';
  }
}

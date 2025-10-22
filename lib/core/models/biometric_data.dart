import 'package:json_annotation/json_annotation.dart';

part 'biometric_data.g.dart';

@JsonSerializable()
class BiometricData {
  final String date;
  final double hrv;
  final int rhr;
  final int steps;
  final int sleepScore;

  const BiometricData({
    required this.date,
    required this.hrv,
    required this.rhr,
    required this.steps,
    required this.sleepScore,
  });

  factory BiometricData.fromJson(Map<String, dynamic> json) =>
      _$BiometricDataFromJson(json);

  Map<String, dynamic> toJson() => _$BiometricDataToJson(this);

  DateTime get dateTime => DateTime.parse(date);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BiometricData &&
          runtimeType == other.runtimeType &&
          date == other.date &&
          hrv == other.hrv &&
          rhr == other.rhr &&
          steps == other.steps &&
          sleepScore == other.sleepScore;

  @override
  int get hashCode =>
      date.hashCode ^
      hrv.hashCode ^
      rhr.hashCode ^
      steps.hashCode ^
      sleepScore.hashCode;

  @override
  String toString() {
    return 'BiometricData{date: $date, hrv: $hrv, rhr: $rhr, steps: $steps, sleepScore: $sleepScore}';
  }
}

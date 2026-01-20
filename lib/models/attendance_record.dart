class AttendanceRecord {
  final DateTime date;
  final String inTime;
  final String outTime;
  final Duration totalTime;
  final Duration totalBreak;

  AttendanceRecord({
    required this.date,
    required this.inTime,
    required this.outTime,
    required this.totalTime,
    required this.totalBreak,
  });
}
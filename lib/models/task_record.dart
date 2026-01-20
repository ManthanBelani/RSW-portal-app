import 'package:dashboard_clone/services/auth_service.dart';

class TaskRecord {
  final String id;
  final DateTime date;
  final DateTime createdDate;
  final String time;
  final String note;
  final String project;
  final String user;
  final String username;
  final String action;
  final Map<String, dynamic> rawData;

  TaskRecord({
    required this.id,
    required this.date,
    required this.createdDate,
    required this.time,
    required this.note,
    required this.project,
    required this.user,
    required this.username,
    required this.action,
    required this.rawData,
  });

  Future<bool> canEdit() async {
    final currentUsername = await AuthService.getUsername();
    if (currentUsername?.toLowerCase() == 'admin') {
      return true;
    }

    if (currentUsername?.toLowerCase() == username.toLowerCase()) {
      final now = DateTime.now();
      final difference = now.difference(createdDate);
      return difference.inMinutes <= 15;
    }

    return false;
  }
}

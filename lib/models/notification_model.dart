class NotificationModel {
  final String message;
  final String time;
  final CreatedBy createdBy;
  final int isReminder;
  final int isRead;

  NotificationModel({
    required this.message,
    required this.time,
    required this.createdBy,
    required this.isReminder,
    required this.isRead,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      message: json['message']?.toString() ?? '',
      time: json['time']?.toString() ?? '',
      createdBy: CreatedBy.fromJson(json['created_by'] as Map<String, dynamic>? ?? {}),
      isReminder: int.tryParse(json['is_reminder']?.toString() ?? '0') ?? 0,
      isRead: int.tryParse(json['is_read']?.toString() ?? '0') ?? 0,
    );
  }

  String getInitials() {
    final firstName = createdBy.firstName;
    final lastName = createdBy.lastName;
    
    String initials = '';
    if (firstName.isNotEmpty) {
      initials += firstName[0].toUpperCase();
    }
    if (lastName.isNotEmpty) {
      initials += lastName[0].toUpperCase();
    }
    
    return initials.isEmpty ? 'UN' : initials;
  }

  String getTimeAgo() {
    try {
      final notificationTime = DateTime.parse(time);
      final now = DateTime.now();
      final difference = now.difference(notificationTime);

      if (difference.inDays > 0) {
        return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return 'Unknown time';
    }
  }
}

class CreatedBy {
  final int id;
  final String lastName;
  final String firstName;
  final int designationId;

  CreatedBy({
    required this.id,
    required this.lastName,
    required this.firstName,
    required this.designationId,
  });

  factory CreatedBy.fromJson(Map<String, dynamic> json) {
    return CreatedBy(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      lastName: json['last_name']?.toString() ?? '',
      firstName: json['first_name']?.toString() ?? '',
      designationId: int.tryParse(json['designation_id']?.toString() ?? '0') ?? 0,
    );
  }
}

class NotificationResponse {
  final bool success;
  final List<NotificationModel> notifications;
  final int recordsTotal;
  final int recordsFiltered;

  NotificationResponse({
    required this.success,
    required this.notifications,
    required this.recordsTotal,
    required this.recordsFiltered,
  });

  factory NotificationResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    final notificationsList = data['notifications'] as List<dynamic>? ?? [];
    
    return NotificationResponse(
      success: json['success'] ?? false,
      notifications: notificationsList
          .map((item) => NotificationModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      recordsTotal: data['recordsTotal'] ?? 0,
      recordsFiltered: data['recordsFiltered'] ?? 0,
    );
  }

  int get unreadCount => notifications.where((n) => n.isRead == 0).length;
}
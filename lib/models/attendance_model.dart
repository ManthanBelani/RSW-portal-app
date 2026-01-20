class AttendanceResponse {
  final bool success;
  final AttendanceData data;

  AttendanceResponse({
    required this.success,
    required this.data,
  });

  factory AttendanceResponse.fromJson(Map<String, dynamic> json) {
    return AttendanceResponse(
      success: json['success'] as bool,
      data: AttendanceData.fromJson(json['data']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'data': data.toJson(),
    };
  }
}

class AttendanceData {
  final int recordsTotal;
  final int recordsFiltered;
  final List<AttendanceRecord> data;

  AttendanceData({
    required this.recordsTotal,
    required this.recordsFiltered,
    required this.data,
  });

  factory AttendanceData.fromJson(Map<String, dynamic> json) {
    return AttendanceData(
      recordsTotal: json['recordsTotal'] as int,
      recordsFiltered: json['recordsFiltered'] as int,
      data: (json['data'] as List)
          .map((item) => AttendanceRecord.fromJson(item))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'recordsTotal': recordsTotal,
      'recordsFiltered': recordsFiltered,
      'data': data.map((e) => e.toJson()).toList(),
    };
  }
}

class AttendanceRecord {
  final String date;
  final String intime;
  final String outtime;
  final String totaltime;
  final String totalBreak;
  final int exclamationMark;
  final List<WorkingSession> workingSessions;
  final List<BreakSession> breakSessions;
  final String? leaveStatus;

  AttendanceRecord({
    required this.date,
    required this.intime,
    required this.outtime,
    required this.totaltime,
    required this.totalBreak,
    required this.exclamationMark,
    required this.workingSessions,
    required this.breakSessions,
    this.leaveStatus,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      date: json['date'] as String,
      intime: json['intime'] as String,
      outtime: json['outtime'] as String,
      totaltime: json['totaltime'] as String,
      totalBreak: json['total_break'] as String,
      exclamationMark: json['exclamation_mark'] as int,
      workingSessions: (json['workingSessions'] as List)
          .map((item) => WorkingSession.fromJson(item))
          .toList(),
      breakSessions: (json['breakSessions'] as List)
          .map((item) => BreakSession.fromJson(item))
          .toList(),
      leaveStatus: json['leave_status'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'intime': intime,
      'outtime': outtime,
      'totaltime': totaltime,
      'total_break': totalBreak,
      'exclamation_mark': exclamationMark,
      'workingSessions': workingSessions.map((e) => e.toJson()).toList(),
      'breakSessions': breakSessions.map((e) => e.toJson()).toList(),
      'leave_status': leaveStatus,
    };
  }
}

class WorkingSession {
  final String inTime;
  final String? outTime;
  final String duration;
  final int mid;
  final String deviceName;
  final String status;

  WorkingSession({
    required this.inTime,
    this.outTime,
    required this.duration,
    required this.mid,
    required this.deviceName,
    required this.status,
  });

  factory WorkingSession.fromJson(Map<String, dynamic> json) {
    return WorkingSession(
      inTime: json['in'] as String,
      outTime: json['out'] as String?,
      duration: json['duration'] as String,
      mid: json['MID'] as int,
      deviceName: json['device_name'] as String,
      status: json['status'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'in': inTime,
      'out': outTime,
      'duration': duration,
      'MID': mid,
      'device_name': deviceName,
      'status': status,
    };
  }
}

class BreakSession {
  final String breakStart;
  final String? breakEnd;
  final String breakDuration;

  BreakSession({
    required this.breakStart,
    this.breakEnd,
    required this.breakDuration,
  });

  factory BreakSession.fromJson(Map<String, dynamic> json) {
    return BreakSession(
      breakStart: json['break_start'] as String,
      breakEnd: json['break_end'] as String?,
      breakDuration: json['break_duration'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'break_start': breakStart,
      'break_end': breakEnd,
      'break_duration': breakDuration,
    };
  }
}
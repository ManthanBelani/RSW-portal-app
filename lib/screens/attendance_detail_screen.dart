import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/constants.dart';

class AttendanceDetailScreen extends StatelessWidget {
  final DateTime date;
  final Map<String, dynamic> attendanceData;

  const AttendanceDetailScreen({
    super.key,
    required this.date,
    required this.attendanceData,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    // Parse working sessions from API data
    final List<AttendanceLog> logs = [];
    final workingSessions = attendanceData['workingSessions'] as List? ?? [];
    
    for (var session in workingSessions) {
      // Add punch in
      final inTime = session['in'] as String;
      final inParts = inTime.split(':');
      final inHour = int.parse(inParts[0]);
      final inPeriod = inHour >= 12 ? 'PM' : 'AM';
      final inDisplayHour = inHour > 12 ? inHour - 12 : (inHour == 0 ? 12 : inHour);
      final inTimeFormatted = '$inDisplayHour:${inParts[1]}:${inParts[2]}';
      
      logs.add(AttendanceLog(
        time: inTimeFormatted,
        period: inPeriod,
        direction: '${session['device_name']} - Punch In',
        isPunchIn: true,
      ));
      
      // Add punch out if not ongoing
      if (session['out'] != 'Still working') {
        final outTime = session['out'] as String;
        final outParts = outTime.split(':');
        final outHour = int.parse(outParts[0]);
        final outPeriod = outHour >= 12 ? 'PM' : 'AM';
        final outDisplayHour = outHour > 12 ? outHour - 12 : (outHour == 0 ? 12 : outHour);
        final outTimeFormatted = '$outDisplayHour:${outParts[1]}:${outParts[2]}';
        
        logs.add(AttendanceLog(
          time: outTimeFormatted,
          period: outPeriod,
          direction: '${session['device_name']} - Punch Out',
          isPunchIn: false,
        ));
      }
    }
    
    final totalWorkingTime = attendanceData['totaltime'] ?? '00:00:00';

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Container(
          margin: EdgeInsets.all(isMobile ? 12 : 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.1),
                spreadRadius: 2,
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header Section
              Container(
                padding: EdgeInsets.all(isMobile ? 16 : 24),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Full attendance report of',
                            style: TextStyle(
                              fontSize: isMobile ? 16 : 18,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('dd/MM/yyyy').format(date),
                            style: TextStyle(
                              fontSize: isMobile ? 16 : 18,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 20 : 28,
                          vertical: isMobile ? 10 : 14,
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Back',
                        style: TextStyle(
                          fontSize: isMobile ? 14 : 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Table Header
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 16 : 24,
                  vertical: isMobile ? 12 : 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  border: Border(
                    top: BorderSide(color: Colors.grey[200]!, width: 1),
                    bottom: BorderSide(color: Colors.grey[200]!, width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Center(
                        child: Text(
                          'Log Time',
                          style: TextStyle(
                            fontSize: isMobile ? 14 : 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Center(
                        child: Text(
                          'Direction',
                          style: TextStyle(
                            fontSize: isMobile ? 14 : 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Attendance Logs
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: logs.length,
                  itemBuilder: (context, index) {
                    final log = logs[index];
                    return Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 16 : 24,
                        vertical: isMobile ? 16 : 20,
                      ),
                      decoration: BoxDecoration(
                        color: index % 2 == 0 ? Colors.grey[50] : Colors.white,
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.grey[200]!,
                            width: 0.5,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Center(
                                  child: Text(
                                    log.time,
                                    style: TextStyle(
                                      fontSize: isMobile ? 13 : 15,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                                Center(
                                  child: Text(
                                    log.period,
                                    style: TextStyle(
                                      fontSize: isMobile ? 11 : 13,
                                      fontWeight: FontWeight.w400,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Direction Column
                          Expanded(
                            flex: 3,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: isMobile ? 8 : 12,
                                vertical: isMobile ? 6 : 8,
                              ),
                              decoration: BoxDecoration(
                                color: log.isPunchIn
                                    ? Colors.green[100]
                                    : Colors.red[100],
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                log.direction,
                                style: TextStyle(
                                  fontSize: isMobile ? 11 : 13,
                                  fontWeight: FontWeight.w500,
                                  color: log.isPunchIn
                                      ? Colors.green[700]
                                      : Colors.red[700],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Total Working Time
              Container(
                width: double.infinity,
                margin: EdgeInsets.all(isMobile ? 16 : 24),
                padding: EdgeInsets.all(isMobile ? 16 : 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Text(
                  'Total Working Time : $totalWorkingTime',
                  style: TextStyle(
                    fontSize: isMobile ? 16 : 18,
                    fontWeight: FontWeight.w600,
                    color: primaryColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AttendanceLog {
  final String time;
  final String period;
  final String direction;
  final bool isPunchIn;

  AttendanceLog({
    required this.time,
    required this.period,
    required this.direction,
    required this.isPunchIn,
  });
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TestCalender extends StatefulWidget {
  final List<Map<String, dynamic>>? birthdays;
  final List<Map<String, dynamic>>? holidays;
  final List<Map<String, dynamic>>? leaves;
  final List<Map<String, dynamic>>? attendance;
  final List<Map<String, dynamic>>? employeeLeaves;
  final bool isAdmin;

  const TestCalender({
    super.key,
    this.birthdays,
    this.holidays,
    this.leaves,
    this.attendance,
    this.employeeLeaves,
    this.isAdmin = false,
  });

  @override
  State<TestCalender> createState() => _TestCalenderState();
}

class _TestCalenderState extends State<TestCalender> {
  late DateTime _activeDate;

  @override
  void initState() {
    super.initState();
    _activeDate = DateTime.now();
    _debugPrintData();
  }

  void _debugPrintData() {
    print('=== Calendar Data Debug ===');
    print('Birthdays: ${widget.birthdays?.length ?? 0}');
    if (widget.birthdays != null && widget.birthdays!.isNotEmpty) {
      print('All birthdays:');
      for (var birthday in widget.birthdays!) {
        print('  - ${birthday['first_name']} ${birthday['last_name']}: ${birthday['birthdate']}');
      }
    }
    print('Holidays: ${widget.holidays?.length ?? 0}');
    if (widget.holidays != null && widget.holidays!.isNotEmpty) {
      print('First 3 holidays:');
      for (var i = 0; i < (widget.holidays!.length > 3 ? 3 : widget.holidays!.length); i++) {
        print('  - ${widget.holidays![i]['description']}: ${widget.holidays![i]['start']}');
      }
    }
    print('Employee Leaves: ${widget.employeeLeaves?.length ?? 0}');
    if (widget.employeeLeaves != null && widget.employeeLeaves!.isNotEmpty) {
      print('First 3 employee leaves:');
      for (var i = 0; i < (widget.employeeLeaves!.length > 3 ? 3 : widget.employeeLeaves!.length); i++) {
        print('  - ${widget.employeeLeaves![i]['date']}');
      }
    }
    print('Attendance: ${widget.attendance?.length ?? 0}');
    print('Leaves: ${widget.leaves?.length ?? 0}');
    print('Current month: ${_activeDate.month}/${_activeDate.year}');
  }

  DateTime _firstDayOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  DateTime _lastDayOfMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0);
  }

  DateTime _firstDayOfCalendar(DateTime date) {
    final firstDay = _firstDayOfMonth(date);
    return firstDay.subtract(Duration(days: firstDay.weekday % 7));
  }

  DateTime _lastDayOfCalendar(DateTime date) {
    final lastDay = _lastDayOfMonth(date);
    final daysToAdd = 6 - (lastDay.weekday % 7);
    return lastDay.add(Duration(days: daysToAdd));
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  bool _isInActiveMonth(DateTime date) {
    return date.month == _activeDate.month && date.year == _activeDate.year;
  }

  bool _isWeekend(DateTime date) {
    return date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
  }

  bool _hasBirthday(DateTime date) {
    if (widget.birthdays == null || widget.birthdays!.isEmpty) return false;
    
    try {
      final result = widget.birthdays!.any((birthday) {
        final birthDateStr = birthday['birthdate'] as String;
        final parts = birthDateStr.split('-');
        if (parts.length == 2) {
          final month = int.parse(parts[0]);
          final day = int.parse(parts[1]);
          final matches = date.month == month && date.day == day;
          if (matches) {
            print('Birthday match found for ${date.day}/${date.month}: $birthday');
          }
          return matches;
        }
        return false;
      });
      return result;
    } catch (e) {
      print('Error checking birthday: $e');
      return false;
    }
  }

  String _getBirthdayInfo(DateTime date) {
    if (widget.birthdays == null) return '';
    final birthdayUsers = widget.birthdays!.where((birthday) {
      final birthDateStr = birthday['birthdate'] as String;
      final parts = birthDateStr.split('-');
      if (parts.length == 2) {
        final month = int.parse(parts[0]);
        final day = int.parse(parts[1]);
        return date.month == month && date.day == day;
      }
      return false;
    }).toList();

    return birthdayUsers
        .map((user) => '${user['first_name']} ${user['last_name']}')
        .join(', ');
  }

  bool _isHoliday(DateTime date) {
    if (widget.holidays == null || widget.holidays!.isEmpty) return false;
    
    try {
      final result = widget.holidays!.any((holiday) {
        final holidayDate = DateTime.parse(holiday['start']);
        final matches = holidayDate.year == date.year &&
            holidayDate.month == date.month &&
            holidayDate.day == date.day;
        if (matches) {
          print(
              'Holiday match found for ${date.day}/${date.month}/${date.year}: ${holiday['description']}');
        }
        return matches;
      });
      return result;
    } catch (e) {
      print('Error checking holiday: $e');
      return false;
    }
  }

  String _getHolidayInfo(DateTime date) {
    if (widget.holidays == null) return '';
    final holidayList = widget.holidays!.where((holiday) {
      final holidayDate = DateTime.parse(holiday['start']);
      return holidayDate.year == date.year &&
          holidayDate.month == date.month &&
          holidayDate.day == date.day;
    }).toList();

    return holidayList.map((h) => h['description']).join(', ');
  }

  bool _hasLeave(DateTime date) {
    if (widget.leaves == null) return false;
    return widget.leaves!.any((leave) {
      final leaveDate = DateTime.parse(leave['start']);
      return leaveDate.year == date.year &&
          leaveDate.month == date.month &&
          leaveDate.day == date.day;
    });
  }

  bool _hasEmployeeLeave(DateTime date) {
    if (widget.employeeLeaves == null || widget.employeeLeaves!.isEmpty) {
      return false;
    }
    
    try {
      final result = widget.employeeLeaves!.any((empLeave) {
        final leaveDate = DateTime.parse(empLeave['date']);
        final matches = leaveDate.year == date.year &&
            leaveDate.month == date.month &&
            leaveDate.day == date.day;
        if (matches) {
          print(
              'Employee leave match found for ${date.day}/${date.month}/${date.year}');
        }
        return matches;
      });
      return result;
    } catch (e) {
      print('Error checking employee leave: $e');
      return false;
    }
  }

  List<Map<String, dynamic>> _getEmployeeLeaveInfo(DateTime date) {
    if (widget.employeeLeaves == null) return [];
    final empLeaveData = widget.employeeLeaves!.firstWhere(
      (empLeave) {
        final leaveDate = DateTime.parse(empLeave['date']);
        return leaveDate.year == date.year &&
            leaveDate.month == date.month &&
            leaveDate.day == date.day;
      },
      orElse: () => {},
    );

    if (empLeaveData.isEmpty) return [];
    return List<Map<String, dynamic>>.from(empLeaveData['leave_info'] ?? []);
  }

  bool _hasShortWorkHours(DateTime date) {
    if (widget.attendance == null) return false;
    final workHour = widget.attendance!.firstWhere(
      (wh) {
        final whDate = DateTime.parse(wh['start']);
        return whDate.year == date.year &&
            whDate.month == date.month &&
            whDate.day == date.day;
      },
      orElse: () => {},
    );

    if (workHour.isEmpty) return false;

    final hours = double.tryParse(workHour['hours']?.toString() ?? '0') ?? 0;
    final leaveStatus = workHour['leave_status'];

    if (['hl1', 'hl2'].contains(leaveStatus)) {
      return hours < 4.5;
    } else if (['fl', 'ml'].contains(leaveStatus)) {
      return false;
    } else {
      return hours < 8.5;
    }
  }

  void _previousMonth() {
    setState(() {
      _activeDate = DateTime(_activeDate.year, _activeDate.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _activeDate = DateTime(_activeDate.year, _activeDate.month + 1);
    });
  }

  void _goToToday() {
    setState(() {
      _activeDate = DateTime.now();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(),
          _buildCalendar(),
          if (!widget.isAdmin) _buildLegend(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.chevron_left, color: Colors.grey[700]),
            onPressed: _previousMonth,
            splashRadius: 20,
          ),
          Text(
            DateFormat('MMMM yyyy').format(_activeDate),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey[900],
              letterSpacing: 0.5,
            ),
          ),
          Row(
            children: [
              OutlinedButton(
                onPressed: _goToToday,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.pink[400],
                  side: BorderSide(color: Colors.pink.shade300, width: 1.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                ),
                child: const Text(
                  'Today',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 4),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(Icons.chevron_right, color: Colors.grey[700]),
                onPressed: _nextMonth,
                splashRadius: 20,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildWeekDays(),
          const SizedBox(height: 16),
          _buildDates(),
        ],
      ),
    );
  }

  Widget _buildWeekDays() {
    const weekDays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: weekDays.asMap().entries.map((entry) {
          final isWeekend = entry.key == 0 || entry.key == 6;
          return Expanded(
            child: Center(
              child: Text(
                entry.value,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: isWeekend ? Colors.red[400] : Colors.grey[600],
                  letterSpacing: 0.5,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDates() {
    final firstDay = _firstDayOfCalendar(_activeDate);
    final lastDay = _lastDayOfCalendar(_activeDate);
    final totalDays = lastDay.difference(firstDay).inDays + 1;
    final weeks = (totalDays / 7).ceil();

    return Column(
      children: List.generate(weeks, (weekIndex) {
        return Row(
          children: List.generate(7, (dayIndex) {
            final date = firstDay.add(Duration(days: weekIndex * 7 + dayIndex));
            return Expanded(
              child: _buildDateCell(date),
            );
          }),
        );
      }),
    );
  }

  Widget _buildDateCell(DateTime date) {
    final isToday = _isToday(date);
    final isInMonth = _isInActiveMonth(date);
    final isWeekend = _isWeekend(date);
    final hasBirthday = _hasBirthday(date);
    final isHoliday = _isHoliday(date);
    final hasLeave = _hasLeave(date);
    final hasEmployeeLeave = _hasEmployeeLeave(date);
    final hasShortHours = _hasShortWorkHours(date);

    if (isInMonth && (hasBirthday || isHoliday || hasEmployeeLeave)) {
      print(
          'Date ${date.day}/${date.month}: Birthday=$hasBirthday, Holiday=$isHoliday, EmpLeave=$hasEmployeeLeave');
    }

    Color? backgroundColor;
    Color? borderColor;

    if (isToday && isInMonth) {
      backgroundColor = Colors.green[100];
      borderColor = Colors.green[400];
    } else if (hasBirthday && isInMonth) {
      backgroundColor = Colors.pink[50];
    } else if ((hasLeave || hasEmployeeLeave) && isInMonth && !isWeekend) {
      backgroundColor = Colors.orange[50];
    } else if (hasShortHours && isInMonth) {
      backgroundColor = Colors.red[50];
    } else if (isInMonth) {
      backgroundColor = Colors.grey[100];
    }

    Color textColor;
    if (!isInMonth) {
      textColor = Colors.grey[400]!;
    } else if (isWeekend || isHoliday) {
      textColor = Colors.red[400]!;
    } else if (isToday) {
      textColor = Colors.green[700]!;
    } else {
      textColor = Colors.grey[800]!;
    }

    return GestureDetector(
      onTap: isInMonth
          ? () {
            }
          : null,
      child: Tooltip(
        message: _buildTooltipMessage(date),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: backgroundColor,
                  shape: BoxShape.circle,
                  border: borderColor != null
                      ? Border.all(color: borderColor, width: 2)
                      : null,
                  boxShadow: isToday
                      ? [
                          BoxShadow(
                            color: Colors.green.withValues(alpha: 0.3),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Text(
                      '${date.day}',
                      style: TextStyle(
                        color: textColor,
                        fontWeight:
                            isToday ? FontWeight.bold : FontWeight.w500,
                        fontSize: 16,
                      ),
                    ),
                    if (hasBirthday && isInMonth)
                      Positioned(
                        bottom: 2,
                        child: Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.pink[400],
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              if (isInMonth)
                SizedBox(
                  height: 6,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (hasLeave && !isWeekend && !isHoliday)
                        Container(
                          width: 5,
                          height: 5,
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          decoration: BoxDecoration(
                            color: Colors.orange[600],
                            shape: BoxShape.circle,
                          ),
                        ),
                      if (hasShortHours)
                        Container(
                          width: 5,
                          height: 5,
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          decoration: BoxDecoration(
                            color: Colors.red[600],
                            shape: BoxShape.circle,
                          ),
                        ),
                      if (hasEmployeeLeave && !isWeekend && !isHoliday)
                        Container(
                          width: 5,
                          height: 5,
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          decoration: BoxDecoration(
                            color: Colors.orange[600],
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _buildTooltipMessage(DateTime date) {
    final messages = <String>[];

    if (_hasBirthday(date)) {
      messages.add("🎂 ${_getBirthdayInfo(date)}'s birthday");
    }

    if (_isHoliday(date)) {
      messages.add("🎉 ${_getHolidayInfo(date)}");
    }

    final empLeaveInfo = _getEmployeeLeaveInfo(date);
    if (empLeaveInfo.isNotEmpty && !_isWeekend(date)) {
      for (var leave in empLeaveInfo) {
        final name = leave['name'] ?? '';
        final reason = leave['leavereason'] ?? '';
        final leaveDay = leave['leaveday'] ?? '';
        final leaveCount = leave['leave_count'];

        String leaveText = '📅 $name';
        if (leaveCount != null && leaveCount != 0) {
          leaveText += ' ($leaveCount)';
        }
        if (leaveDay.isNotEmpty) {
          leaveText += ' - ${leaveDay.toUpperCase()}';
        }
        if (reason.isNotEmpty) {
          leaveText += '\n   $reason';
        }
        messages.add(leaveText);
      }
    }

    if (_hasShortWorkHours(date)) {
      messages.add("⚠️ Less Attendance");
    }

    return messages.isEmpty ? '' : messages.join('\n\n');
  }

  Widget _buildLegend() {
    final birthdayCount = widget.birthdays?.length ?? 0;
    final holidayCount = widget.holidays?.length ?? 0;
    final empLeaveCount = widget.employeeLeaves?.length ?? 0;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
        border: Border(top: BorderSide(color: Colors.grey.shade200, width: 1)),
      ),
      child: Column(
        children: [
          Wrap(
            spacing: 20,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              _buildLegendItem(Colors.green[600]!, 'Today'),
              _buildLegendItem(Colors.red[600]!, 'Less Attendance'),
              _buildLegendItem(Colors.orange[600]!, 'Leave'),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Tap on date to see details of that date.',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[500],
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
          if (birthdayCount > 0 || holidayCount > 0 || empLeaveCount > 0)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Text(
                  'Data loaded: $birthdayCount birthdays, $holidayCount holidays, $empLeaveCount employee leaves',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.blue[800],
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

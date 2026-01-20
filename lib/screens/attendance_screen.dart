import 'package:custom_date_range_picker/custom_date_range_picker.dart';
import 'package:dashboard_clone/constants/constants.dart';
import 'package:dashboard_clone/screens/dashboard_screen.dart';
// import 'package:rsw_portal/constants/constants.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/attendance_service.dart';
import 'attendance_detail_screen.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  DateTimeRange? _selectedDateRange;
  late TextEditingController _dateController;
  List<Map<String, dynamic>> _attendanceData = [];
  bool _isLoading = false;
  int _entriesPerPage = 25;

  @override
  void initState() {
    super.initState();
    _dateController = TextEditingController();
    _updateDateText();
    _loadAttendanceData();
  }

  @override
  void dispose() {
    _dateController.dispose();
    super.dispose();
  }

  void _updateDateText() {
    if (_selectedDateRange != null) {
      _dateController.text =
      '${DateFormat('dd/MM/yyyy').format(_selectedDateRange!.start)} - ${DateFormat('dd/MM/yyyy').format(_selectedDateRange!.end)}';
    } else {
      _dateController.text = '';
    }
  }

  Future<void> _loadAttendanceData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      String? startDate;
      String? endDate;

      if (_selectedDateRange != null) {
        startDate = DateFormat('yyyy-MM-dd').format(_selectedDateRange!.start);
        endDate = DateFormat('yyyy-MM-dd').format(_selectedDateRange!.end);
      }

      final response = await AttendanceService.fetchAttendanceData(
        startDate: startDate,
        endDate: endDate,
      );

      if (response != null && response['success'] == true) {
        final data = response['data']['data'] as List;
        setState(() {
          _attendanceData = data.cast<Map<String, dynamic>>();
        });
      }
    } catch (e) {
      print('Error loading attendance data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading attendance data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _openDatePicker() {
    showCustomDateRangePicker(
      context,
      dismissible: true,
      maximumDate: DateTime.now().add(const Duration(days: 365)),
      minimumDate: DateTime.now().subtract(const Duration(days: 365)),
      primaryColor: primaryColor,
      backgroundColor: Colors.white,
      startDate: _selectedDateRange?.start,
      endDate: _selectedDateRange?.end,
      onApplyClick: (DateTime startDate, DateTime endDate) {
        setState(() {
          _selectedDateRange = DateTimeRange(start: startDate, end: endDate);
          _updateDateText();
        });
      },
      onCancelClick: () {
      },
    );
  }



  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    final s = d.inSeconds % 60;
    return "${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
  }

  Color _getTotalTimeColor(Duration duration) {
    if (duration.inHours < 4) return Colors.red[100]!;
    return Colors.green[100]!;
  }

  double _calculateTableWidth(bool isMobile) {
    if (isMobile) {
      return 120 + 80 + 80 + 100 + 100 + 80;
    } else {
      return double.infinity;
    }
  }

  Widget _buildAdvancedTable(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    bool isMobile = screenWidth < 600;

    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.all(40),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_attendanceData.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        child: Center(
          child: Text(
            'No attendance records found',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
      );
    }

    final tableContent = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildTableHeader(isMobile),
        ...List.generate(
          _attendanceData.length,
              (index) => _buildTableRow(context, index, isMobile),
        ),
      ],
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: isMobile
          ? SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: _calculateTableWidth(isMobile),
          ),
          child: tableContent,
        ),
      )
          : tableContent,
    );
  }

  Widget _buildTableHeader(bool isMobile) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
      ),
      child: isMobile
          ? Row(
        children: [
          _buildHeaderCell("Dates", width: 120),
          _buildHeaderCell("In", width: 80),
          _buildHeaderCell("Out", width: 80),
          _buildHeaderCell("Total Time", width: 100),
          _buildHeaderCell("Total Break", width: 100),
          _buildHeaderCell("Action", width: 80),
        ],
      )
          : Row(
        children: [
          Expanded(flex: 3, child: _buildFlexHeaderCell("Dates")),
          Expanded(flex: 2, child: _buildFlexHeaderCell("In")),
          Expanded(flex: 2, child: _buildFlexHeaderCell("Out")),
          Expanded(flex: 2, child: _buildFlexHeaderCell("Total Time")),
          Expanded(flex: 2, child: _buildFlexHeaderCell("Total Break")),
          Expanded(flex: 2, child: _buildFlexHeaderCell("Action")),
        ],
      ),
    );
  }

  Widget _buildFlexHeaderCell(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: Colors.grey[700],
        ),
      ),
    );
  }

  Widget _buildHeaderCell(String title, {required double width}) {
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Colors.grey[700],
          ),
        ),
      ),
    );
  }

  Widget _buildDataCell(Widget child, {required double width}) {
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        alignment: Alignment.centerLeft,
        child: child,
      ),
    );
  }

  Duration _parseDuration(String duration) {
    try {
      final parts = duration.split(':');
      return Duration(
        hours: int.parse(parts[0]),
        minutes: int.parse(parts[1]),
        seconds: int.parse(parts[2]),
      );
    } catch (e) {
      return Duration.zero;
    }
  }

  Widget _buildTableRow(BuildContext context, int index, bool isMobile) {
    final record = _attendanceData[index];
    final date = DateTime.parse(record['date']);
    final dayName = DateFormat('EEEE').format(date);
    final dateString = DateFormat('dd/MM/yyyy').format(date);
    final inTime = record['intime'] ?? '-';
    final outTime = record['outtime'] ?? '-';
    final totalTime = _parseDuration(record['totaltime'] ?? '00:00:00');
    final totalBreak = _parseDuration(record['total_break'] ?? '00:00:00');

    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: index % 2 == 0 ? Colors.white : Colors.grey[50],
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: isMobile
          ? Row(
        children: [
          _buildDataCell(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  dateString,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  dayName,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
            width: 120,
          ),
          _buildDataCell(
            Text(
              inTime,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            width: 80,
          ),
          _buildDataCell(
            Text(
              outTime,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            width: 80,
          ),
          _buildDataCell(
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: _getTotalTimeColor(totalTime),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Text(
                _formatDuration(totalTime),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  color: _getTotalTimeColor(totalTime) ==
                      Colors.red[100]
                      ? Colors.red[800]
                      : Colors.green[800],
                ),
              ),
            ),
            width: 100,
          ),
          _buildDataCell(
            Text(
              _formatDuration(totalBreak),
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 13,
                fontWeight: FontWeight.w400,
              ),
            ),
            width: 100,
          ),
          _buildDataCell(
            IconButton(
              icon: Icon(
                Icons.remove_red_eye_rounded,
                color: primaryColor1,
                size: 18,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        AttendanceDetailScreen(
                          date: date,
                          attendanceData: record,
                        ),
                  ),
                );
              },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            width: 80,
          ),
        ],
      )
          : Row(
        children: [
          Expanded(
            flex: 3,
            child: _buildFlexDataCell(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    dateString,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dayName,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: _buildFlexDataCell(
              Text(
                inTime,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: _buildFlexDataCell(
              Text(
                outTime,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: _buildFlexDataCell(
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _getTotalTimeColor(totalTime),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  _formatDuration(totalTime),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: _getTotalTimeColor(totalTime) ==
                        Colors.red[100]
                        ? Colors.red[800]
                        : Colors.green[800],
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: _buildFlexDataCell(
              Text(
                _formatDuration(totalBreak),
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: _buildFlexDataCell(
              IconButton(
                icon: Icon(
                  Icons.remove_red_eye_rounded,
                  color: primaryColor1,
                  size: 20,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          AttendanceDetailScreen(
                            date: date,
                            attendanceData: record,
                          ),
                    ),
                  );
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlexDataCell(Widget child) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      alignment: Alignment.centerLeft,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[50],
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Text(
                    'Attendance',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: () {
                      // Navigator.pop(context);
                      // Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => DashboardScreen(),));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: backButtonColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    child: const Text('Back', style: TextStyle(fontSize: 15)),
                  ),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.1),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      decoration: InputDecoration(
                        label: Text('Select date range'),
                        labelStyle: TextStyle(color: Colors.grey[500]),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: primaryColor),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        suffixIcon: IconButton(
                          onPressed: () {
                            _openDatePicker();
                          },
                          icon: Icon(
                            Icons.calendar_today_outlined,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                      controller: _dateController,
                      readOnly: true,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        if (MediaQuery.of(context).size.width > 600) ...[
                          SizedBox(
                            width: 120,
                            child: ElevatedButton(
                              onPressed: _loadAttendanceData,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: const Text(
                                'Submit',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          SizedBox(
                            width: 120,
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _selectedDateRange = null;
                                  _updateDateText();
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: backButtonColor,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: const Text(
                                'Reset',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ] else ...[
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _loadAttendanceData,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: const Text(
                                'Submit',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _selectedDateRange = null;
                                  _updateDateText();
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: backButtonColor,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: const Text(
                                'Reset',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.1),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Text(
                              "Show",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: DropdownButton<int>(
                                dropdownColor: Colors.white,
                                 borderRadius: BorderRadius.circular(10),
                                value: _entriesPerPage,
                                underline: Container(),
                                items: [25, 50, 100].map((e) {
                                  return DropdownMenuItem<int>(
                                    value: e,
                                    child: Text(
                                      e.toString(),
                                      style: TextStyle(fontSize: 14),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (v) =>
                                    setState(() => _entriesPerPage = v!),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "entries",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          decoration: InputDecoration(
                            prefixIcon: Icon(
                              Icons.search,
                              size: 20,
                              color: Colors.grey[500],
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: primaryColor),
                            ),
                            hintText: 'Search',
                            hintStyle: TextStyle(color: Colors.grey[500]),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildAdvancedTable(context),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
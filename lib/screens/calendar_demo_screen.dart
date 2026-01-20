import 'package:flutter/material.dart';
import 'test_calender.dart';
import '../services/general_calendar_service.dart';

class CalendarDemoScreen extends StatefulWidget {
  const CalendarDemoScreen({super.key});

  @override
  State<CalendarDemoScreen> createState() => _CalendarDemoScreenState();
}

class _CalendarDemoScreenState extends State<CalendarDemoScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _calendarData;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCalendarData();
  }

  Future<void> _loadCalendarData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await GeneralCalendarService.getGeneralCalendarData();

      if (response != null && response['success'] == true) {
        setState(() {
          _calendarData = response['data'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load calendar data';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Calendar'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCalendarData,
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Dashboard Calendar',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[900],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                if (_isLoading)
                  Container(
                    height: 500,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.error_outline,
                            color: Colors.red[700], size: 48),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: Colors.red[900],
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _loadCalendarData,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red[700],
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  )
                else if (_calendarData != null)
                  TestCalender(
                    birthdays: _calendarData!['birthdays'] != null
                        ? List<Map<String, dynamic>>.from(
                            _calendarData!['birthdays'])
                        : null,
                    holidays: _calendarData!['holiday'] != null
                        ? List<Map<String, dynamic>>.from(
                            _calendarData!['holiday'])
                        : null,
                    leaves: _calendarData!['leaves'] != null
                        ? List<Map<String, dynamic>>.from(
                            _calendarData!['leaves'])
                        : null,
                    attendance: _calendarData!['attendance'] != null
                        ? List<Map<String, dynamic>>.from(
                            _calendarData!['attendance'])
                        : null,
                    employeeLeaves: _calendarData!['employeeLeaves'] != null
                        ? List<Map<String, dynamic>>.from(
                            _calendarData!['employeeLeaves'])
                        : null,
                    isAdmin: false,
                  ),
                const SizedBox(height: 24),
                if (!_isLoading && _calendarData != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.check_circle_outline,
                                color: Colors.green[700], size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Calendar Data Loaded',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green[900],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${_calendarData!['birthdays']?.length ?? 0} birthdays, '
                          '${_calendarData!['holiday']?.length ?? 0} holidays, '
                          '${_calendarData!['employeeLeaves']?.length ?? 0} employee leaves',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green[800],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

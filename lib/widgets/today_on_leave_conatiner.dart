import 'package:dashboard_clone/constants/constants.dart';
import 'package:dashboard_clone/services/general_calendar_service.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class TodayLeaveListContainer extends StatefulWidget {
  final Function(int)? onCountChanged;
  
  const TodayLeaveListContainer({super.key, this.onCountChanged});

  @override
  State<TodayLeaveListContainer> createState() =>
      _TodayLeaveListContainerState();
}

class _TodayLeaveListContainerState extends State<TodayLeaveListContainer> {
  var _todayLeaveData = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTodayLeaveData();
  }

  Future<void> _loadTodayLeaveData() async {
    try {
      final result = await GeneralCalendarService.getGeneralCalendarData();
      if (mounted) {
        print('=== Today Leave Container Debug ===');
        print('API Success: ${result?['success']}');
        
        if (result?['data'] != null) {
          final data = result!['data'] as Map<String, dynamic>;
          print('Available data keys: ${data.keys.toList()}');
          
          // Try different possible field names
          final allLeaves = data['employeeLeaves'] ?? 
                           data['employee_leaves'] ?? 
                           data['leaves'] ?? 
                           data['leave'] ?? [];
          
          print('All leaves type: ${allLeaves.runtimeType}');
          print('All leaves count: ${allLeaves.length}');
          
          if (allLeaves.isNotEmpty) {
            print('First leave item: ${allLeaves[0]}');
          }
          
          final today = DateTime.now();
          print('Today date: ${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}');
          
          // Filter leaves to only show today's date and flatten the structure
          final List<Map<String, dynamic>> flattenedLeaves = [];
          
          for (var leave in allLeaves as List) {
            final leaveDate = leave['date'] ?? '';
            if (leaveDate.isEmpty) continue;
            
            try {
              // Parse the date from API (format: yyyy-MM-dd or dd/MM/yyyy)
              DateTime parsedDate;
              if (leaveDate.contains('-')) {
                parsedDate = DateTime.parse(leaveDate);
              } else if (leaveDate.contains('/')) {
                final parts = leaveDate.split('/');
                parsedDate = DateTime(
                  int.parse(parts[2]),
                  int.parse(parts[1]),
                  int.parse(parts[0]),
                );
              } else {
                continue;
              }
              
              // Check if this is today's date
              if (parsedDate.year == today.year &&
                  parsedDate.month == today.month &&
                  parsedDate.day == today.day) {
                
                // Get all employees on leave for this date
                final leaveInfo = leave['leave_info'] ?? [];
                
                // Create a separate entry for each employee
                for (var employee in leaveInfo) {
                  flattenedLeaves.add({
                    'date': leaveDate,
                    'name': employee['name'] ?? '',
                    'leavereason': employee['leavereason'] ?? '',
                    'leaveday': employee['leaveday'] ?? '',
                    'leave_count': employee['leave_count'] ?? '',
                  });
                }
              }
            } catch (e) {
              print('Error parsing leave date: $e');
              continue;
            }
          }

          print('Total employees on leave today: ${flattenedLeaves.length}');
          if (flattenedLeaves.isNotEmpty) {
            print('First employee: ${flattenedLeaves[0]}');
          }

          setState(() {
            _todayLeaveData = flattenedLeaves;
            _isLoading = false;
          });
          
          // Notify parent about the count
          widget.onCountChanged?.call(flattenedLeaves.length);
        } else {
          print('No data field in API response');
          setState(() {
            _todayLeaveData = [];
            _isLoading = false;
          });
        }
      }
    } catch (e, stackTrace) {
      print('Error loading today leave data: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _todayLeaveData = [];
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _todayLeaveData.isEmpty ? SizedBox(height: 0,) : Container(
      margin: const EdgeInsets.only(left: 20, right: 20, top: 0),
      constraints: const BoxConstraints(maxHeight: 400),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 70,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
            ),
            child: Center(
              child: Text(
                'Today On Leave',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? ListView.separated(
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: 3,
                    separatorBuilder: (context, index) =>
                        Divider(height: 1, color: Colors.grey[300]),
                    itemBuilder: (context, index) => Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.grey[100]!,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 150,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    width: 200,
                                    height: 14,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                : _todayLeaveData.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(20),
                    child: Center(
                      child: Text(
                        'No one is on leave today',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  )
                : ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: _todayLeaveData.length,
                    separatorBuilder: (context, index) =>
                        Divider(height: 1, color: Colors.grey[300]),
                    itemBuilder: (context, index) {
                      final employee = _todayLeaveData[index];
                      final date = employee['date'] ?? '';
                      final name = employee['name'] ?? '';
                      final leaveReason = employee['leavereason'] ?? '';
                      final leaveDay = employee['leaveday'] ?? '';
                      final leaveCount = employee['leave_count'] ?? '';

                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.red.shade100,
                              child: Text(
                                name.isNotEmpty ? name[0].toUpperCase() : 'N',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      Text(
                                        ' ($leaveDay)',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      Text(
                                        ' ($leaveCount)',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    leaveReason,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    date,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

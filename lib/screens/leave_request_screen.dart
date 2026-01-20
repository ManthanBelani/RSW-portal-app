import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import '../constants/constants.dart';
import '../services/leave_request_service.dart';
import '../services/project_list_user_service.dart';
import '../services/crud_leave_service.dart';
import '../widgets/reusable_data_table.dart';
import '../widgets/searchable_dropdown.dart';
import 'add_leave_screen.dart';

class LeaveRequestScreen extends StatefulWidget {
  const LeaveRequestScreen({super.key});

  @override
  State<LeaveRequestScreen> createState() => _LeaveRequestScreenState();
}

class _LeaveRequestScreenState extends State<LeaveRequestScreen> {
  @override
  void initState() {
    super.initState();
    _dateRangeController = TextEditingController();
    _searchController = TextEditingController();
    _searchController.addListener(_onSearchChanged);
    _loadDropdownData();
    getAllLeaveData();
  }

  late TextEditingController _dateRangeController;
  late TextEditingController _searchController;

  String? _selectedUser;
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _leaveData = [];
  DateTimeRange? _selectedDateRange;
  int _entriesPerPage = 50;
  int _totalRecords = 0;
  Timer? _debounceTimer;
  bool _isLoading = false;

  void _debounce(VoidCallback callback) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), callback);
  }

  Future<void> getAllLeaveData({
    String? userId,
    String? fromDate,
    String? toDate,
    String? search,
    int? perPage,
  }) async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      String? formattedFromDate;
      String? formattedToDate;

      if (_selectedDateRange != null) {
        formattedFromDate =
            '${_selectedDateRange!.start.year}-${_selectedDateRange!.start.month.toString().padLeft(2, '0')}-${_selectedDateRange!.start.day.toString().padLeft(2, '0')}';
        formattedToDate =
            '${_selectedDateRange!.end.year}-${_selectedDateRange!.end.month.toString().padLeft(2, '0')}-${_selectedDateRange!.end.day.toString().padLeft(2, '0')}';
      }

      final response = await LeaveRequestService.getLeaveRequestMainPageData(
        userId: userId ?? _selectedUser,
        fromDate: formattedFromDate,
        toDate: formattedToDate,
        search: search ?? _searchController.text,
        perPage: perPage ?? _entriesPerPage,
      );

      if (response != null && response['success'] == true) {
        final leaveList = response['data']['aaData'] as List;
        final totalRecords = response['data']['recordsTotal'] as int? ?? 0;

        if (mounted) {
          setState(() {
            _leaveData = leaveList.map((leave) {
              return {
                'id': leave['id']?.toString() ?? '',
                'userId': leave['user_id']?.toString() ?? '',
                'fromdate': leave['leavedate_from'] ?? '',
                'todate': leave['leavedate_to'] ?? '',
                'leaveday': leave['leaveday'] ?? '',
                'userName':
                    '${leave['first_name'] ?? ''} ${leave['last_name'] ?? ''} (${leave['leave_count'] ?? ''})'
                        .trim(),
                'date': leave['leavedate_from'] != null
                    ? (leave['leavedate_to'] != null
                          ? '${DateFormat('dd/MM/yyyy').format(DateTime.parse(leave['leavedate_from']))} To ${DateFormat('dd/MM/yyyy').format(DateTime.parse(leave['leavedate_to']))}'
                          : '${DateFormat('dd/MM/yyyy').format(DateTime.parse(leave['leavedate_from']))}')
                    : '',
                'reason': leave['leavereason'] ?? '',
                'leaveType': leave['leaveday'] == 'fl'
                    ? 'Full Leave'
                    : leave['leaveday'] == 'ml'
                    ? 'More Days Leave'
                    : leave['leave_type'] ?? '',
                'status': leave['status'] == 1
                    ? 'Pending'
                    : leave['status'] == 2
                    ? 'Approved'
                    : 'Rejected',
              };
            }).toList();
            _totalRecords = totalRecords;
          });
        }
      }
    } catch (e) {
      print('Error loading leave data: $e');
      if (mounted) {
        setState(() {
          _leaveData = [];
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Sample data - replace with actual API data
  // late List<Map<String, dynamic>> _leaveData = [
  //   {
  //     'userName': 'Alice Williams (6)',
  //     'date': '29/10/2027',
  //     'reason': 'vfbksdf',
  //     'leaveType': 'Full Leave',
  //     'status': 'Approved',
  //   },
  //   {
  //     'userName': 'Akshay test (-3)',
  //     'date': '02/03/2026 To 30/04/2026',
  //     'reason': 'Out Of India go on vactions',
  //     'leaveType': 'More Days Leave',
  //     'status': 'Rejected',
  //   },
  //   {
  //     'userName': 'dSophia first (2)',
  //     'date': '11/02/2026',
  //     'reason': 'marriage',
  //     'leaveType': 'Full Leave',
  //     'status': 'Approved',
  //   },
  //   {
  //     'userName': 'Olivia Martin (2)',
  //     'date': '19/01/2026 To 20/01/2026',
  //     'reason': 'BB',
  //     'leaveType': 'More Days Leave',
  //     'status': 'Rejected',
  //   },
  //   {
  //     'userName': 'Olivia Martin (2)',
  //     'date': '19/01/2026 To 20/01/2026',
  //     'reason': 'BB',
  //     'leaveType': 'More Days Leave',
  //     'status': 'Pending',
  //   },
  // ];

  Future<void> _loadDropdownData() async {
    try {
      final userResult =
          await UserListWithOutAdminService.getUserListWithOutAdmin();
      if (userResult != null && userResult['success'] == true) {
        final userList = userResult['data'] as List;
        if (mounted) {
          setState(() {
            _users = userList
                .map(
                  (u) => {
                    'id': u['id'].toString(),
                    'name': '${u['first_name'] ?? ''} ${u['last_name'] ?? ''}'
                        .trim(),
                  },
                )
                .toList();
          });
        }
      }
    } catch (e) {
      print('Error loading dropdown data: $e');
      if (mounted) {
        setState(() {
          _users = [];
        });
      }
    }
  }

  void _openDateRangePicker() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(
            context,
          ).copyWith(colorScheme: ColorScheme.light(primary: primaryColor)),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
        _dateRangeController.text =
            '${DateFormat('dd/MM/yyyy').format(picked.start)} - ${DateFormat('dd/MM/yyyy').format(picked.end)}';
      });
      getAllLeaveData();
    }
  }

  void _handleSubmit() {
    setState(() {
      getAllLeaveData();
    });
    print('Submit pressed - filters applied via API');
  }

  void _handleReset() {
    setState(() {
      _dateRangeController.clear();
      _selectedUser = null;
      _selectedDateRange = null;
      _searchController.clear();
    });
    getAllLeaveData();
  }

  Future<void> _handleApprove(Map<String, dynamic> leave) async {
    final result = await CrudLeaveService.approveUserLeave(
      context: context,
      fromdate: leave['fromdate'],
      todate: leave['todate'],
      id: leave['id'],
      userId: leave['userId'],
      leaveday: leave['leaveday'],
    );

    if (result != null && result['success'] == true) {
      await getAllLeaveData();
    }
  }

  Future<void> _handleReject(Map<String, dynamic> leave) async {
    final result = await CrudLeaveService.rejectUserLeave(
      context: context,
      fromdate: leave['fromdate'],
      todate: leave['todate'],
      id: leave['id'],
      userId: leave['userId'],
      leaveday: leave['leaveday'],
    );

    if (result != null && result['success'] == true) {
      await getAllLeaveData();
    }
  }

  Future<void> _handleDelete(Map<String, dynamic> leave) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text(
          'Are you sure you want to delete this leave request?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final result = await CrudLeaveService.deleteUserLeave(
        context: context,
        id: leave['id'],
      );

      if (result != null && result['success'] == true) {
        await getAllLeaveData();
      }
    }
  }

  Widget _buildFlexSkeletonCell({required double height, double widthFactor = 0.5}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      alignment: Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: widthFactor,
        child: Container(
          height: height,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }

  Widget _buildSkeletonRow(int index) {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: index % 2 == 0 ? Colors.white : Colors.grey[50],
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Row(
          children: [
            Expanded(flex: 2, child: _buildFlexSkeletonCell(height: 16, widthFactor: 0.8)),
            Expanded(flex: 2, child: _buildFlexSkeletonCell(height: 16, widthFactor: 0.7)),
            Expanded(flex: 2, child: _buildFlexSkeletonCell(height: 16, widthFactor: 0.9)),
            Expanded(flex: 2, child: _buildFlexSkeletonCell(height: 32, widthFactor: 0.6)),
            Expanded(flex: 1, child: _buildFlexSkeletonCell(height: 24, widthFactor: 0.8)),
            Expanded(flex: 2, child: _buildFlexSkeletonCell(height: 32, widthFactor: 0.7)),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaveTable() {
    if (_isLoading) {
      return Column(
        children: List.generate(5, (index) => _buildSkeletonRow(index)),
      );
    }

    if (_leaveData.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        child: Center(
          child: Text(
            'No leave requests found',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
        ),
      );
    }

    return Center(
      child: ReusableDataTable(
        columns: [
          TableColumnConfig(
            title: 'User Name',
            flex: 2,
            builder: (data, index) => Text(
              data['userName'],
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),
          ),
          TableColumnConfig(
            title: 'Date',
            flex: 2,
            builder: (data, index) => Text(
              data['date'],
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),
          ),
          TableColumnConfig(
            title: 'Reason',
            flex: 2,
            builder: (data, index) => Text(
              data['reason'],
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),
          ),
          TableColumnConfig(
            title: 'Leave',
            flex: 2,
            builder: (data, index) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  data['leaveType'],
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.pink[50],
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    'detail',
                    style: TextStyle(color: Colors.pink[400], fontSize: 10),
                  ),
                ),
              ],
            ),
          ),
          TableColumnConfig(
            title: 'Status',
            flex: 1,
            builder: (data, index) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: data['status'] == 'Approved'
                    ? Colors.green[50]
                    : data['status'] == 'Rejected'
                    ? Colors.grey[200]
                    : Colors.blue[50],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                data['status'],
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: data['status'] == 'Approved'
                      ? Colors.green[700]
                      : data['status'] == 'Rejected'
                      ? Colors.grey[700]
                      : Colors.blue[700],
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          TableColumnConfig(
            title: 'Action',
            flex: 2,
            builder: (data, index) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (data['status'] == 'Pending') ...[
                  TextButton(
                    onPressed: () => _handleApprove(data),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.green[600],
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      minimumSize: const Size(60, 30),
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                    child: const Text('Approve'),
                  ),
                  const SizedBox(width: 4),
                  TextButton(
                    onPressed: () => _handleReject(data),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red[600],
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      minimumSize: const Size(60, 30),
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                    child: const Text('Reject'),
                  ),
                  const SizedBox(width: 4),
                ],
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                  onPressed: () => _handleDelete(data),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 30,
                    minHeight: 30,
                  ),
                ),
              ],
            ),
          ),
        ],
        data: _leaveData,
      ),
    );
  }

  void _onSearchChanged() {
    _debounce(() {
      getAllLeaveData(search: _searchController.text);
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _dateRangeController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Container(
        color: Colors.grey[50],
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'View Leaves',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AddLeaveScreen(),
                            ),
                          );
                          if (result == true) {
                            getAllLeaveData();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF1744),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                        child: const Text(
                          '+ Add Leave',
                          style: TextStyle(fontSize: 15),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  Container(
                    padding: const EdgeInsets.all(20),
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: _dateRangeController,
                                readOnly: true,
                                decoration: InputDecoration(
                                  hintText: 'Select Date Range',
                                  hintStyle: TextStyle(color: Colors.grey[400]),
                                  filled: true,
                                  fillColor: Colors.grey.shade50,
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
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                  suffixIcon: IconButton(
                                    onPressed: _openDateRangePicker,
                                    icon: Icon(
                                      Icons.calendar_today_outlined,
                                      color: Colors.grey[600],
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: SearchableDropdown(
                                value: _selectedUser,
                                hint: 'Select User',
                                items: _users,
                                onChanged: (value) {
                                  setState(() {
                                    _selectedUser = value;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            SizedBox(
                              width: 100,
                              child: ElevatedButton(
                                onPressed: _handleSubmit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryColor,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                ),
                                child: const Text('Submit'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              width: 100,
                              child: ElevatedButton(
                                onPressed: _handleReset,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2196F3),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                ),
                                child: const Text('Reset'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(20),
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
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  'Show ',
                                  style: TextStyle(fontSize: 14),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: DropdownButton<int>(
                                    borderRadius: const BorderRadius.all(
                                      Radius.circular(10),
                                    ),
                                    dropdownColor: Colors.white,
                                    value: _entriesPerPage,
                                    underline: const SizedBox(),
                                    items: [10, 25, 50, 100]
                                        .map(
                                          (e) => DropdownMenuItem(
                                            value: e,
                                            child: Text('$e'),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        _entriesPerPage = value!;
                                      });
                                      _handleSubmit();
                                    },
                                  ),
                                ),
                                const Text(
                                  ' entries',
                                  style: TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                            Text(
                              'Total: $_totalRecords entries',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search',
                            prefixIcon: Icon(
                              Icons.search,
                              color: Colors.grey[600],
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
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
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          onChanged: (value) {
                            _debounce(() => _handleSubmit());
                          },
                        ),
                        const SizedBox(height: 20),
                        _buildLeaveTable(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

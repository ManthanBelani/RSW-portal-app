import 'package:dashboard_clone/constants/constants.dart';
import 'package:dashboard_clone/widgets/elevated_button.dart';
import 'package:dashboard_clone/widgets/searchable_dropdown.dart';
import 'package:dashboard_clone/services/task_service.dart';
import 'package:dashboard_clone/services/project_list_user_service.dart';
import 'package:dashboard_clone/services/crud_task.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import '../models/task_record.dart';
import 'add_task_screen.dart';
import 'edit_task_screen.dart';

class TaskScreen extends StatefulWidget {
  final List<bool>? permissions;
  
  const TaskScreen({super.key, this.permissions});

  @override
  State<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> {
  late TextEditingController _startDateController;
  late TextEditingController _endDateController;
  late TextEditingController _searchController;

  String? _selectedProject;
  String? _selectedUser;
  String? _selectedActiveStatus;
  String? _selectedBillableStatus;
  String? _selectedPaidStatus;

  String _totalTime = '0.00';
  int _entriesPerPage = 50;
  String _searchQuery = '';
  bool _isLoading = true;
  List<TaskRecord> records = [];

  List<Map<String, dynamic>> _projects = [];
  List<Map<String, dynamic>> _users = [];
  
  // Permission helpers [add, edit, delete, view]
  bool get _canAdd => widget.permissions != null && 
                      widget.permissions!.length > 0 && 
                      widget.permissions![0];
  bool get _canEdit => widget.permissions != null && 
                       widget.permissions!.length > 1 && 
                       widget.permissions![1];
  bool get _canDelete => widget.permissions != null && 
                         widget.permissions!.length > 2 && 
                         widget.permissions![2];
  bool get _canView => widget.permissions != null && 
                       widget.permissions!.length > 3 && 
                       widget.permissions![3];

  @override
  void initState() {
    super.initState();
    _startDateController = TextEditingController();
    _endDateController = TextEditingController();
    _searchController = TextEditingController();

    // Add listener for search - triggers API call immediately
    _searchController.addListener(() {
      if (_searchQuery != _searchController.text) {
        setState(() {
          _searchQuery = _searchController.text;
        });
        _loadTaskData(
          startDate: _startDateController.text.isNotEmpty
              ? _startDateController.text
              : null,
          endDate: _endDateController.text.isNotEmpty
              ? _endDateController.text
              : null,
        );
      }
    });

    _loadDropdownData();
    _loadTaskData();
  }

  Future<void> _loadDropdownData() async {
    try {
      // Load projects
      final projectResult = await ProjectListUserService.getProjectList();
      if (projectResult != null && projectResult['success'] == true) {
        final projectList = projectResult['data'] as List;
        if (mounted) {
          setState(() {
            _projects = projectList
                .map(
                  (p) => {
                    'id': p['id'].toString(),
                    'name': p['project_name'] ?? '',
                  },
                )
                .toList();
          });
        }
      }

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
          _projects = [];
          _users = [];
        });
      }
    }
  }

  Future<void> _loadTaskData({String? startDate, String? endDate}) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await TaskService.getTaskList(
        startDate: startDate,
        endDate: endDate,
        projectId: _selectedProject,
        userId: _selectedUser,
        active: _selectedActiveStatus == 'Active'
            ? '0'
            : _selectedActiveStatus == 'In-Active'
            ? '1'
            : null,
        billable: _selectedBillableStatus == 'Billable'
            ? '1'
            : _selectedBillableStatus == 'Non-billable'
            ? '2'
            : null,
        paid: _selectedPaidStatus == 'Paid'
            ? '2'
            : _selectedPaidStatus == 'Unpaid'
            ? '1'
            : null,
        search: _searchQuery,
        perPage: _entriesPerPage,
      );

      if (result != null && result['success'] == true) {
        final data = result['data'];
        final taskList = data['data'] as List;
        final totalTime = data['total_time']?.toString() ?? '0.00';

        if (mounted) {
          setState(() {
            records = taskList.map((task) {
              final dateParts = (task['date'] ?? '').split('/');
              DateTime taskDate = DateTime.now();
              if (dateParts.length == 3) {
                taskDate = DateTime(
                  int.parse(dateParts[2]),
                  int.parse(dateParts[1]),
                  int.parse(dateParts[0]),
                );
              }

              DateTime createdDate = DateTime.now();
              try {
                createdDate = DateTime.parse(task['created_at'] ?? '');
              } catch (e) {
                print('Error parsing created_at: $e');
              }

              return TaskRecord(
                id: task['id']?.toString() ?? '',
                date: taskDate,
                createdDate: createdDate,
                time: task['hours']?.toString() ?? '0',
                note: task['note'] ?? '',
                project: task['project'] ?? '',
                user: '${task['first_name'] ?? ''} ${task['last_name'] ?? ''}',
                username: task['username']?.toString() ?? '',
                action: 'View',
                rawData: task,
              );
            }).toList();
            _totalTime = totalTime;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            records = [];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error loading task data: $e');
      if (mounted) {
        setState(() {
          records = [];
          _totalTime = '0.00';
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _startDateController.dispose();
    _endDateController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _openStartDatePicker() {
    showDatePicker(
      context: context,
      initialDate: DateTime.now(),
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
    ).then((selectedDate) {
      if (selectedDate != null) {
        setState(() {
          _startDateController.text = DateFormat(
            'dd/MM/yyyy',
          ).format(selectedDate);
        });
      }
    });
  }

  void _openEndDatePicker() {
    showDatePicker(
      context: context,
      initialDate: DateTime.now(),
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
    ).then((selectedDate) {
      if (selectedDate != null) {
        setState(() {
          _endDateController.text = DateFormat(
            'dd/MM/yyyy',
          ).format(selectedDate);
        });
      }
    });
  }

  bool get hasFiltersSelected {
    return _startDateController.text.isNotEmpty ||
        _endDateController.text.isNotEmpty ||
        _selectedProject != null ||
        _selectedUser != null ||
        _selectedActiveStatus != null ||
        _selectedBillableStatus != null ||
        _selectedPaidStatus != null ||
        _searchQuery.isNotEmpty;
  }

  List<TaskRecord> get filteredRecords {
    return records;
  }

  void _handleReset() {
    setState(() {
      _startDateController.clear();
      _endDateController.clear();
      _searchController.clear();
      _searchQuery = '';
      _selectedProject = null;
      _selectedUser = null;
      _selectedActiveStatus = null;
      _selectedBillableStatus = null;
      _selectedPaidStatus = null;
    });
    _loadTaskData();
  }

  void _handleSubmit() {
    String? startDate = _startDateController.text.isNotEmpty
        ? _startDateController.text
        : null;
    String? endDate = _endDateController.text.isNotEmpty
        ? _endDateController.text
        : null;

    print('=== Submit Clicked ===');
    print('Start Date: $startDate');
    print('End Date: $endDate');
    print('Selected Project: $_selectedProject');
    print('Selected User: $_selectedUser');
    print('Selected Active Status: $_selectedActiveStatus');
    print('Selected Billable Status: $_selectedBillableStatus');
    print('Selected Paid Status: $_selectedPaidStatus');

    // Load data with all current filter values
    _loadTaskData(startDate: startDate, endDate: endDate);
  }

  void _handleYesterday() {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    setState(() {
      _startDateController.text = DateFormat('dd/MM/yyyy').format(yesterday);
      _endDateController.text = DateFormat('dd/MM/yyyy').format(yesterday);
    });
  }

  void _showDeleteDialog(String taskId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: const Text(
            'Delete Task',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          content: const Text(
            'Are you sure you want to delete this task?',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: ReusableButton(
                    text: 'Cancel',
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    backgroundColor: Colors.grey,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ReusableButton(
                    text: 'Delete',
                    onPressed: () async {
                      Navigator.of(context).pop();
                      await _deleteTask(taskId);
                    },
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteTask(String taskId) async {
    try {
      final result = await CRUDForTask.deleteTask(taskId);

      if (result != null && result['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Task deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
          // Reload task data
          _loadTaskData(
            startDate: _startDateController.text.isNotEmpty
                ? _startDateController.text
                : null,
            endDate: _endDateController.text.isNotEmpty
                ? _endDateController.text
                : null,
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result?['message'] ?? 'Failed to delete task'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  InputDecoration _buildDropdownDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[400]),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: primaryColor),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  double _calculateTableWidth(bool isMobile) {
    if (isMobile) {
      return 80 + 300 + 120 + 100 + 100 + 80 + 120 + 100;
    } else {
      return double.infinity;
    }
  }

  Widget _buildAdvancedTable(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    bool isMobile = screenWidth < 600;

    final tableContent = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildTableHeader(isMobile),
        if (_isLoading)
          ...List.generate(
            5, // Show 5 skeleton rows while loading
            (index) => _buildSkeletonRow(isMobile, index),
          )
        else
          ...List.generate(
            filteredRecords.length,
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

  Widget _buildSkeletonRow(bool isMobile, int index) {
    return Container(
      decoration: BoxDecoration(
        color: index % 2 == 0 ? Colors.white : Colors.grey[50],
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: isMobile
            ? Row(
                children: [
                  _buildSkeletonCell(width: 80, height: 16),
                  _buildSkeletonCell(width: 80, height: 16),
                  _buildSkeletonCell(width: 300, height: 40),
                  _buildSkeletonCell(width: 120, height: 16),
                  _buildSkeletonCell(width: 100, height: 16),
                  _buildSkeletonCell(width: 100, height: 16),
                  _buildSkeletonCell(width: 120, height: 32),
                  _buildSkeletonCell(width: 100, height: 16),
                ],
              )
            : IntrinsicHeight(
                child: Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: _buildFlexSkeletonCell(height: 16),
                    ),
                    Expanded(
                      flex: 1,
                      child: _buildFlexSkeletonCell(height: 16),
                    ),
                    Expanded(
                      flex: 4,
                      child: _buildFlexSkeletonCell(height: 40),
                    ),
                    Expanded(
                      flex: 2,
                      child: _buildFlexSkeletonCell(height: 16),
                    ),
                    Expanded(
                      flex: 2,
                      child: _buildFlexSkeletonCell(height: 16),
                    ),
                    Expanded(
                      flex: 2,
                      child: _buildFlexSkeletonCell(height: 16),
                    ),
                    Expanded(
                      flex: 2,
                      child: _buildFlexSkeletonCell(height: 32),
                    ),
                    Expanded(
                      flex: 1,
                      child: _buildFlexSkeletonCell(height: 16),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildSkeletonCell({required double width, required double height}) {
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        alignment: Alignment.centerLeft,
        child: Container(
          width: width * 0.7,
          height: height,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }

  Widget _buildFlexSkeletonCell({required double height}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      alignment: Alignment.centerLeft,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
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
                _buildHeaderCell("Time", width: 80),
                _buildHeaderCell("Status", width: 80),
                _buildHeaderCell("Note", width: 300),
                _buildHeaderCell("Project", width: 120),
                _buildHeaderCell("User", width: 100),
                _buildHeaderCell("Date", width: 100),
                _buildHeaderCell("Created Date", width: 120),
                _buildHeaderCell("Action", width: 100),
              ],
            )
          : Row(
              children: [
                Expanded(flex: 1, child: _buildFlexHeaderCell("Time")),
                Expanded(flex: 1, child: _buildFlexHeaderCell("Status")),
                Expanded(flex: 4, child: _buildFlexHeaderCell("Note")),
                Expanded(flex: 2, child: _buildFlexHeaderCell("Project")),
                Expanded(flex: 2, child: _buildFlexHeaderCell("User")),
                Expanded(flex: 2, child: _buildFlexHeaderCell("Date")),
                Expanded(flex: 2, child: _buildFlexHeaderCell("Created Date")),
                Expanded(flex: 1, child: _buildFlexHeaderCell("Action")),
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

  Widget _buildStatusChips(Map<String, dynamic> taskData) {
    final pay = taskData['pay']?.toString() ?? '';
    final active = taskData['active']?.toString() ?? '';

    List<Widget> chips = [];

    if (pay == '2' && active == '0') {
      chips.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFECF8F2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            'P',
            style: TextStyle(
              color: Color(0xFF0080FF),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
      chips.add(const SizedBox(width: 4));
      chips.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFECF8F2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            'A',
            style: TextStyle(
              color: Color(0xFF22AB55),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    } else if (pay == '2' && active == '1') {
      chips.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFECF8F2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            'P',
            style: TextStyle(
              color: Color(0xFF0080FF),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    } else if (pay == '1' && active == '0') {
      chips.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFECF8F2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            'A',
            style: TextStyle(
              color: Color(0xFF22AB55),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    return Row(mainAxisSize: MainAxisSize.min, children: chips);
  }

  Widget _buildTableRow(BuildContext context, int index, bool isMobile) {
    final record = filteredRecords[index];
    final dateString = DateFormat('dd/MM/yyyy').format(record.date);
    final createdDateString = DateFormat(
      'dd/MM/yyyy\nHH:mm a',
    ).format(record.createdDate);

    return Container(
      decoration: BoxDecoration(
        color: index % 2 == 0 ? Colors.white : Colors.grey[50],
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: isMobile
          ? Row(
              children: [
                _buildDataCell(
                  Text(
                    record.time,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  width: 80,
                ),
                _buildDataCell(_buildStatusChips(record.rawData), width: 80),
                _buildDataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      record.note,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black87,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  width: 300,
                ),
                _buildDataCell(
                  Text(
                    record.project,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  width: 120,
                ),
                _buildDataCell(
                  Text(
                    record.user,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  width: 100,
                ),
                _buildDataCell(
                  Text(
                    dateString,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  width: 100,
                ),
                _buildDataCell(
                  Text(
                    createdDateString,
                    style: const TextStyle(fontSize: 11, color: Colors.black87),
                    textAlign: TextAlign.center,
                  ),
                  width: 120,
                ),
                _buildDataCell(
                  SizedBox(
                    width: 80,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_canEdit)
                          InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => EditTaskScreen(
                                    taskId: record.id,
                                    taskData: record.rawData,
                                  ),
                                ),
                              ).then((_) {
                                // Reload data after returning from edit
                                _loadTaskData(
                                  startDate:
                                      _startDateController
                                          .text
                                          .isNotEmpty
                                      ? _startDateController.text
                                      : null,
                                  endDate:
                                      _endDateController.text.isNotEmpty
                                      ? _endDateController.text
                                      : null,
                                );
                              });
                            },
                            child: Icon(
                              Icons.edit,
                              color: Colors.green,
                              size: 18,
                            ),
                          ),
                        if (_canEdit && _canDelete)
                          const SizedBox(width: 12),
                        if (_canDelete)
                          InkWell(
                            onTap: () {
                              _showDeleteDialog(record.id);
                            },
                            child: Icon(
                              Icons.delete,
                              color: Colors.red,
                              size: 18,
                            ),
                          ),
                      ],
                    ),
                  ),
                  width: 100,
                ),
              ],
            )
          : IntrinsicHeight(
              child: Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: _buildFlexDataCell(
                      Text(
                        record.time,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: _buildFlexDataCell(
                      _buildStatusChips(record.rawData),
                    ),
                  ),
                  Expanded(
                    flex: 4,
                    child: _buildFlexDataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          record.note,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: _buildFlexDataCell(
                      Text(
                        record.project,
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
                        record.user,
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
                        dateString,
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
                        createdDateString,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: _buildFlexDataCell(
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_canEdit)
                            InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        EditTaskScreen(
                                          taskId: record.id,
                                          taskData: record.rawData,
                                        ),
                                  ),
                                ).then((_) {
                                  _loadTaskData(
                                    startDate:
                                        _startDateController
                                            .text
                                            .isNotEmpty
                                        ? _startDateController.text
                                        : null,
                                    endDate:
                                        _endDateController
                                            .text
                                            .isNotEmpty
                                        ? _endDateController.text
                                        : null,
                                  );
                                });
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Icon(
                                  Icons.edit,
                                  color: Colors.green,
                                  size: 20,
                                ),
                              ),
                            ),
                          if (_canEdit && _canDelete)
                            const SizedBox(width: 8),
                          if (_canDelete)
                            InkWell(
                              onTap: () {
                                _showDeleteDialog(record.id);
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                  size: 20,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
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
    print(
      'TaskScreen build - isLoading: $_isLoading, records: ${records.length}',
    );
    return Container(
      color: Colors.grey[50],
      child: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'View Tasks',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    if (_canAdd)
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AddTaskScreen(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
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
                          '+ Add Task',
                          style: TextStyle(fontSize: 15),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),

                // Filter Container - Single Column Layout
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
                      // Start Date
                      TextFormField(
                        controller: _startDateController,
                        readOnly: true,
                        decoration: InputDecoration(
                          hintText: 'Select Start Date',
                          hintStyle: TextStyle(color: Colors.grey[400]),
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
                            onPressed: _openStartDatePicker,
                            icon: Icon(
                              Icons.calendar_today_outlined,
                              color: Colors.grey[600],
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // End Date
                      TextFormField(
                        controller: _endDateController,
                        readOnly: true,
                        decoration: InputDecoration(
                          hintText: 'Select End Date',
                          hintStyle: TextStyle(color: Colors.grey[400]),
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
                            onPressed: _openEndDatePicker,
                            icon: Icon(
                              Icons.calendar_today_outlined,
                              color: Colors.grey[600],
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Project Dropdown (Searchable)
                      SearchableDropdown(
                        value: _selectedProject,
                        hint: 'Select Project',
                        items: _projects,
                        onChanged: (value) {
                          setState(() {
                            _selectedProject = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // User Dropdown (Searchable)
                      SearchableDropdown(
                        value: _selectedUser,
                        hint: 'Select User',
                        items: _users,
                        onChanged: (value) {
                          setState(() {
                            _selectedUser = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // Active/In-Active Dropdown
                      DropdownButtonFormField<String>(
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                        dropdownColor: Colors.white,
                        value: _selectedActiveStatus,
                        decoration: _buildDropdownDecoration(
                          'Active/In-Active',
                        ),
                        isExpanded: true,
                        items: ['Active', 'In-Active']
                            .map(
                              (e) => DropdownMenuItem<String>(
                                value: e,
                                child: Text(e),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedActiveStatus = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // Billable/Non-billable Dropdown
                      DropdownButtonFormField<String>(
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                        dropdownColor: Colors.white,
                        value: _selectedBillableStatus,
                        decoration: _buildDropdownDecoration(
                          'Billable/Non-billable',
                        ),
                        isExpanded: true,
                        items: ['Billable', 'Non-billable']
                            .map(
                              (e) => DropdownMenuItem<String>(
                                value: e,
                                child: Text(e),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedBillableStatus = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // Paid/Unpaid Dropdown
                      DropdownButtonFormField<String>(
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                        dropdownColor: Colors.white,
                        value: _selectedPaidStatus,
                        decoration: _buildDropdownDecoration('Paid/Unpaid'),
                        isExpanded: true,
                        items: ['Paid', 'Unpaid']
                            .map(
                              (e) => DropdownMenuItem<String>(
                                value: e,
                                child: Text(e),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedPaidStatus = value;
                          });
                        },
                      ),
                      const SizedBox(height: 20),

                      // Total Time
                      Center(
                        child: Text(
                          'Total Time : $_totalTime',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Buttons
                      Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: ReusableButton(
                                  text: 'Submit',
                                  onPressed: hasFiltersSelected
                                      ? _handleSubmit
                                      : null,
                                  backgroundColor: hasFiltersSelected
                                      ? primaryColor
                                      : Colors.grey,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ReusableButton(
                                  text: 'Reset',
                                  onPressed: _handleReset,
                                  backgroundColor: backButtonColor,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ReusableButton(
                              text: 'Yesterday',
                              onPressed: _handleYesterday,
                              backgroundColor: Colors.blue,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Table Section
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
                      // Show entries and Search
                      Column(
                        // mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                  borderRadius: BorderRadius.all(
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
                                    _loadTaskData(
                                      startDate:
                                          _startDateController.text.isNotEmpty
                                          ? _startDateController.text
                                          : null,
                                      endDate:
                                          _endDateController.text.isNotEmpty
                                          ? _endDateController.text
                                          : null,
                                    );
                                  },
                                ),
                              ),
                              const Text(
                                ' entries',
                                style: TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                          SizedBox(height: 10),
                          SizedBox(
                            height: 50,
                            child: TextField(
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
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Table (skeleton rows shown inside when loading)
                      _buildAdvancedTable(context),
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

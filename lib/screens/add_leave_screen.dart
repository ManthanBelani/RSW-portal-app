import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/constants.dart';
import '../widgets/searchable_dropdown.dart';
import '../services/project_list_user_service.dart';
import '../services/crud_leave_service.dart';

class AddLeaveScreen extends StatefulWidget {
  const AddLeaveScreen({super.key});

  @override
  State<AddLeaveScreen> createState() => _AddLeaveScreenState();
}

class _AddLeaveScreenState extends State<AddLeaveScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dateController = TextEditingController();
  final _reasonController = TextEditingController();

  String? _selectedUser;
  String? _selectedUserName;
  String _leaveType = 'debit';
  String _leave = 'full';
  String _halfLeaveShift = 'first'; // 'first' or 'second'
  List<Map<String, dynamic>> _users = [];
  DateTime? _selectedDate;
  DateTimeRange? _selectedDateRange;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _dateController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
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
      print('Error loading users: $e');
    }
  }

  Future<void> _selectDate() async {
    // If "More Days Leave" is selected, show date range picker
    if (_leave == 'more') {
      final DateTimeRange? picked = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2020),
        lastDate: DateTime(2030),
        initialDateRange: _selectedDateRange,
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
          _selectedDate = null;
          _dateController.text =
              '${DateFormat('dd/MM/yyyy').format(picked.start)} - ${DateFormat('dd/MM/yyyy').format(picked.end)}';
        });
      }
    } else {
      // For Half Leave and Full Leave, show single date picker
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: _selectedDate ?? DateTime.now(),
        firstDate: DateTime(2020),
        lastDate: DateTime(2030),
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
          _selectedDate = picked;
          _selectedDateRange = null;
          _dateController.text = DateFormat('dd/MM/yyyy').format(picked);
        });
      }
    }
  }

  Future<void> _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a user'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      setState(() {
        _isSubmitting = true;
      });

      try {
        // Format dates for API (yyyy-MM-dd)
        String startDate;
        String endDate;

        if (_leave == 'more' && _selectedDateRange != null) {
          startDate = DateFormat(
            'yyyy-MM-dd',
          ).format(_selectedDateRange!.start);
          endDate = DateFormat('yyyy-MM-dd').format(_selectedDateRange!.end);
        } else if (_selectedDate != null) {
          startDate = DateFormat('yyyy-MM-dd').format(_selectedDate!);
          endDate = DateFormat('yyyy-MM-dd').format(_selectedDate!);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please select a date'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() {
            _isSubmitting = false;
          });
          return;
        }

        // Map leave type to API values
        String leavedayValue;
        String leaveday1Value;

        if (_leave == 'half') {
          leavedayValue = 'hl';
          // Include shift information in the leave type description
          if (_halfLeaveShift == 'first') {
            leaveday1Value = 'First Shift Leave( Working time 3 PM -7:30 PM)';
          } else {
            leaveday1Value =
                'Second Shift Leave ( Working time 10 AM -2:30 PM)';
          }
        } else if (_leave == 'full') {
          leavedayValue = 'fl';
          leaveday1Value = 'Full Leave';
        } else {
          leavedayValue = 'ml';
          leaveday1Value = 'More Days Leave';
        }

        final result = await CrudLeaveService.addUserLeave(
          context: context,
          user_name: _selectedUserName ?? '',
          user_id: _selectedUser!,
          leave_type: _leaveType,
          leaveday: leavedayValue,
          leaveday1: leaveday1Value,
          startdate: startDate,
          enddate: endDate,
          leavereason: _reasonController.text,
        );

        if (result != null && result['success'] == true) {
          // Navigate back to leave request screen
          if (mounted) {
            Navigator.of(context).pop(true); // Return true to indicate success
          }
        }
      } catch (e) {
        print('Error submitting leave: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isSubmitting = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
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
                      'Add Leave',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2196F3),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 12,
                        ),
                      ),
                      child: const Text('Back', style: TextStyle(fontSize: 15)),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Form Container
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // User Name
                        _buildFormRow(
                          label: 'User Name',
                          child: SearchableDropdown(
                            value: _selectedUser,
                            hint: 'User Name',
                            items: _users,
                            onChanged: (value) {
                              setState(() {
                                _selectedUser = value;
                                if (value != null) {
                                  final user = _users.firstWhere(
                                    (u) => u['id'] == value,
                                    orElse: () => {},
                                  );
                                  _selectedUserName = user['name'] ?? '';
                                }
                              });
                            },
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Leave Type
                        _buildFormRow(
                          label: 'Leave Type',
                          child: Column(
                            children: [
                              RadioListTile<String>(
                                title: const Text(
                                  'Credit Leave',
                                  style: TextStyle(fontSize: 14),
                                ),
                                value: 'credit',
                                groupValue: _leaveType,
                                onChanged: (value) {
                                  setState(() {
                                    _leaveType = value!;
                                  });
                                },
                                contentPadding: EdgeInsets.zero,
                                activeColor: Colors.pink,
                                visualDensity: VisualDensity.compact,
                              ),
                              RadioListTile<String>(
                                title: const Text(
                                  'Debit Leave',
                                  style: TextStyle(fontSize: 14),
                                ),
                                value: 'debit',
                                groupValue: _leaveType,
                                onChanged: (value) {
                                  setState(() {
                                    _leaveType = value!;
                                  });
                                },
                                contentPadding: EdgeInsets.zero,
                                visualDensity: VisualDensity.compact,
                                activeColor: Colors.pink,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Leave
                        _buildFormRow(
                          label: 'Leave',
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: RadioListTile<String>(
                                      title: const Text(
                                        'Half Leave',
                                        style: TextStyle(fontSize: 14),
                                      ),
                                      value: 'half',
                                      groupValue: _leave,
                                      onChanged: (value) {
                                        setState(() {
                                          _leave = value!;
                                          // Clear date when switching leave type
                                          _dateController.clear();
                                          _selectedDate = null;
                                          _selectedDateRange = null;
                                        });
                                      },
                                      contentPadding: EdgeInsets.zero,
                                      visualDensity: VisualDensity.compact,
                                      activeColor: Colors.pink,
                                    ),
                                  ),
                                  Expanded(
                                    child: RadioListTile<String>(
                                      title: const Text(
                                        'Full Leave',
                                        style: TextStyle(fontSize: 14),
                                      ),
                                      value: 'full',
                                      groupValue: _leave,
                                      onChanged: (value) {
                                        setState(() {
                                          _leave = value!;
                                          // Clear date when switching leave type
                                          _dateController.clear();
                                          _selectedDate = null;
                                          _selectedDateRange = null;
                                        });
                                      },
                                      contentPadding: EdgeInsets.zero,
                                      visualDensity: VisualDensity.compact,
                                      activeColor: Colors.pink,
                                    ),
                                  ),
                                ],
                              ),
                              RadioListTile<String>(
                                title: const Text(
                                  'More Days Leave',
                                  style: TextStyle(fontSize: 14),
                                ),
                                value: 'more',
                                groupValue: _leave,
                                onChanged: (value) {
                                  setState(() {
                                    _leave = value!;
                                    // Clear date when switching leave type
                                    _dateController.clear();
                                    _selectedDate = null;
                                    _selectedDateRange = null;
                                  });
                                },
                                contentPadding: EdgeInsets.zero,
                                activeColor: Colors.pink,
                                visualDensity: VisualDensity.compact,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // My Unavailability (only show when Half Leave is selected)
                        if (_leave == 'half')
                          _buildFormRow(
                            label: 'My Unavailability',
                            child: Column(
                              children: [
                                RadioListTile<String>(
                                  title: const Text(
                                    'First Shift Leave( Working time 3 PM -7:30 PM)',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                  value: 'first',
                                  groupValue: _halfLeaveShift,
                                  onChanged: (value) {
                                    setState(() {
                                      _halfLeaveShift = value!;
                                    });
                                  },
                                  contentPadding: EdgeInsets.zero,
                                  visualDensity: VisualDensity.compact,
                                  activeColor: Colors.pink,
                                ),
                                RadioListTile<String>(
                                  title: const Text(
                                    'Second Shift Leave ( Working time 10 AM -2:30 PM)',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                  value: 'second',
                                  groupValue: _halfLeaveShift,
                                  onChanged: (value) {
                                    setState(() {
                                      _halfLeaveShift = value!;
                                    });
                                  },
                                  contentPadding: EdgeInsets.zero,
                                  visualDensity: VisualDensity.compact,
                                  activeColor: Colors.pink,
                                ),
                              ],
                            ),
                          ),
                        if (_leave == 'half') const SizedBox(height: 24),

                        // Select Date
                        _buildFormRow(
                          label: 'Select Date',
                          child: TextFormField(
                            controller: _dateController,
                            readOnly: true,
                            decoration: InputDecoration(
                              hintText: _leave == 'more'
                                  ? 'DD/MM/YYYY - DD/MM/YYYY'
                                  : 'DD/MM/YYYY',
                              hintStyle: TextStyle(color: Colors.grey[400]),
                              filled: true,
                              fillColor: Colors.grey[50],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
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
                                onPressed: _selectDate,
                                icon: Icon(
                                  Icons.calendar_today_outlined,
                                  color: Colors.grey[600],
                                  size: 20,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please select a date';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Leave Reason
                        _buildFormRow(
                          label: 'Leave Reason',
                          child: TextFormField(
                            controller: _reasonController,
                            maxLines: 3,
                            decoration: InputDecoration(
                              hintText: 'Leave reason',
                              hintStyle: TextStyle(color: Colors.grey[400]),
                              filled: true,
                              fillColor: Colors.grey[50],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
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
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter leave reason';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Submit Button
                SizedBox(
                  width: 180,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isSubmitting
                          ? Colors.grey[200]
                          : Colors.grey[300],
                      foregroundColor: Colors.grey[600],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.grey,
                              ),
                            ),
                          )
                        : const Text('Submit', style: TextStyle(fontSize: 15)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormRow({required String label, required Widget child}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(child: child),
      ],
    );
  }
}

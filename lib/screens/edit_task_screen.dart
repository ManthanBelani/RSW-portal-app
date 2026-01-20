import 'package:dashboard_clone/constants/constants.dart';
import 'package:dashboard_clone/widgets/elevated_button.dart';
import 'package:dashboard_clone/widgets/searchable_dropdown.dart';
import 'package:dashboard_clone/services/project_list_user_service.dart';
import 'package:dashboard_clone/services/crud_task.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EditTaskScreen extends StatefulWidget {
  final String taskId;
  final Map<String, dynamic>? taskData;

  const EditTaskScreen({super.key, required this.taskId, this.taskData});

  @override
  State<EditTaskScreen> createState() => _EditTaskScreenState();
}

class _EditTaskScreenState extends State<EditTaskScreen> {
  late TextEditingController _dateController;
  late TextEditingController _notesController;
  late TextEditingController _hoursController;
  late TextEditingController _ticketNumberController;
  late TextEditingController _otherHoursController;

  String? _selectedProjectId;
  String? _selectedBillable;
  String? _selectedActive;
  String? _selectedWorkHours;
  String? _userId;
  String? _teamId;
  String? _designationId;

  List<Map<String, dynamic>> _projects = [];
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _dateController = TextEditingController();
    _notesController = TextEditingController();
    _hoursController = TextEditingController();
    _ticketNumberController = TextEditingController();
    _otherHoursController = TextEditingController();

    _loadProjects();
    if (widget.taskData != null) {
      _populateTaskData();
    }
  }

  Future<void> _loadProjects() async {
    try {
      final result = await ProjectListUserService.getProjectList();
      if (result != null && result['success'] == true) {
        final projectList = result['data'] as List;
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
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error loading projects: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _populateTaskData() {
    if (widget.taskData != null) {
      final data = widget.taskData!;

      print('=== Task Data Received ===');
      print('Available keys: ${data.keys.toList()}');
      print('team_id: ${data['team_id']}');
      print('designation_id: ${data['designation_id']}');
      print('user_id: ${data['user_id']}');
      print('project_id: ${data['project_id']}');

      _dateController.text = data['date'] ?? '';
      _notesController.text = data['note'] ?? '';
      
      // Handle hours - check if it's a predefined value or custom
      final hoursValue = data['hours']?.toString() ?? '';
      final predefinedHours = [
        '1', '1.5', '2', '2.5', '3', '3.5', '4', '4.5',
        '5', '5.5', '6', '6.5', '7', '7.5', '8', '8.5', '9'
      ];
      
      if (predefinedHours.contains(hoursValue)) {
        _selectedWorkHours = hoursValue;
      } else if (hoursValue.isNotEmpty) {
        _selectedWorkHours = 'other';
        _otherHoursController.text = hoursValue;
      }
      
      _hoursController.text = hoursValue;
      _ticketNumberController.text = data['ticketnumber']?.toString() ?? '';
      _selectedProjectId = data['project_id']?.toString();
      _userId = data['user_id']?.toString();
      _designationId = data['designation_id']?.toString() ?? '';

      // Try multiple possible field names for team_id
      // Use designation_id as fallback since API returns that
      _teamId =
          data['team_id']?.toString() ??
          data['teamId']?.toString() ??
          data['team']?.toString() ??
          data['designation_id']?.toString() ??
          '';

      // Set billable status
      final billValue = data['bill']?.toString();
      if (billValue == '1') {
        _selectedBillable = 'Billable';
      } else if (billValue == '2') {
        _selectedBillable = 'Non-billable';
      }

      // Set active status
      final activeValue = data['active']?.toString();
      if (activeValue == '1') {
        _selectedActive = 'Active';
      } else if (activeValue == '0') {
        _selectedActive = 'In-Active';
      }
    }
  }

  Future<void> _handleSubmit() async {
    // Validate required fields
    if (_selectedProjectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a project'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedWorkHours == null || _selectedWorkHours == 'Work hours') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select work hours'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedWorkHours == 'other' && _otherHoursController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter hours'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      String formattedDate = _dateController.text;
      if (_dateController.text.contains('/')) {
        final parts = _dateController.text.split('/');
        if (parts.length == 3) {
          formattedDate = '${parts[2]}-${parts[1]}-${parts[0]}';
        }
      }

      final billValue = _selectedBillable == 'Billable' ? '1' : '2';
      final activeValue = _selectedActive == 'Active' ? '1' : '0';

      // Determine hours value
      String hoursValue;
      if (_selectedWorkHours == 'other') {
        hoursValue = _otherHoursController.text;
      } else {
        hoursValue = _selectedWorkHours ?? '';
      }

      final ticketNumber = _selectedProjectId == '126'
          ? _ticketNumberController.text
          : '';

      print('=== Submitting Update ===');
      print('Task ID: ${widget.taskId}');
      print('Project ID: $_selectedProjectId');
      print('User ID: $_userId');
      print('Team ID: $_teamId');
      print('Designation ID: $_designationId');
      print('Team ID is empty: ${_teamId?.isEmpty ?? true}');

      String finalTeamId = _teamId ?? '';
      if (finalTeamId.isEmpty && widget.taskData != null) {
        // Check all possible team_id fields, including designation_id
        finalTeamId =
            widget.taskData!['team_id']?.toString() ??
            widget.taskData!['teamId']?.toString() ??
            widget.taskData!['team']?.toString() ??
            widget.taskData!['designation_id']?.toString() ??
            _designationId ??
            '';
        print('Fallback Team ID (using designation_id): $finalTeamId');
      }

      final result = await CRUDForTask.updateTask(
        widget.taskId,
        _selectedProjectId!,
        formattedDate,
        hoursValue,
        '', // other
        _notesController.text,
        ticketNumber,
        billValue,
        activeValue,
        '', // task_id
        _userId ?? ''
      );

      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });

        if (result != null && result['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Task updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result?['message'] ?? 'Failed to update task'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  void dispose() {
    _dateController.dispose();
    _notesController.dispose();
    _hoursController.dispose();
    _ticketNumberController.dispose();
    _otherHoursController.dispose();
    super.dispose();
  }

  void _openDatePicker() {
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
          _dateController.text = DateFormat('dd/MM/yyyy').format(selectedDate);
        });
      }
    });
  }

  InputDecoration _buildInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
      filled: true,
      fillColor: Colors.white,
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
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
                      'Edit Task',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                      ),
                      child: const Text('Back', style: TextStyle(fontSize: 16)),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Form Container
                Container(
                  padding: const EdgeInsets.all(24),
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
                      // Project Name Dropdown (Searchable)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Project Name',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SearchableDropdown(
                            value: _selectedProjectId,
                            hint: 'Select Project',
                            items: _projects,
                            onChanged: (value) {
                              setState(() {
                                _selectedProjectId = value;
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Date Field
                      TextFormField(
                        controller: _dateController,
                        readOnly: true,
                        decoration: _buildInputDecoration('Date').copyWith(
                          suffixIcon: IconButton(
                            onPressed: _openDatePicker,
                            icon: Icon(
                              Icons.calendar_today_outlined,
                              color: Colors.grey[600],
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Work Hours Dropdown
                      DropdownButtonFormField<String>(
                        dropdownColor: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        value: _selectedWorkHours,
                        decoration: _buildInputDecoration('Work Hours'),
                        isExpanded: true,
                        items: [
                          'Work hours',
                          '1',
                          '1.5',
                          '2',
                          '2.5',
                          '3',
                          '3.5',
                          '4',
                          '4.5',
                          '5',
                          '5.5',
                          '6',
                          '6.5',
                          '7',
                          '7.5',
                          '8',
                          '8.5',
                          '9',
                          'other',
                        ].map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(
                              value,
                              style: TextStyle(
                                color: value == 'Work hours'
                                    ? Colors.grey[400]
                                    : Colors.black87,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedWorkHours = value;
                          });
                        },
                      ),
                      const SizedBox(height: 20),

                      // Other Hours Field (only shown when 'other' is selected)
                      if (_selectedWorkHours == 'other') ...[
                        TextFormField(
                          controller: _otherHoursController,
                          decoration: _buildInputDecoration('Enter Hours'),
                          keyboardType: TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Ticket Number Field (only for project_id 126)
                      if (_selectedProjectId == '126') ...[
                        TextFormField(
                          controller: _ticketNumberController,
                          decoration: _buildInputDecoration('Ticket Number'),
                          keyboardType: TextInputType.text,
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Billable/Non-Billable Dropdown
                      DropdownButtonFormField<String>(dropdownColor: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        value: _selectedBillable,
                        decoration: _buildInputDecoration(
                          'Billable/Non-Billable',
                        ),
                        isExpanded: true,
                        items: ['Billable', 'Non-billable']
                            .map(
                              (option) => DropdownMenuItem<String>(
                                value: option,
                                child: Text(option),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedBillable = value;
                          });
                        },
                      ),
                      const SizedBox(height: 20),

                      // Active/In-Active Dropdown
                      DropdownButtonFormField<String>(dropdownColor: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        value: _selectedActive,
                        decoration: _buildInputDecoration('Active/In-Active'),
                        isExpanded: true,
                        items: ['Active', 'In-Active']
                            .map(
                              (option) => DropdownMenuItem<String>(
                                value: option,
                                child: Text(option),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedActive = value;
                          });
                        },
                      ),
                      const SizedBox(height: 20),

                      // Notes Field
                      TextFormField(
                        controller: _notesController,
                        decoration: _buildInputDecoration('Notes'),
                        maxLines: 5,
                        textAlignVertical: TextAlignVertical.top,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Submit Button
                SizedBox(
                  width: 150,
                  child: ReusableButton(
                    text: 'Submit',
                    onPressed: _isSubmitting ? null : _handleSubmit,
                    backgroundColor: const Color(0xFFFC3342),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    isLoading: _isSubmitting,
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

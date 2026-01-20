import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/constants.dart';
import '../widgets/searchable_dropdown.dart';
import '../services/crud_task.dart';
import '../services/project_list_user_service.dart';
import '../services/auth_service.dart';

class AddTaskScreen extends StatefulWidget {
  const AddTaskScreen({super.key});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class TaskEntry {
  String? selectedProjectId;
  TextEditingController dateController = TextEditingController();
  TextEditingController notesController = TextEditingController();
  TextEditingController ticketController = TextEditingController();
  TextEditingController otherController = TextEditingController();
  String selectedBillableStatus = 'Billable/Non-billable';
  String selectedWorkHours = 'Work hours';

  TaskEntry() {
    dateController.text = DateFormat('dd/MM/yyyy').format(DateTime.now());
  }

  void dispose() {
    dateController.dispose();
    notesController.dispose();
    ticketController.dispose();
    otherController.dispose();
  }
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  List<TaskEntry> taskEntries = [];
  List<Map<String, dynamic>> projects = [];
  bool isSubmitting = false;
  bool isLoadingProjects = true;

  @override
  void initState() {
    super.initState();
    _loadProjects();
    _addNewTaskEntry();
  }

  @override
  void dispose() {
    for (var entry in taskEntries) {
      entry.dispose();
    }
    super.dispose();
  }

  Future<void> _loadProjects() async {
    try {
      final result = await ProjectListUserService.getProjectList();
      if (result != null && result['success'] == true) {
        final projectList = result['data'] as List;
        if (mounted) {
          setState(() {
            projects = projectList
                .map(
                  (p) => {
                    'id': p['id'].toString(),
                    'name': p['project_name'] ?? '',
                  },
                )
                .toList();
            isLoadingProjects = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoadingProjects = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading projects: $e')),
        );
      }
    }
  }

  void _addNewTaskEntry() {
    setState(() {
      taskEntries.add(TaskEntry());
    });
  }

  void _removeTaskEntry(int index) {
    if (taskEntries.length > 1) {
      setState(() {
        taskEntries[index].dispose();
        taskEntries.removeAt(index);
      });
    }
  }

  void _openDatePicker(TaskEntry entry) {
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
          entry.dateController.text = DateFormat('dd/MM/yyyy').format(selectedDate);
        });
      }
    });
  }

  Future<void> _submitTasks() async {
    // Validate all entries
    for (int i = 0; i < taskEntries.length; i++) {
      final entry = taskEntries[i];
      
      if (entry.selectedProjectId == null || entry.selectedProjectId!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please select project for task ${i + 1}')),
        );
        return;
      }

      if (entry.dateController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please select date for task ${i + 1}')),
        );
        return;
      }

      if (entry.selectedWorkHours == 'Work hours') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please select work hours for task ${i + 1}')),
        );
        return;
      }

      if (entry.selectedWorkHours == 'other' && entry.otherController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please enter hours for task ${i + 1}')),
        );
        return;
      }

      if (entry.selectedBillableStatus == 'Billable/Non-billable') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please select billable status for task ${i + 1}')),
        );
        return;
      }

      // Validate ticket number for project 126
      if (entry.selectedProjectId == '126' && entry.ticketController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please enter ticket number for task ${i + 1}')),
        );
        return;
      }
    }

    setState(() {
      isSubmitting = true;
    });

    try {
      // Get user_id from AuthService
      final userId = await AuthService.getUserId();

      if (userId == null || userId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User ID not found. Please login again.')),
        );
        setState(() {
          isSubmitting = false;
        });
        return;
      }

      // Prepare tasks data
      List<Map<String, dynamic>> tasksData = taskEntries.map((entry) {
        // Convert date format from dd/MM/yyyy to dd-MMM-yyyy
        DateTime parsedDate = DateFormat('dd/MM/yyyy').parse(entry.dateController.text);
        String formattedDate = DateFormat('dd-MMM-yyyy').format(parsedDate);

        // Determine hours value
        double hours;
        if (entry.selectedWorkHours == 'other') {
          hours = double.tryParse(entry.otherController.text) ?? 0;
        } else {
          hours = double.tryParse(entry.selectedWorkHours) ?? 0;
        }

        // Determine bill_name (1 for Billable, 2 for Non-billable)
        int billName = entry.selectedBillableStatus == 'Billable' ? 1 : 2;

        return {
          'project_id': int.tryParse(entry.selectedProjectId!) ?? 0,
          'bill_name': billName,
          'ticketnumber': entry.ticketController.text,
          'date': formattedDate,
          'hours': hours,
          'other': entry.otherController.text,
          'note': entry.notesController.text,
        };
      }).toList();

      // Call API
      final result = await CRUDForTask.addTask(userId, tasksData);

      if (result != null && result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Tasks added successfully!')),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result?['message'] ?? 'Failed to add tasks')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Add Task',
                      style: TextStyle(
                        fontSize: isMobile ? 20 : 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: backButtonColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 16 : 24,
                          vertical: isMobile ? 8 : 12,
                        ),
                      ),
                      child: Text(
                        'Back',
                        style: TextStyle(
                          fontSize: isMobile ? 14 : 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                ...taskEntries.asMap().entries.map((entry) {
                  int index = entry.key;
                  TaskEntry taskEntry = entry.value;
                  return Column(
                    children: [
                      _buildTaskContainer(taskEntry, index, isMobile),
                      const SizedBox(height: 16),
                    ],
                  );
                }).toList(),
                const SizedBox(height: 16),
                Center(
                  child: ElevatedButton.icon(
                    onPressed: isSubmitting ? null : _submitTasks,
                    icon: isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check),
                    label: Text(
                      isSubmitting ? 'Submitting...' : 'Submit',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 24 : 48,
                        vertical: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTaskContainer(TaskEntry entry, int index, bool isMobile) {
    return Container(
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
        padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Task ${index + 1}',
                  style: TextStyle(
                    fontSize: isMobile ? 18 : 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Row(
                  children: [
                    if (index == taskEntries.length - 1)
                      ElevatedButton.icon(
                        onPressed: _addNewTaskEntry,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                      ),
                    if (taskEntries.length > 1) ...[
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () => _removeTaskEntry(index),
                        icon: const Icon(Icons.remove, size: 18),
                        label: const Text('Remove'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (isMobile) ...[
              _buildSectionHeader('Project Name & Billable'),
              const SizedBox(height: 16),
              _buildProjectDropdown(entry),
              const SizedBox(height: 16),
              _buildBillableDropdown(entry),
              if (entry.selectedProjectId == '126') ...[
                const SizedBox(height: 16),
                _buildSectionHeader('Ticket Number'),
                const SizedBox(height: 16),
                _buildTicketField(entry),
              ],
              const SizedBox(height: 24),
              _buildSectionHeader('Date & Time'),
              const SizedBox(height: 16),
              _buildDateField(entry),
              const SizedBox(height: 16),
              _buildWorkHoursDropdown(entry),
              if (entry.selectedWorkHours == 'other') ...[
                const SizedBox(height: 16),
                _buildOtherHoursField(entry),
              ],
              const SizedBox(height: 24),
              _buildSectionHeader('Notes'),
              const SizedBox(height: 16),
              _buildNotesField(entry),
            ] else ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader('Project Name & Billable'),
                        const SizedBox(height: 16),
                        _buildProjectDropdown(entry),
                        const SizedBox(height: 16),
                        _buildBillableDropdown(entry),
                        if (entry.selectedProjectId == '126') ...[
                          const SizedBox(height: 16),
                          _buildSectionHeader('Ticket Number'),
                          const SizedBox(height: 16),
                          _buildTicketField(entry),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader('Date & Time'),
                        const SizedBox(height: 16),
                        _buildDateField(entry),
                        const SizedBox(height: 16),
                        _buildWorkHoursDropdown(entry),
                        if (entry.selectedWorkHours == 'other') ...[
                          const SizedBox(height: 16),
                          _buildOtherHoursField(entry),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader('Notes'),
                        const SizedBox(height: 16),
                        _buildNotesField(entry),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: Colors.grey[600],
      ),
    );
  }

  Widget _buildProjectDropdown(TaskEntry entry) {
    return SearchableDropdown(
      value: entry.selectedProjectId,
      hint: 'Select Project',
      items: projects,
      onChanged: (String? newValue) {
        setState(() {
          entry.selectedProjectId = newValue;
        });
      },
    );
  }

  Widget _buildTicketField(TaskEntry entry) {
    return TextFormField(
      controller: entry.ticketController,
      decoration: InputDecoration(
        hintText: 'Ticket Number (Optional)',
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
      ),
    );
  }

  Widget _buildOtherHoursField(TaskEntry entry) {
    return TextFormField(
      controller: entry.otherController,
      keyboardType: TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        hintText: 'Enter hours (e.g., 2.5)',
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
      ),
    );
  }

  Widget _buildBillableDropdown(TaskEntry entry) {
    return DropdownButtonFormField<String>(
      borderRadius: BorderRadius.circular(10),
      dropdownColor: Colors.white,
      value: entry.selectedBillableStatus,
      decoration: InputDecoration(
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
      ),
      items: ['Billable/Non-billable', 'Billable', 'Non-billable'].map((
        String value,
      ) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(
            value,
            style: TextStyle(
              color: value == 'Billable/Non-billable'
                  ? Colors.grey[400]
                  : Colors.black87,
            ),
          ),
        );
      }).toList(),
      onChanged: (String? newValue) {
        setState(() {
          entry.selectedBillableStatus = newValue!;
        });
      },
    );
  }

  Widget _buildDateField(TaskEntry entry) {
    return TextFormField(
      controller: entry.dateController,
      readOnly: true,
      onTap: () => _openDatePicker(entry),
      decoration: InputDecoration(
        hintText: 'Select Date',
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
        suffixIcon: Icon(
          Icons.calendar_today_outlined,
          color: Colors.grey[600],
          size: 20,
        ),
      ),
    );
  }

  Widget _buildWorkHoursDropdown(TaskEntry entry) {
    return DropdownButtonFormField<String>(borderRadius: BorderRadius.circular(10),
      dropdownColor: Colors.white,
      value: entry.selectedWorkHours,
      decoration: InputDecoration(
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
      ),
      items:
          [
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
      onChanged: (String? newValue) {
        setState(() {
          entry.selectedWorkHours = newValue!;
        });
      },
    );
  }

  Widget _buildNotesField(TaskEntry entry) {
    return TextFormField(
      controller: entry.notesController,
      maxLines: 8,
      decoration: InputDecoration(
        hintText: 'Enter your notes here...',
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
      ),
    );
  }
}

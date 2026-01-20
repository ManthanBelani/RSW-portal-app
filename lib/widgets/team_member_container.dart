import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/team_data_service.dart';

class Teammate {
  final List<String> developers;
  final List<String> teamLeaders;
  final List<String> projectManagers;

  Teammate({
    required this.developers,
    required this.teamLeaders,
    required this.projectManagers,
  });

  factory Teammate.fromJson(Map<String, dynamic> json) {
    return Teammate(
      developers: json['developers'] != null
          ? List<String>.from(json['developers'])
          : [],
      teamLeaders: json['teamLeaders'] != null
          ? List<String>.from(json['teamLeaders'])
          : [],
      projectManagers: json['projectManagers'] != null
          ? List<String>.from(json['projectManagers'])
          : [],
    );
  }
}

class ProjectItem {
  final String projectName;
  final String? startDate;
  final String? endDate;
  final int projectId;
  final Teammate teammates;
  final String? role;
  final String? priority;

  ProjectItem({
    required this.projectName,
    this.startDate,
    this.endDate,
    required this.projectId,
    required this.teammates,
    this.role,
    this.priority,
  });

  factory ProjectItem.fromJson(Map<String, dynamic> json) {
    return ProjectItem(
      projectName: json['project_name'] ?? 'Unnamed Project',
      startDate: json['start_date'],
      endDate: json['end_date'],
      projectId: json['project_id'] ?? 0,
      teammates: Teammate.fromJson(json['teammates'] ?? {}),
      role: json['role'],
      priority: json['priority'],
    );
  }
}

String formatName(String name) {
  return name
      .split(' ')
      .map((part) => part[0].toUpperCase() + part.substring(1).toLowerCase())
      .join(' ');
}

String formatDateRange(String? startDate, String? endDate) {
  if (startDate == null || endDate == null) return 'No Date';
  if (startDate == endDate) return 'Today';
  try {
    final start = DateTime.parse(startDate);
    final end = DateTime.parse(endDate);
    final formatter = DateFormat('d MMM');
    return '${formatter.format(start)} - ${formatter.format(end)}';
  } catch (e) {
    return 'No Date';
  }
}

bool hasRole(String role) {
  return role == '' || role == '';
}

class TeamMembersBox extends StatefulWidget {
  const TeamMembersBox({super.key});

  @override
  State<TeamMembersBox> createState() => _TeamMembersBoxState();
}

class _TeamMembersBoxState extends State<TeamMembersBox> {
  bool _isOccupied = true;
  bool _isLoading = true;
  List<ProjectItem> _projects = [];
  String? _errorMessage;
  final TeamDataService _teamDataService = TeamDataService();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _teamDataService.getProjectMemberData();

      if (response != null && response['success'] == true) {
        final data = response['data'];
        
        if (data != null && data['success'] == true) {
          final projectsData = data['data'] as List<dynamic>?;
          final hasProjectAndFree = data['has_project_and_free'] ?? 0;
          
          setState(() {
            _projects = projectsData
                    ?.map((project) => ProjectItem.fromJson(project))
                    .toList() ??
                [];
            _isOccupied = hasProjectAndFree == 1;
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = 'Failed to load project data';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = response?['error']?['message'] ?? 'Failed to load data';
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

  void _toggleStatus() {
    setState(() {
      _isOccupied = !_isOccupied;
    });
  }

  void _openUnassign(ProjectItem project) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Un-Assign Project'),
        content: const Text(
          'Are you sure you want to un-assign from this project?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _confirmUnassign();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('OK', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmUnassign() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Project unassigned!'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final userFullName = 'Rainstream Web';

    Color _getBackgroundColor(ProjectItem item) {
      final isDev = item.teammates.developers.contains(userFullName);
      final isTL = item.teammates.teamLeaders.contains(userFullName);
      final isPM = item.teammates.projectManagers.contains(userFullName);

      if (isDev && isTL) {
        return Colors.green.withOpacity(0.15);
      } else if (isDev && isPM) {
        return Colors.blue.withOpacity(0.15);
      } else if (isDev) {
        return Colors.green.withOpacity(0.1);
      } else if (isTL) {
        return Colors.orange.withOpacity(0.1);
      } else if (isPM) {
        return Colors.blue.withOpacity(0.1);
      }
      return Colors.grey.withOpacity(0.05);
    }

    Color _getTextColor(ProjectItem item) {
      final isDev = item.teammates.developers.contains(userFullName);
      final isTL = item.teammates.teamLeaders.contains(userFullName);
      final isPM = item.teammates.projectManagers.contains(userFullName);

      if (isDev && isTL) return Colors.orange.shade700;
      if (isDev && isPM) return Colors.blue.shade700;
      if (isDev) return Colors.green.shade700;
      if (isTL) return Colors.orange.shade700;
      if (isPM) return Colors.blue.shade700;
      return Colors.grey.shade600;
    }

    Widget _buildChipList(List<String> names, Color color) {
      if (names.isEmpty) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Text(
            'Not Assigned',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      }
      return Wrap(
        spacing: 6,
        runSpacing: 6,
        children: names.map((name) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Text(
              formatName(name),
              style: TextStyle(
                fontSize: 12,
                // color: color.shade500,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        }).toList(),
      );
    }

    Widget _buildRoleRow({required String title, required Widget child}) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 130,
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
            Expanded(child: child),
          ],
        ),
      );
    }

    return Container(
      //margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: BoxBorder.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            decoration: BoxDecoration(
              // border: BoxBorder.all(color: Colors.grey),
              gradient: LinearGradient(
                colors: [Colors.grey.shade50, Colors.grey.shade100],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Projects Assigned',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.refresh, color: Colors.grey.shade700),
                  onPressed: _loadData,
                  tooltip: 'Refresh',
                  iconSize: 20,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _isOccupied ? 'Occupied' : 'Available',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _isOccupied
                              ? Colors.red.shade600
                              : Colors.green.shade600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Transform.scale(
                        scale: 0.8,
                        child: Switch(
                          value: _isOccupied,
                          onChanged: (value) => _toggleStatus(),
                          activeColor: Colors.red.shade400,
                          inactiveThumbColor: Colors.green.shade400,
                          inactiveTrackColor: Colors.green.shade100,
                          activeTrackColor: Colors.red.shade100,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            child: _isLoading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : _errorMessage != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 48,
                                color: Colors.red.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _errorMessage!,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.red.shade600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: _loadData,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Retry'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _projects.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.assignment_outlined,
                                    size: 48,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No Projects Assigned',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    itemCount: _projects.length,
                    separatorBuilder: (context, index) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Divider(height: 1, color: Colors.grey.shade200),
                    ),
                    itemBuilder: (context, index) {
                      final item = _projects[index];
                      return Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: _getBackgroundColor(item),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _getTextColor(item).withOpacity(0.2),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    item.projectName,
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                  if (item.role != null)
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                        top: 4,
                                                      ),
                                                      child: Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                          horizontal: 8,
                                                          vertical: 2,
                                                        ),
                                                        decoration:
                                                            BoxDecoration(
                                                          color: _getTextColor(
                                                            item,
                                                          ).withOpacity(0.15),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(4),
                                                        ),
                                                        child: Text(
                                                          item.role!
                                                              .replaceAll(
                                                                '_',
                                                                ' ',
                                                              )
                                                              .toUpperCase(),
                                                          style: TextStyle(
                                                            fontSize: 10,
                                                            fontWeight:
                                                                FontWeight.w700,
                                                            color:
                                                                _getTextColor(
                                                              item,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: _getTextColor(
                                                  item,
                                                ).withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                formatDateRange(
                                                  item.startDate,
                                                  item.endDate,
                                                ),
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 12,
                                                  color: _getTextColor(item),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (hasRole('projectmanager'))
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.red.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: IconButton(
                                        onPressed: () => _openUnassign(item),
                                        icon: const Icon(
                                          Icons.close_rounded,
                                          color: Colors.red,
                                          size: 20,
                                        ),
                                        tooltip: 'Un-assign project',
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildRoleRow(
                              title: item.teammates.developers.length > 1
                                  ? 'Developers:'
                                  : 'Developer:',
                              child: _buildChipList(
                                item.teammates.developers,
                                Colors.green,
                              ),
                            ),
                            _buildRoleRow(
                              title: item.teammates.teamLeaders.length > 1
                                  ? 'Team Leaders:'
                                  : 'Team Leader:',
                              child: _buildChipList(
                                item.teammates.teamLeaders,
                                Colors.orange,
                              ),
                            ),
                            _buildRoleRow(
                              title: item.teammates.projectManagers.length > 1
                                  ? 'Project Managers:'
                                  : 'Project Manager:',
                              child: _buildChipList(
                                item.teammates.projectManagers,
                                Colors.blue,
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

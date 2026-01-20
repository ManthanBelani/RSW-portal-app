import 'package:flutter/material.dart';
import 'package:flutter_advanced_table/flutter_advanced_table.dart';
import '../constants/constants.dart';
import '../services/resource_managment_service.dart';
import '../services/client_list.dart';
import '../widgets/searchable_dropdown.dart';

class ResourceManagementScreen extends StatefulWidget {
  const ResourceManagementScreen({super.key});

  @override
  State<ResourceManagementScreen> createState() =>
      _ResourceManagementScreenState();
}

class _ResourceManagementScreenState extends State<ResourceManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ResourceManagmentService _service = ResourceManagmentService();

  List<Map<String, dynamic>> _resources = [];
  List<Map<String, dynamic>> _projects = [];
  List<Map<String, dynamic>> _teamLeaders = [];
  List<Map<String, dynamic>> _projectManagers = [];

  String? _selectedProject;
  int _rowsPerPage = 50;

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _projectController = TextEditingController();

  final ValueNotifier<bool> _isLoadingAll = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabChange);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _projectController.dispose();
    _isLoadingAll.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    _isLoadingAll.value = true;

    try {
      final results = await Future.wait([
        _service.getClientList(),
        _loadProjects(),
        _service.getTeamLeaderList(),
        _service.getProjectManagerList(),
      ]);

      final hrResult = results[0];
      if (hrResult?['success'] == true && hrResult?['data'] != null) {
        final data = hrResult!['data'];
        List<Map<String, dynamic>> resourceList = [];

        if (data is List) {
          resourceList = List<Map<String, dynamic>>.from(data);
        } else if (data is Map && data['users'] is List) {
          resourceList = List<Map<String, dynamic>>.from(data['users']);
        } else if (data is Map && data['data'] is List) {
          resourceList = List<Map<String, dynamic>>.from(data['data']);
        } else if (data is Map) {
          resourceList = [Map<String, dynamic>.from(data)];
        }

        setState(() {
          _resources = resourceList;
        });
      }

      final projectResult = results[1];
      if (projectResult?['success'] == true && projectResult?['data'] != null) {
        final data = projectResult!['data'];
        setState(() {
          _projects = data is List
              ? List<Map<String, dynamic>>.from(data)
              : [Map<String, dynamic>.from(data)];
        });
      }

      final teamLeaderResult = results[2];
      if (teamLeaderResult?['success'] == true &&
          teamLeaderResult?['data'] != null) {
        final data = teamLeaderResult!['data'];
        setState(() {
          _teamLeaders = data is List
              ? List<Map<String, dynamic>>.from(data)
              : [Map<String, dynamic>.from(data)];
        });
      }

      final pmResult = results[3];
      if (pmResult?['success'] == true && pmResult?['data'] != null) {
        final data = pmResult!['data'];
        setState(() {
          _projectManagers = data is List
              ? List<Map<String, dynamic>>.from(data)
              : [Map<String, dynamic>.from(data)];
        });
      }
    } catch (e) {
      debugPrint('Error loading data: $e');
    } finally {
      _isLoadingAll.value = false;
    }
  }

  Future<Map<String, dynamic>?> _loadProjects() async {
    try {
      final response = await ClientList.getProjectUserList();

      if (response?['success'] == true && response?['data'] != null) {
        final data = response!['data'];
        List<Map<String, dynamic>> projectList = [];

        if (data is List) {
          projectList = List<Map<String, dynamic>>.from(data);
        } else if (data is Map) {
          projectList = [Map<String, dynamic>.from(data)];
        }

        setState(() {
          _projects = projectList;
        });

        return {'success': true, 'data': projectList};
      }
    } catch (e) {
      debugPrint('Error loading projects: $e');
    }
    return {'success': false};
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.shade50,
      height: MediaQuery.of(context).size.height - 100,
      child: Column(
        children: [
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: primaryColor,
              unselectedLabelColor: Colors.grey,
              indicatorColor: primaryColor,
              tabs: const [
                Tab(text: 'All Resources'),
                Tab(text: 'Non Billable'),
                Tab(text: 'Free Resources'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildResourceTab(),
                _buildResourceTab(),
                _buildResourceTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResourceTab() {
    return Column(
      children: [
        _buildFilters(),
        _buildToolbar(),
        Expanded(child: _buildAdvancedTable()),
      ],
    );
  }

  List<Map<String, dynamic>> get _filteredResources {
    return _resources.where((resource) {
      if (_searchController.text.isEmpty) return true;
      final name =
          resource['employee_name']?.toString().toLowerCase() ??
          resource['name']?.toString().toLowerCase() ??
          '';
      final designation =
          resource['designation_name'] ?? resource['designation'] ?? '';
      final search = _searchController.text.toLowerCase();
      return name.contains(search) ||
          designation.toLowerCase().contains(search);
    }).toList();
  }

  Widget _buildAdvancedTable() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: MediaQuery.of(context).size.width - 32,
          ),
          child: AdvancedTableWidget(
            headerItems: [
              'User',
              'Billable',
              'Occupied',
              '',
              'Start / End Date',
              'Project',
              'Team Leader',
              'Project Manager',
            ],
            actions: ['Add'],
            isLoadingAll: _isLoadingAll,
            fullLoadingPlaceHolder: Center(
              child: CircularProgressIndicator(color: primaryColor),
            ),
            onEmptyState: Center(
              child: Text(
                'No resources found',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
              ),
            ),
            items: _filteredResources,
            headerDecoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            innerHeaderPadding: const EdgeInsets.symmetric(
              vertical: 12,
              horizontal: 8,
            ),
            rowDecorationBuilder: (index, isHover) {
              return BoxDecoration(
                color: isHover
                    ? Colors.grey.shade100
                    : (index % 2 == 0 ? Colors.white : Colors.grey.shade50),
                borderRadius: BorderRadius.circular(4),
              );
            },
            innerRowElementsPadding: const EdgeInsets.symmetric(
              vertical: 8,
              horizontal: 8,
            ),
            addSpacerToActions: false,
            headerBuilder: (context, headerBuilder) {
              // Fixed widths for better control
              double width = 150;
              if (headerBuilder.index == 0) width = 200; // User column wider
              if (headerBuilder.index == 1 || headerBuilder.index == 2)
                width = 100; // Switches
              if (headerBuilder.index == 3) width = 50; // Drag handle
              if (headerBuilder.index == 4) width = 200; // Date range
              if (headerBuilder.index >= 5) width = 200; // Dropdowns

              return SizedBox(
                width: width,
                child: Text(
                  headerBuilder.value,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Colors.grey.shade700,
                  ),
                ),
              );
            },
            rowElementsBuilder: (context, rowBuilder) {
              final resource = _filteredResources[rowBuilder.index];
              return [
                // User Cell - 200px
                SizedBox(width: 200, child: _buildUserCell(resource)),
                // Billable Switch - 100px
                SizedBox(width: 100, child: _buildBillableSwitch(resource)),
                // Occupied Switch - 100px
                SizedBox(width: 100, child: _buildOccupiedSwitch(resource)),
                // Drag Handle - 50px
                SizedBox(
                  width: 50,
                  child: Icon(
                    Icons.drag_handle,
                    color: Colors.grey.shade400,
                    size: 22,
                  ),
                ),
                // Date Range - 200px
                SizedBox(width: 200, child: _buildDateRangeCell()),
                // Project Dropdown - 200px
                SizedBox(width: 200, child: _buildProjectDropdown(resource)),
                // Team Leader Dropdown - 200px
                SizedBox(width: 200, child: _buildTeamLeaderDropdown(resource)),
                // Project Manager Dropdown - 200px
                SizedBox(
                  width: 200,
                  child: _buildProjectManagerDropdown(resource),
                ),
              ];
            },
            actionBuilder: (context, actionBuilder) {
              return SizedBox(
                width: 80,
                child: IconButton(
                  icon: Icon(
                    Icons.add_circle,
                    color: Colors.green.shade400,
                    size: 28,
                  ),
                  onPressed: () {
                    // Handle add action for row at actionBuilder.rowIndex
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildUserCell(Map<String, dynamic> resource) {
    final userName =
        resource['employee_name'] ?? resource['name'] ?? 'User Name';
    final designation =
        resource['designation_name'] ??
        resource['designation'] ??
        'Designation';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          userName,
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: primaryColor, width: 1.5),
          ),
          child: Text(
            designation,
            style: TextStyle(
              fontSize: 10,
              color: primaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBillableSwitch(Map<String, dynamic> resource) {
    return Transform.scale(
      scale: 0.8,
      child: Switch(
        value:
            (resource['billable_status'] == 1 ||
            resource['billable_status'] == true ||
            resource['billable'] == true),
        onChanged: (value) {
          setState(() {
            resource['billable_status'] = value ? 1 : 0;
          });
        },
        activeColor: Colors.red.shade400,
        inactiveThumbColor: Colors.grey.shade400,
        inactiveTrackColor: Colors.green.shade100,
        activeTrackColor: Colors.red.shade100,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  Widget _buildOccupiedSwitch(Map<String, dynamic> resource) {
    return Transform.scale(
      scale: 0.8,
      child: Switch(
        value:
            (resource['occupied'] == true || resource['has_project'] == true),
        onChanged: (value) {
          setState(() {
            resource['occupied'] = value;
          });
        },
        activeColor: Colors.red.shade400,
        inactiveThumbColor: Colors.grey.shade400,
        inactiveTrackColor: Colors.green.shade100,
        activeTrackColor: Colors.red.shade100,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  Widget _buildDateRangeCell() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Select Date Range',
          style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
        ),
        const SizedBox(height: 4),
        const Text(
          '11/11 - 11/11',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: primaryColor, width: 1),
              ),
              child: Text(
                'Current Month',
                style: TextStyle(fontSize: 9, color: primaryColor),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.grey.shade300, width: 1),
              ),
              child: Text(
                'Today',
                style: TextStyle(fontSize: 9, color: Colors.grey.shade600),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProjectDropdown(Map<String, dynamic> resource) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      hint: Text(
        'Project',
        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
      ),
      value: resource['selected_project'],
      isExpanded: true,
      items: _projects.map((project) {
        return DropdownMenuItem<String>(
          value: project['id']?.toString(),
          child: Text(
            project['project_name'] ?? '',
            style: const TextStyle(fontSize: 12),
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          resource['selected_project'] = value;
        });
      },
    );
  }

  Widget _buildTeamLeaderDropdown(Map<String, dynamic> resource) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      hint: Row(
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: Colors.grey.shade300,
            child: const Text(
              'TL',
              style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text('Team Leader', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
      value: resource['selected_team_leader'],
      isExpanded: true,
      items: _teamLeaders.map((leader) {
        final name = leader['name'] ?? leader['employee_name'] ?? '';
        final initials = name.isNotEmpty && name.length > 1
            ? name.substring(0, 2).toUpperCase()
            : 'TL';

        return DropdownMenuItem<String>(
          value: leader['id']?.toString(),
          child: Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: Colors.grey.shade300,
                child: Text(
                  initials,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          resource['selected_team_leader'] = value;
        });
      },
    );
  }

  Widget _buildProjectManagerDropdown(Map<String, dynamic> resource) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      hint: Row(
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: Colors.grey.shade300,
            child: const Text(
              'PM',
              style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text('Project Manager', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
      value: resource['selected_project_manager'],
      isExpanded: true,
      items: _projectManagers.map((manager) {
        final name = manager['name'] ?? manager['employee_name'] ?? '';
        final initials = name.isNotEmpty && name.length > 1
            ? name.substring(0, 2).toUpperCase()
            : 'PM';

        return DropdownMenuItem<String>(
          value: manager['id']?.toString(),
          child: Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: Colors.grey.shade300,
                child: Text(
                  initials,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          resource['selected_project_manager'] = value;
        });
      },
    );
  }

  Widget _buildFilters() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
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
          const Text(
            'Select Project',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          SearchableDropdown(
            value: _selectedProject,
            hint: 'Select Project',
            items: _projects,
            idKey: 'id',
            nameKey: 'project_name',
            displayText: _projectController.text.isNotEmpty
                ? _projectController.text
                : null,
            onChanged: (value) {
              setState(() {
                _selectedProject = value;
                if (value != null) {
                  final selectedItem = _projects.firstWhere(
                    (item) => item['id']?.toString() == value,
                    orElse: () => {},
                  );
                  _projectController.text =
                      selectedItem['project_name']?.toString() ?? '';
                } else {
                  _projectController.text = '';
                }
                _loadData();
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar() {
    return Material(
      color: Colors.white,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            const Text('Show ', style: TextStyle(fontSize: 14)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButton<int>(
                value: _rowsPerPage,
                underline: const SizedBox(),
                items: [10, 25, 50, 100].map((value) {
                  return DropdownMenuItem(
                    value: value,
                    child: Text(value.toString()),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _rowsPerPage = value!;
                  });
                },
              ),
            ),
            const Text(' entries', style: TextStyle(fontSize: 14)),
            const Spacer(),
            SizedBox(
              width: 300,
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                onChanged: (value) => setState(() {}),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

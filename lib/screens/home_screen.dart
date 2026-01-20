import 'package:dashboard_clone/constants/constants.dart';
import 'package:dashboard_clone/screens/change_password_screen.dart';
import 'package:dashboard_clone/screens/task_screen.dart';
import 'package:dashboard_clone/screens/view_invoice_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:dotted_line/dotted_line.dart';
// import 'package:rsw_portal/constants/constants.dart';
// import 'package:rsw_portal/screens/task_screen.dart';
import '../models/dashboard_data_model.dart';
import '../models/user_permission_model.dart';
import '../services/dashboard_small_container_service.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import '../widgets/attendance_calender.dart';
import '../widgets/dashboard_small_conatiner.dart';
import '../widgets/drawer_list_widget.dart';
import '../widgets/leave_request_container.dart';
import '../widgets/notification_item.dart';
import '../widgets/pending_invoice_container.dart';
import '../widgets/profilepic_update_dialog.dart';
import '../widgets/team_member_container.dart';
import '../widgets/today_on_leave_conatiner.dart';
import '../widgets/upcoming_holiday_container.dart';
import '../widgets/fill_hours_continer.dart';
import 'attendance_screen.dart';
import 'test_calendar_screen.dart';

class DashboardScreen extends StatefulWidget {
  final Map<String, dynamic>? result;
  const DashboardScreen({super.key, this.result});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey _profileButtonKey = GlobalKey();
  String selectedMenuItem = 'Dashboard';
  UserDesignationPermission? userPermissions;
  DashboardData? dashboardData;
  bool isLoading = true;

  bool get isDesktop => MediaQuery.of(context).size.width >= 1200;
  bool get isTablet =>
      MediaQuery.of(context).size.width >= 768 &&
      MediaQuery.of(context).size.width < 1200;
  bool get isMobile => MediaQuery.of(context).size.width < 768;

  @override
  void initState() {
    super.initState();
    _initializePermissions(
      widget.result?['data']?['user_designation_permission'],
    );
    _loadDashboardData();
  }

  void _initializePermissions([Map<String, dynamic>? permissionData]) {
    if (permissionData != null) {
      userPermissions = UserDesignationPermission.fromJson(permissionData);
    } else {
      userPermissions = UserDesignationPermission(
        id: 1,
        designationId: 1,
        teamId: null,
        notes: [true, true, true, true],
        projects: [true, true, true, true],
        tasks: [true, true, true, true],
        users: [true, true, true, true],
        interviews: [false, false, false, false],
        leads: [false, false, false, false],
        banks: [false, false, false, false],
        leaveRequest: [true, true, true, true],
        generateFixInvoice: [false, false, false, false],
        holiday: [false, false, false, false],
        roles: [false, false, false, false],
        works: [false, false, false, false],
        clients: [false, false, false, false],
        capture: [false, false, false, false],
        codingStandard: [false, false, false, true],
        attendance: [true, true, true, true],
        resourceManagement: [
          false,
          false,
        ], // Only 2 values for resource management
        socialMediaContents: [false, false, false, false],
        createdAt: null,
        updatedAt: "",
        userComputerInfos: [false, false, false, false],
        generateDocument: [false, false, false, false],
        campaigns: [false, false, false, false],
        userDocuments: [false, false, false, false],
        payrollSection: [false, false, false, false],
        proposalSystem: [false, false, false, false],
        designations: [false, false, false, false],
        rulebook: [false, false, false, false],
      );
    }
  }

  Future<void> _loadDashboardData() async {
    try {
      setState(() {
        isLoading = true;
      });

      final response =
          await DashboardSmallContainerService.getDashboardCardData();
      if (response != null && response['success'] == true) {
        final data = response['data'];
        if (data != null) {
          dashboardData = DashboardData.fromJson(data);
        }
      }
    } catch (e) {
      print('Error loading dashboard data: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  List<Widget> _buildDrawerItems() {
    List<Widget> items = [];

    // Helper to create a drawer item with selection logic
    Widget _item({
      required String title,
      required String icon,
      List<bool>? permissions,
      VoidCallback? onCreate,
      VoidCallback? onView,
      VoidCallback? onTileTap,
    }) {
      final isSelected = selectedMenuItem == title;
      // Check if user has view permission (index 3)
      final hasViewPermission =
          permissions != null &&
          permissions.length > 3 &&
          permissions[3] == true;

      return DrawerItem(
        title: title,
        iconAsset: icon,
        permissions: permissions,
        onCreateTap:
            (permissions != null && permissions.length > 0 && permissions[0])
            ? onCreate
            : null,
        onViewTap:
            (permissions != null && permissions.length > 3 && permissions[3])
            ? onView
            : null,
        isSelected: isSelected,
        onTileTap: hasViewPermission
            ? (onTileTap ??
                  () {
                    setState(() {
                      selectedMenuItem = title;
                    });
                    Navigator.pop(context); // Close drawer
                  })
            : null,
      );
    }

    // Always show Dashboard
    items.add(
      _item(
        title: 'Dashboard',
        icon: 'assets/icons/ic_dashboard.svg',
        onTileTap: () {
          setState(() {
            selectedMenuItem = 'Dashboard';
          });
          Navigator.pop(context); // Close drawer
          // Already on dashboard, just close drawer
        },
      ),
    );

    // Attendance
    if (userPermissions?.attendance.any((perm) => perm) ?? false) {
      items.add(
        _item(
          title: 'Attendance',
          icon: 'assets/icons/ic_attendance.svg',
          permissions: userPermissions?.attendance,
          onCreate: () {},
          onView: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AttendanceScreen()),
            );
          },
          onTileTap: () {
            setState(() {
              selectedMenuItem = 'Attendance';
            });
            Navigator.pop(context); // Close drawer
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AttendanceScreen()),
            );
          },
        ),
      );
    }

    // Resource Management
    if (userPermissions?.resourceManagement.any((perm) => perm) ?? false) {
      items.add(
        _item(
          title: 'Resource Management',
          icon: 'assets/icons/resource.svg',
          permissions: userPermissions?.resourceManagement,
          onCreate: () {},
          onView: () {},
        ),
      );
    }

    // Invoices
    if (userPermissions?.generateFixInvoice.any((perm) => perm) ?? false) {
      items.add(
        _item(
          title: 'Invoices',
          icon: 'assets/icons/ic_generate_invoice.svg',
          permissions: userPermissions?.generateFixInvoice,
          onCreate: () {},
          onView: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ViewInvoiceScreen()),
            );
          },
          onTileTap: () {
            setState(() {
              selectedMenuItem = 'Invoices';
            });
            Navigator.pop(context); // Close drawer
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ViewInvoiceScreen()),
            );
          },
        ),
      );
    }

    // Add a separator if items follow
    if (items.length > 1 &&
            (userPermissions?.tasks.any((perm) => perm) ?? false) ||
        (userPermissions?.leaveRequest.any((perm) => perm) ?? false) ||
        (userPermissions?.users.any((perm) => perm) ?? false) ||
        (userPermissions?.interviews.any((perm) => perm) ?? false) ||
        (userPermissions?.userComputerInfos.any((perm) => perm) ?? false) ||
        (userPermissions?.generateDocument.any((perm) => perm) ?? false)) {
      items.add(DottedLine(dashRadius: 10, dashColor: Colors.grey.shade300));
    }

    // Tasks
    if (userPermissions?.tasks.any((perm) => perm) ?? false) {
      items.add(
        _item(
          title: 'Tasks',
          icon: 'assets/icons/ic_tasks.svg',
          permissions: userPermissions?.tasks,
          onCreate: () {},
          onView: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    TaskScreen(permissions: userPermissions?.tasks),
              ),
            );
          },
          onTileTap: () {
            setState(() {
              selectedMenuItem = 'Tasks';
            });
            Navigator.pop(context); // Close drawer
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    TaskScreen(permissions: userPermissions?.tasks),
              ),
            );
          },
        ),
      );
    }

    // Leave Request
    if (userPermissions?.leaveRequest.any((perm) => perm) ?? false) {
      items.add(
        _item(
          title: 'Leave Request',
          icon: 'assets/icons/ic_leave_req.svg',
          permissions: userPermissions?.leaveRequest,
          onCreate: () {},
          onView: () {},
        ),
      );
    }

    // Users
    if (userPermissions?.users.any((perm) => perm) ?? false) {
      items.add(
        _item(
          title: 'Users',
          icon: 'assets/icons/ic_users.svg',
          permissions: userPermissions?.users,
          onCreate: () {},
          onView: () {},
        ),
      );
    }

    // Interviews
    if (userPermissions?.interviews.any((perm) => perm) ?? false) {
      items.add(
        _item(
          title: 'Interview',
          icon: 'assets/icons/ic_interviews.svg',
          permissions: userPermissions?.interviews,
          onCreate: () {},
          onView: () {},
        ),
      );
    }

    // User Computer Infos
    if (userPermissions?.userComputerInfos.any((perm) => perm) ?? false) {
      items.add(
        _item(
          title: 'User Activities',
          icon: 'assets/icons/ic_user_activities.svg',
          permissions: userPermissions?.userComputerInfos,
          onCreate: () {},
          onView: () {},
        ),
      );
    }

    // Generate Document
    if (userPermissions?.generateDocument.any((perm) => perm) ?? false) {
      items.add(
        _item(
          title: 'Employee Documents',
          icon: 'assets/icons/ic_generate_doc.svg',
          permissions: userPermissions?.generateDocument,
          onCreate: () {},
          onView: () {},
        ),
      );
    }

    // Add a separator if items follow
    if (items.length > 1 &&
            (userPermissions?.notes.any((perm) => perm) ?? false) ||
        (userPermissions?.projects.any((perm) => perm) ?? false) ||
        (userPermissions?.proposalSystem.any((perm) => perm) ?? false) ||
        (userPermissions?.clients.any((perm) => perm) ?? false) ||
        (userPermissions?.userDocuments.any((perm) => perm) ?? false)) {
      items.add(DottedLine(dashRadius: 10, dashColor: Colors.grey.shade300));
    }

    // Notes
    if (userPermissions?.notes.any((perm) => perm) ?? false) {
      items.add(
        _item(
          title: 'Notes',
          icon: 'assets/icons/ic_edit_notes.svg',
          permissions: userPermissions?.notes,
          onCreate: () {},
          onView: () {},
        ),
      );
    }

    // Projects
    if (userPermissions?.projects.any((perm) => perm) ?? false) {
      items.add(
        _item(
          title: 'Projects',
          icon: 'assets/icons/ic_projects.svg',
          permissions: userPermissions?.projects,
          onCreate: () {},
          onView: () {},
        ),
      );
    }

    // Proposal System
    if (userPermissions?.proposalSystem.any((perm) => perm) ?? false) {
      items.add(
        _item(
          title: 'Proposals',
          icon: 'assets/icons/handshake.svg',
          permissions: userPermissions?.proposalSystem,
          onCreate: () {},
          onView: () {},
        ),
      );
    }

    // Clients
    if (userPermissions?.clients.any((perm) => perm) ?? false) {
      items.add(
        _item(
          title: 'Clients',
          icon: 'assets/icons/ic_clients.svg',
          permissions: userPermissions?.clients,
          onCreate: () {},
          onView: () {},
        ),
      );
    }

    // User Documents
    if (userPermissions?.userDocuments.any((perm) => perm) ?? false) {
      items.add(
        _item(
          title: 'Clients Documents',
          icon: 'assets/icons/ic_generate_doc.svg',
          permissions: userPermissions?.userDocuments,
          onCreate: () {},
          onView: () {},
        ),
      );
    }

    // Add a separator if items follow
    if (items.length > 1 &&
            (userPermissions?.campaigns.any((perm) => perm) ?? false) ||
        (userPermissions?.leads.any((perm) => perm) ?? false) ||
        (userPermissions?.socialMediaContents.any((perm) => perm) ?? false)) {
      items.add(DottedLine(dashRadius: 10, dashColor: Colors.grey.shade300));
    }

    // Campaigns
    if (userPermissions?.campaigns.any((perm) => perm) ?? false) {
      items.add(
        _item(
          title: 'Campaigns',
          icon: 'assets/icons/ic_campaigns.svg',
          permissions: userPermissions?.campaigns,
          onCreate: () {},
          onView: () {},
        ),
      );
    }

    // Leads
    if (userPermissions?.leads.any((perm) => perm) ?? false) {
      items.add(
        _item(
          title: 'Leads',
          icon: 'assets/icons/ic_campaigns.svg',
          permissions: userPermissions?.leads,
          onCreate: () {},
          onView: () {},
        ),
      );
    }

    // Social Media Contents
    if (userPermissions?.socialMediaContents.any((perm) => perm) ?? false) {
      items.add(
        _item(
          title: 'Social Media Content',
          icon: 'assets/icons/ic_social_media.svg',
          permissions: userPermissions?.socialMediaContents,
          onCreate: () {},
          onView: () {},
        ),
      );
    }

    // Add a separator if items follow
    if (items.length > 1 &&
            (userPermissions?.banks.any((perm) => perm) ?? false) ||
        (userPermissions?.designations.any((perm) => perm) ?? false) ||
        (userPermissions?.rulebook.any((perm) => perm) ?? false) ||
        (userPermissions?.codingStandard.any((perm) => perm) ?? false) ||
        (userPermissions?.userComputerInfos.any((perm) => perm) ?? false) ||
        (userPermissions?.holiday.any((perm) => perm) ?? false)) {
      items.add(DottedLine(dashRadius: 10, dashColor: Colors.grey.shade300));
    }

    // Banks
    if (userPermissions?.banks.any((perm) => perm) ?? false) {
      items.add(
        _item(
          title: 'Banks',
          icon: 'assets/icons/ic_banks.svg',
          permissions: userPermissions?.banks,
          onCreate: () {},
          onView: () {},
        ),
      );
    }

    // Designations
    if (userPermissions?.designations.any((perm) => perm) ?? false) {
      items.add(
        _item(
          title: 'Designations',
          icon: 'assets/icons/ic_roles.svg',
          permissions: userPermissions?.designations,
          onCreate: () {},
          onView: () {},
        ),
      );
    }

    // Rulebook
    if (userPermissions?.rulebook.any((perm) => perm) ?? false) {
      items.add(
        _item(
          title: 'Commitment Book',
          icon: 'assets/icons/ic_generate_doc.svg',
          permissions: userPermissions?.rulebook,
          onCreate: () {},
          onView: () {},
        ),
      );
    }

    // Coding Standard
    if (userPermissions?.codingStandard.any((perm) => perm) ?? false) {
      items.add(
        _item(
          title: 'Coding Standards',
          icon: 'assets/icons/ic_coding.svg',
          permissions: userPermissions?.codingStandard,
          onCreate: () {},
          onView: () {},
        ),
      );
    }

    // Holiday
    if (userPermissions?.holiday.any((perm) => perm) ?? false) {
      items.add(
        _item(
          title: 'Holidays',
          icon: 'assets/icons/ic_holiday.svg',
          permissions: userPermissions?.holiday,
          onCreate: () {},
          onView: () {},
        ),
      );
    }

    return items;
  }

  void _showNotificationPopupMenu() {
    final RenderBox? renderBox =
        _profileButtonKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final Offset offset = renderBox.localToGlobal(Offset.zero);
    final Size size = renderBox.size;

    showMenu(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      menuPadding: const EdgeInsets.all(0),
      color: Colors.white,
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx + size.width - 300,
        offset.dy + size.height,
        offset.dx + size.width,
        offset.dy + size.height + 400,
      ),
      items: [
        PopupMenuItem(
          padding: EdgeInsets.zero,
          child: Container(
            width: 300,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Notifications',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  'You have 0 unread messages',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                SizedBox(height: 16),
                Divider(color: Colors.grey[300], height: 1),
                SizedBox(height: 16),
                // Notification Items
                ...[
                  NotificationItem(
                    initials: 'HM',
                    message:
                        'Manthan\'s leave request has been rejected from 18/10/2025 to 01/11/2025',
                    timeAgo: '1 days ago',
                  ),
                ],
                SizedBox(height: 16),
                Divider(color: Colors.grey[300], height: 1),
                SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text(
                      'View All',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showProfilePopupMenu() {
    final RenderBox? renderBox =
        _profileButtonKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final Offset offset = renderBox.localToGlobal(Offset.zero);
    final Size size = renderBox.size;

    showMenu(
      elevation: 2,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadiusGeometry.all(Radius.circular(10)),
      ),
      menuPadding: const EdgeInsets.all(10),
      color: Colors.white,
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx + size.width - 150,
        offset.dy + size.height,
        offset.dx + size.width,
        offset.dy + size.height + 200,
      ),
      items: [
        _buildPopupMenuItem(
          'assets/icons/ic_changePassword.svg',
          'Change Password',
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ChangePasswordScreen()),
          ),
        ),
        _buildPopupMenuItem(
          'assets/icons/ic_user_activities.svg',
          'Account Activity',
          () {},
        ),
        _buildPopupMenuItem(
          'assets/icons/ic_codingSetting.svg',
          'Coding Standard',
          () {},
        ),
        _buildPopupMenuItem(
          'assets/icons/ic_generate_doc.svg',
          'Commitment Book',
          () {},
        ),
        _buildPopupMenuItem(
          'assets/icons/ic_user_computer_info.svg',
          'Your Device Info',
          () {},
        ),
        _buildPopupMenuItem('assets/icons/ic_vehicle.svg', 'Vehicles', () {}),
        _buildPopupMenuItem('assets/icons/ic_policy.svg', 'Policy', () {}),
        const PopupMenuItem(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.settings, color: Colors.grey),
              SizedBox(width: 8),
              Text(
                'Settings',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          onTap: () async {
            // Show confirmation dialog
            final shouldLogout = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Logout'),
                content: const Text('Are you sure you want to logout?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Logout'),
                  ),
                ],
              ),
            );

            if (shouldLogout == true) {
              // Clear login state and navigate to login screen
              await AuthService.logout();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              }
            }
          },
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.logout, color: Colors.grey),
              SizedBox(width: 8),
              Text(
                'Log Out',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ),
      ],
    );
  }

  PopupMenuItem _buildPopupMenuItem(String iconPath, String title, onTap) {
    return PopupMenuItem(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            iconPath,
            width: 20,
            height: 20,
            colorFilter: const ColorFilter.mode(Colors.grey, BlendMode.srcIn),
          ),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontSize: 14, color: Colors.grey)),
        ],
      ),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      drawer: _buildDrawer(),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            surfaceTintColor: Colors.white.withOpacity(1),
            shadowColor: Colors.white,
            backgroundColor: Colors.white.withOpacity(0.8),
            elevation: 1,
            pinned: true,
            automaticallyImplyLeading: false,
            leading: IconButton(
              icon: const Icon(Icons.menu, color: Colors.black87),
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            ),
            actions: [
              kIsWeb
                  ? Row(
                      children: [
                        ElevatedButton(
                          onPressed: () {},
                          child: Text(
                            widget.result?['data']['user']['quarter'] ?? 'Q1',
                            style: TextStyle(fontSize: 14),
                          ),
                          style: ElevatedButton.styleFrom(
                            foregroundColor: primaryColor,
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              side: BorderSide(color: primaryColor),
                              borderRadius: BorderRadiusGeometry.all(
                                Radius.circular(20),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 10),
                        IconButton(
                          onPressed: () {},
                          icon: const Icon(
                            Icons.autorenew,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    )
                  : ElevatedButton(
                      onPressed: () {},
                      child: Text(
                        widget.result?['data']['user']['quarter'] ?? 'Q1',
                        style: TextStyle(fontSize: 12),
                      ),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: primaryColor,
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          side: BorderSide(color: primaryColor),
                          borderRadius: BorderRadiusGeometry.all(
                            Radius.circular(20),
                          ),
                        ),
                      ),
                    ),
              IconButton(
                onPressed: () {
                  _showNotificationPopupMenu();
                },
                icon: const Icon(
                  Icons.notifications_outlined,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) =>
                            UpdateProfilePicturePopup(context),
                      );
                    },
                    child: const CircleAvatar(
                      radius: 16,
                      backgroundImage: AssetImage(
                        'assets/images/rsLogo167.png',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    key: _profileButtonKey,
                    onTap: _showProfilePopupMenu,
                    child: Row(
                      children: [
                        Text(
                          widget.result?['data']['user']['first_name'],
                          style: TextStyle(fontSize: 14, color: Colors.black87),
                        ),
                        SizedBox(width: 5),
                        Text(
                          widget.result?['data']['user']['last_name'],
                          style: TextStyle(fontSize: 14, color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
              ),
            ],
            flexibleSpace: Container(
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey, width: 0.5),
                ),
              ),
            ),
          ),
        ],
      ),
      // Floating Action Button for testing calendar service
      // floatingActionButton: FloatingActionButton.extended(
      //   onPressed: () {
      //     Navigator.push(
      //       context,
      //       MaterialPageRoute(builder: (context) => const TestCalendarScreen()),
      //     );
      //   },
      //   backgroundColor: Colors.blue,
      //   foregroundColor: Colors.white,
      //   icon: const Icon(Icons.calendar_today),
      //   label: const Text('Test Calendar'),
      // ),
    );
  }

  Widget _buildDrawer() {
    return Container(
      width: 350,
      color: Colors.white,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(
              right: 20,
              left: 20,
              bottom: 20,
              top: 30,
            ),
            child: Image.asset(
              'assets/images/Full_Logo.png',
              height: 50,
              width: 200,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.business, size: 50);
              },
            ),
          ),

          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: const Color.fromRGBO(145, 158, 171, 0.12),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 22,
                  backgroundImage: AssetImage('assets/images/rsLogo167.png'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            widget.result?['data']['user']['first_name']
                                as String,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 5),
                          Text(
                            widget.result?['data']['user']['last_name']
                                as String,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        widget.result?['data']['user']['username'] as String,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text(
                  'GENERAL',
                  style: TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: _buildDrawerItems(),
            ),
          ),
        ],
      ),
    );
  }
}

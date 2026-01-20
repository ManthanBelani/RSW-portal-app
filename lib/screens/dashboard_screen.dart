import 'package:dashboard_clone/constants/constants.dart';
import 'package:dashboard_clone/screens/change_password_screen.dart';
import 'package:dashboard_clone/screens/coding_standards.dart';
import 'package:dashboard_clone/screens/leave_request_screen.dart';
import 'package:dashboard_clone/screens/policy_screen.dart';
import 'package:dashboard_clone/screens/resource_managment_screen.dart';
import 'package:dashboard_clone/screens/task_screen.dart';
import 'package:dashboard_clone/screens/test_calender.dart';
import 'package:dashboard_clone/screens/view_invoice_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:dotted_line/dotted_line.dart';
// import 'package:rsw_portal/constants/constants.dart';
// import 'package:rsw_portal/screens/task_screen.dart';
import '../models/dashboard_data_model.dart';
import '../models/user_permission_model.dart';
import '../models/notification_model.dart';
import '../services/dashboard_small_container_service.dart';
import '../services/notification_service.dart';
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
import 'notes_screen.dart';
import 'vehicle_screen.dart';
import 'test_calendar_screen.dart';
import 'view_activity_screen.dart';

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
  int absentTodayCount = 0;
  bool _isRefreshing = false;
  int _refreshKey = 0;

  List<NotificationModel> notifications = [];
  bool isLoadingNotifications = false;
  int unreadNotificationCount = 0;

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
    _loadNotifications();
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
          true,
          true,
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

  Future<void> _loadNotifications() async {
    try {
      setState(() {
        isLoadingNotifications = true;
      });

      final response = await NotificationService.getNotificationData();

      if (response != null && response['success'] == true) {
        final notificationResponse = NotificationResponse.fromJson(response);

        setState(() {
          notifications = notificationResponse.notifications;
          unreadNotificationCount = notificationResponse.unreadCount;
        });
      }
    } catch (e) {
      print('Error loading notifications: $e');
    } finally {
      setState(() {
        isLoadingNotifications = false;
      });
    }
  }

  Future<void> _refreshAllData() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    try {
      await Future.wait([_loadDashboardData(), _loadNotifications()]);
      setState(() {
        _refreshKey++;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Dashboard refreshed successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error refreshing dashboard: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error refreshing dashboard: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  Widget _getCurrentPageContent() {
    switch (selectedMenuItem) {
      case 'Dashboard':
        return _buildDashboardContent();
      case 'Resource Management':
        return ResourceManagementScreen();
      case 'Tasks':
        return TaskScreen(permissions: userPermissions?.tasks);
      case 'Attendance':
        return AttendanceScreen();
      case 'Invoices':
        return const ViewInvoiceScreen();
      case 'Leave Request':
        return const LeaveRequestScreen();
      case 'Notes':
        return const NotesScreen();
      case 'Commitment Book':
        return const TestCalender();
      case 'Change Password':
        return const ChangePasswordScreen();
      case 'Account Activity':
        return const ViewActivityScreen();
      case 'Policy':
        return const PolicyScreen();
      case 'Coding Standard':
        return const CodingStandards();
      case 'Vehicles':
        final userName =
            '${widget.result?['data']?['user']?['first_name'] ?? ''} ${widget.result?['data']?['user']?['last_name'] ?? ''}'
                .trim();
        return VehicleScreen(currentUserName: userName);
      default:
        return _buildDashboardContent();
    }
  }

  List<Widget> _buildDrawerItems() {
    List<Widget> items = [];

    Widget _item({
      required String title,
      required String icon,
      List<bool>? permissions,
      VoidCallback? onCreate,
      VoidCallback? onView,
      VoidCallback? onTileTap,
    }) {
      final isSelected = selectedMenuItem == title;
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
        permissions: [true, true, true, true], // Dashboard always accessible
        onTileTap: () {
          setState(() {
            selectedMenuItem = 'Dashboard';
          });
          Navigator.pop(context);
        },
      ),
    );

    // Attendance - Bypassing permissions for testing
    items.add(
      _item(
        title: 'Attendance',
        icon: 'assets/icons/ic_attendance.svg',
        permissions: [true, true, true, true], // Bypass permissions
        onCreate: () {
          setState(() {
            selectedMenuItem = 'Attendance';
          });
          Navigator.pop(context);
        },
        onView: () {
          setState(() {
            selectedMenuItem = 'Attendance';
          });
          Navigator.pop(context);
        },
        onTileTap: () {
          setState(() {
            selectedMenuItem = 'Attendance';
          });
          Navigator.pop(context);
        },
      ),
    );

    // Resource Management
    if (userPermissions?.resourceManagement.any((perm) => perm) ?? false) {
      items.add(
        _item(
          title: 'Resource Management',
          icon: 'assets/icons/resource.svg',
          permissions: userPermissions?.resourceManagement,
          onCreate: () {
            setState(() {
              selectedMenuItem = 'Resource Management';
            });
            Navigator.pop(context);
          },
          onView: () {
            setState(() {
              selectedMenuItem = 'Resource Management';
            });
            Navigator.pop(context);
          },
          onTileTap: () {
            setState(() {
              selectedMenuItem = 'Resource Management';
            });
            Navigator.pop(context);
          },
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
          onTileTap: () {
            setState(() {
              selectedMenuItem = 'Invoices';
            });
            Navigator.pop(context);
          },
          onView: () {},
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
          onView: () {},
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
          onTileTap: () {
            setState(() {
              selectedMenuItem = 'Leave Request';
            });
            Navigator.pop(context);
          },
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

    // Notes - Bypassing permissions for testing
    items.add(
      _item(
        title: 'Notes',
        icon: 'assets/icons/ic_edit_notes.svg',
        permissions: [true, true, true, true], // Bypass permissions
        onCreate: () {
          setState(() {
            selectedMenuItem = 'Notes';
          });
          Navigator.pop(context);
        },
        onView: () {
          setState(() {
            selectedMenuItem = 'Notes';
          });
          Navigator.pop(context);
        },
        onTileTap: () {
          setState(() {
            selectedMenuItem = 'Notes';
          });
          Navigator.pop(context);
        },
      ),
    );

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
            constraints: BoxConstraints(maxHeight: 400),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Notifications',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  'You have $unreadNotificationCount unread message${unreadNotificationCount != 1 ? 's' : ''}',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                SizedBox(height: 16),
                Divider(color: Colors.grey[300], height: 1),
                SizedBox(height: 16),
                // Notification Items
                if (isLoadingNotifications)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                      ),
                    ),
                  )
                else if (notifications.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        'No notifications available',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: notifications.length > 5
                          ? 5
                          : notifications.length,
                      separatorBuilder: (context, index) => SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final notification = notifications[index];
                        return NotificationItem(
                          initials: notification.getInitials(),
                          message: notification.message,
                          timeAgo: notification.getTimeAgo(),
                          backgroundColor: notification.isRead == 0
                              ? Colors.blue.shade50
                              : null,
                          initialsBackgroundColor: notification.isRead == 0
                              ? Colors.blue.shade100
                              : Colors.grey.shade100,
                          initialsColor: notification.isRead == 0
                              ? Colors.blue.shade700
                              : Colors.grey.shade600,
                        );
                      },
                    ),
                  ),
                if (notifications.isNotEmpty) ...[
                  SizedBox(height: 16),
                  Divider(color: Colors.grey[300], height: 1),
                  SizedBox(height: 16),
                  Center(
                    child: TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        // TODO: Navigate to full notifications screen
                      },
                      child: Text(
                        'View All (${notifications.length})',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
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
        PopupMenuItem(
          onTap: () {
            Future.delayed(Duration.zero, () {
              setState(() {
                selectedMenuItem = 'Change Password';
              });
            });
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(
                'assets/icons/ic_changePassword.svg',
                width: 20,
                height: 20,
                colorFilter: const ColorFilter.mode(
                  Colors.grey,
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Change Password',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          onTap: () {
            Future.delayed(Duration.zero, () {
              setState(() {
                selectedMenuItem = 'Account Activity';
              });
            });
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(
                'assets/icons/ic_user_activities.svg',
                width: 20,
                height: 20,
                colorFilter: const ColorFilter.mode(
                  Colors.grey,
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Account Activity',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ),
        // _buildPopupMenuItem(
        //   'assets/icons/ic_user_activities.svg',
        //   'Account Activity',
        //   () {
        //     Navigator.push(
        //       context,
        //       MaterialPageRoute(builder: (context) => ViewActivityScreen()),
        //     );
        //   },
        // ),
        PopupMenuItem(
          onTap: () {
            Future.delayed(Duration.zero, () {
              setState(() {
                selectedMenuItem = 'Coding Standard';
              });
            });
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(
                'assets/icons/ic_codingSetting.svg',
                width: 20,
                height: 20,
                colorFilter: const ColorFilter.mode(
                  Colors.grey,
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Coding Standard',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ),

        // _buildPopupMenuItem(
        //   'assets/icons/ic_codingSetting.svg',
        //   'Coding Standard',
        //   () {
        //     Navigator.push(
        //       context,
        //       MaterialPageRoute(builder: (context) => CodingStandards()),
        //     );
        //   },
        // ),
        PopupMenuItem(
          onTap: () {
            Future.delayed(Duration.zero, () {
              setState(() {
                selectedMenuItem = 'Commitment Book';
              });
            });
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(
                'assets/icons/ic_generate_doc.svg',
                width: 20,
                height: 20,
                colorFilter: const ColorFilter.mode(
                  Colors.grey,
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Commitment Book',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ),
        // _buildPopupMenuItem(
        //   'assets/icons/ic_generate_doc.svg',
        //   'Commitment Book',
        //   () {},
        // ),
        _buildPopupMenuItem(
          'assets/icons/ic_user_computer_info.svg',
          'Your Device Info',
          () {},
        ),
        PopupMenuItem(
          onTap: () {
            Future.delayed(Duration.zero, () {
              setState(() {
                selectedMenuItem = 'Vehicles';
              });
            });
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(
                'assets/icons/ic_vehicle.svg',
                width: 20,
                height: 20,
                colorFilter: const ColorFilter.mode(
                  Colors.grey,
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Vehicles',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          onTap: () {
            Future.delayed(Duration.zero, () {
              setState(() {
                selectedMenuItem = 'Policy';
              });
            });
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(
                'assets/icons/ic_policy.svg',
                width: 20,
                height: 20,
                colorFilter: const ColorFilter.mode(
                  Colors.grey,
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Policy',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ),
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
                onPressed: _isRefreshing ? null : _refreshAllData,
                icon: _isRefreshing
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            primaryColor,
                          ),
                        ),
                      )
                    : const Icon(Icons.sync, color: Colors.black87),
              ),
              Stack(
                children: [
                  IconButton(
                    onPressed: () {
                      _showNotificationPopupMenu();
                    },
                    icon: const Icon(
                      Icons.notifications_outlined,
                      color: Colors.black87,
                    ),
                  ),
                  if (unreadNotificationCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          unreadNotificationCount > 99
                              ? '99+'
                              : '$unreadNotificationCount',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
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
          SliverToBoxAdapter(child: _getCurrentPageContent()),
        ],
      ),
    );
  }

  // Dashboard content widget
  Widget _buildDashboardContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          children: [
            // Top Grid Cards
            LayoutBuilder(
              builder: (context, constraints) {
                int crossAxisCount = 2;
                if (constraints.maxWidth >= 1200) {
                  crossAxisCount = 6;
                } else if (constraints.maxWidth >= 900) {
                  crossAxisCount = 3;
                } else if (constraints.maxWidth >= 600) {
                  crossAxisCount = 2;
                }
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 2.0,
                    children: List.generate(
                      6,
                      (index) => DashboardTopWidget(
                        index: index,
                        dashboardData: dashboardData,
                        isLoading: isLoading,
                        absentTodayCount: absentTodayCount,
                      ),
                    ),
                  ),
                );
              },
            ),
            // Main Content Area
            LayoutBuilder(
              builder: (context, constraints) {
                double containerWidth;
                if (constraints.maxWidth >= 1200) {
                  // Three column layout
                  containerWidth = (constraints.maxWidth - 60) / 3;
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.only(
                            left: 20,
                            right: 10,
                            top: 0,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey.shade300),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: CalendarWidget(showLegend: true),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(
                            left: 10.0,
                            right: 10.0,
                            top: 0.0,
                          ),
                          child:
                              widget.result?['data']?['user']?['username'] ==
                                  'admin'
                              ? SizedBox()
                              : TeamMembersBox(
                                  key: ValueKey('teamMembers_$_refreshKey'),
                                ),
                        ),
                      ),
                      Expanded(
                        child: UpcomingHolidaysContainer(
                          key: ValueKey('holidays_$_refreshKey'),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Expanded(
                        child: FillHoursContainer(
                          key: ValueKey('fillHours_$_refreshKey'),
                        ),
                      ),
                    ],
                  );
                } else if (constraints.maxWidth >= 900) {
                  // Two column layout
                  containerWidth = (constraints.maxWidth - 40) / 2;
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(
                                left: 20,
                                right: 10,
                                top: 0,
                                bottom: 10,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.grey.shade300),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: CalendarWidget(showLegend: true),
                            ),
                            UpcomingHolidaysContainer(
                              key: ValueKey('holidays_$_refreshKey'),
                            ),
                            const SizedBox(height: 20),
                            FillHoursContainer(
                              key: ValueKey('fillHours_$_refreshKey'),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 0.0, left: 10.0),
                          child:
                              widget.result?['data']?['user']?['username'] ==
                                  'admin'
                              ? SizedBox()
                              : TeamMembersBox(
                                  key: ValueKey('teamMembers_$_refreshKey'),
                                ),
                        ),
                      ),
                    ],
                  );
                } else {
                  // Single column layout
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(
                          left: 20,
                          right: 20,
                          top: 0,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade300),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: CalendarWidget(
                          key: ValueKey('calendar_$_refreshKey'),
                          showLegend: true,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                          top: 10.0,
                          bottom: 10,
                          left: 20,
                          right: 20,
                        ),
                        child:
                            widget.result?['data']?['user']?['username'] ==
                                'admin'
                            ? SizedBox()
                            : TeamMembersBox(
                                key: ValueKey('teamMembers_$_refreshKey'),
                              ),
                      ),
                      UpcomingHolidaysContainer(
                        key: ValueKey('holidays_$_refreshKey'),
                      ),
                      const SizedBox(height: 20),
                      widget.result?['data']?['user']?['username'] == 'admin' ||
                              widget.result?['data']?['user']?['username'] ==
                                  'management'
                          ? TodayLeaveListContainer(
                              key: ValueKey('todayLeave_$_refreshKey'),
                              onCountChanged: (count) {
                                setState(() {
                                  absentTodayCount = count;
                                });
                              },
                            )
                          : SizedBox(),
                      const SizedBox(height: 20),
                      FillHoursContainer(
                        key: ValueKey('fillHours_$_refreshKey'),
                      ),
                      const SizedBox(height: 20),
                      widget.result?['data']?['user']?['username'] == 'admin'
                          ? PendingInvoiceContainer(
                              key: ValueKey('pendingInvoice_$_refreshKey'),
                            )
                          : SizedBox(),
                      const SizedBox(height: 20),
                      widget.result?['data']?['user']?['username'] == 'admin' ||
                              widget.result?['data']?['user']?['username'] ==
                                  'management'
                          ? LeaveRequestContainer(
                              key: ValueKey('leaveRequest_$_refreshKey'),
                            )
                          : SizedBox(),
                    ],
                  );
                }
              },
            ),
          ],
        );
      },
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

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:shimmer/shimmer.dart';
import '../models/dashboard_data_model.dart';

class DashboardTopWidget extends StatelessWidget {
  final int index;
  final DashboardData? dashboardData;
  final bool isLoading;
  final int? absentTodayCount;

  const DashboardTopWidget({
    super.key,
    required this.index,
    this.dashboardData,
    this.isLoading = false,
    this.absentTodayCount,
  });

  static const List<Color> _cardColors = [
    Color(0xFFEF5350), // Red
    Color(0xFF66BB6A), // Green
    Color(0xFF42A5F5), // Blue
    Color(0xFFFF9800), // Orange
    Color(0xFF9C27B0), // Purple
    Color(0xFF757575), // Grey
  ];

  static const List<Map<String, String>> _defaultCardData = [
    {
      'value': '0',
      'label': 'Projects',
      'icon': 'assets/icons/ic_projects.svg',
    },
    {
      'value': '0',
      'label': 'Billable Tasks',
      'icon': 'assets/icons/tdesign--money.svg',
    },
    {
      'value': '0',
      'label': 'Non-Billable Tasks',
      'icon': 'assets/icons/ic--outline-money-off.svg',
    },
    {
      'value': '0',
      'label': 'Clients',
      'icon': 'assets/icons/ic_clients.svg',
    },
    {
      'value': '0',
      'label': 'Users',
      'icon': 'assets/icons/ic_users.svg',
    },
    {
      'value': '0',
      'label': 'Projects By Client',
      'icon': 'assets/icons/resource.svg',
    },
  ];

  Map<String, String> _getCardData(int index) {
    // If index is 5, show "Absent Today" with count from leave data
    if (index == 5) {
      return {
        'value': (absentTodayCount ?? 0).toString(),
        'label': 'Absent Today',
        'icon': 'assets/icons/absent-emp.svg',
      };
    }
    
    // If dashboard data is available, use it; otherwise, use default values
    if (dashboardData != null) {
      switch (index) {
        case 0:
          return {
            'value': dashboardData!.project.toString(),
            'label': dashboardData!.projectLabel ?? 'Projects',
            'icon': 'assets/icons/ic_projects.svg',
          };
        case 1:
          return {
            'value': dashboardData!.billableTask.toString(),
            'label': dashboardData!.billableTaskLabel ?? 'Billable Tasks',
            'icon': 'assets/icons/tdesign--money.svg',
          };
        case 2:
          return {
            'value': dashboardData!.nonbillableTask.toString(),
            'label':
                dashboardData!.nonbillableTaskLabel ?? 'Non-Billable Tasks',
            'icon': 'assets/icons/ic--outline-money-off.svg',
          };
        case 3:
          return {
            'value': dashboardData!.client.toString(),
            'label': dashboardData!.clientLabel ?? 'Clients',
            'icon': 'assets/icons/ic_clients.svg',
          };
        case 4:
          return {
            'value': dashboardData!.user.toString(),
            'label': dashboardData!.userLabel ?? 'Users',
            'icon': 'assets/icons/ic_users.svg',
          };
        default:
          return _defaultCardData[index];
      }
    } else {
      return _defaultCardData[index];
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 60,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 80,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      final data = _getCardData(index);
      final screenWidth = MediaQuery.of(context).size.width;
      final screenHeight = MediaQuery.of(context).size.height;

      double containerHeight = screenHeight * 0.12;
      containerHeight = containerHeight.clamp(100, 160);

      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      data['value']!,
                      style: TextStyle(
                        fontSize: containerHeight * 0.16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      data['label']!,
                      style: TextStyle(
                        fontSize: containerHeight * 0.08,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              CircleAvatar(
                radius: containerHeight * 0.15,
                backgroundColor: _cardColors[index % _cardColors.length].withOpacity(0.15),
                child: Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: SvgPicture.asset(
                    data['icon']!,
                    width: containerHeight * 0.2,
                    height: containerHeight * 0.2,
                    fit: BoxFit.contain,
                    colorFilter: ColorFilter.mode(
                      _cardColors[index % _cardColors.length],
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }
}

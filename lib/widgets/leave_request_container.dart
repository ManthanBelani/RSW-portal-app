import 'package:dashboard_clone/services/leave_request_service.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../services/crud_leave_service.dart';
import 'elevated_button.dart';

class LeaveRequestContainer extends StatefulWidget {
  const LeaveRequestContainer({super.key});

  @override
  State<LeaveRequestContainer> createState() => _LeaveRequestContainerState();
}

class _LeaveRequestContainerState extends State<LeaveRequestContainer> {
  var _leaveRequestData = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLeaveRequestData();
  }

  Future<void> _loadLeaveRequestData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await LeaveRequestService.getLeaveRequestDashboardData();
      if (mounted) {
        setState(() {
          _leaveRequestData = result?['data'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _leaveRequestData = [];
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleLeaveAction(
    Future<Map<String, dynamic>?> Function() action,
    String itemId,
  ) async {
    final result = await action();
    if (result != null && result['success'] == true) {
      // Optimistically remove the item from the list
      setState(() {
        _leaveRequestData.removeWhere(
          (item) => item['id'].toString() == itemId,
        );
      });
      // Reload data without showing loading state
      try {
        final result = await LeaveRequestService.getLeaveRequestDashboardData();
        if (mounted) {
          setState(() {
            _leaveRequestData = result?['data'] ?? [];
          });
        }
      } catch (e) {
        // Keep the optimistically updated list if reload fails
        print('Failed to reload leave requests: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _leaveRequestData.isEmpty
        ? SizedBox()
        : Container(
            margin: const EdgeInsets.only(left: 20, right: 20, top: 0),
            constraints: const BoxConstraints(maxHeight: 400),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300),
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
                Container(
                  height: 70,
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(10),
                      topRight: Radius.circular(10),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'Leave Requests',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: _isLoading
                      ? ListView.separated(
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: 3,
                          separatorBuilder: (context, index) =>
                              Divider(height: 1, color: Colors.grey[300]),
                          itemBuilder: (context, index) => Shimmer.fromColors(
                            baseColor: Colors.grey[300]!,
                            highlightColor: Colors.grey[100]!,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: 120,
                                          height: 16,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Container(
                                          width: 180,
                                          height: 14,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 15),
                                  Column(
                                    children: [
                                      Container(
                                        width: 100,
                                        height: 14,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Container(
                                        width: 80,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 10),
                                  Row(
                                    children: [
                                      Container(
                                        width: 24,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        width: 24,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        width: 24,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      : _leaveRequestData.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(20),
                          child: Center(
                            child: Text(
                              'No leave requests at the moment',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        )
                      : ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: _leaveRequestData.length,
                          separatorBuilder: (context, index) =>
                              Divider(height: 1, color: Colors.grey[300]),
                          itemBuilder: (context, index) {
                            final leaveDateFrom =
                                _leaveRequestData[index]['leavedate_from'] ??
                                '';
                            final leaveDateTo =
                                _leaveRequestData[index]['leavedate_to'] ?? '';
                            final reason =
                                _leaveRequestData[index]['reason'] ?? '';
                            final leaveCount =
                                _leaveRequestData[index]['leave_count'] ?? '';
                            final name = _leaveRequestData[index]['name'] ?? '';
                            final leaveDay =
                                _leaveRequestData[index]['leaveday'] ?? '';
                            final fromDayName =
                                (_leaveRequestData[index]['from_day_name'] ??
                                        '')
                                    .substring(0, 3);
                            final id = (_leaveRequestData[index]['id'] ?? '')
                                .toString();
                            final userId =
                                (_leaveRequestData[index]['user_id'] ?? '')
                                    .toString();

                            String leaveDesc;
                            if (leaveDay == 'fl') {
                              leaveDesc = 'Full Leave';
                            } else if (leaveDay == 'hl1') {
                              leaveDesc = 'First Half Leave';
                            } else if (leaveDay == 'hl2') {
                              leaveDesc = 'Second Half Leave';
                            } else if (leaveDay == 'ml') {
                              leaveDesc = 'More Day Leave';
                            } else {
                              leaveDesc = 'Unknown Leave Type';
                            }

                            String leaveDate;
                            if (leaveDay == 'fl' ||
                                leaveDay == 'hl1' ||
                                leaveDay == 'hl2') {
                              leaveDate = '$leaveDateFrom($fromDayName)';
                            } else if (leaveDay == 'ml' &&
                                leaveDateTo.isNotEmpty) {
                              leaveDate = '$leaveDateFrom to $leaveDateTo';
                            } else {
                              leaveDate = leaveDateFrom;
                            }

                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '$name ($leaveCount)',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          reason,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(width: 15),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Text(
                                          leaveDate,
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                        Text(
                                          leaveDesc,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                    IconButton(
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (BuildContext dialogContext) {
                                            return AlertDialog(
                                              backgroundColor: Colors.white,
                                              title: const Text(
                                                'Approve Leave',
                                              ),
                                              content: Text(
                                                'Are you sure you want to approve leave for $name?',
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () {
                                                    Navigator.of(
                                                      dialogContext,
                                                    ).pop();
                                                  },
                                                  child: const Text('Cancel'),
                                                ),
                                                ReusableButton(
                                                  text: 'Approve',
                                                  onPressed: () {
                                                    Navigator.of(
                                                      dialogContext,
                                                    ).pop();
                                                    _handleLeaveAction(
                                                      () =>
                                                          CrudLeaveService.approveUserLeave(
                                                            context: context,
                                                            fromdate:
                                                                leaveDateFrom,
                                                            todate: leaveDateTo,
                                                            id: id,
                                                            userId: userId,
                                                            leaveday: leaveDay,
                                                          ),
                                                      id,
                                                    );
                                                  },
                                                  backgroundColor: Colors.green,
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 24,
                                                        vertical: 12,
                                                      ),
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                      },
                                      icon: const Icon(
                                        size: 20,
                                        Icons.check_circle_outline,
                                        color: Colors.green,
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (BuildContext dialogContext) {
                                            return AlertDialog(
                                              backgroundColor: Colors.white,
                                              title: const Text('Reject Leave'),
                                              content: Text(
                                                'Are you sure you want to Reject leave for $name?',
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () {
                                                    Navigator.of(
                                                      dialogContext,
                                                    ).pop();
                                                  },
                                                  child: const Text('Cancel'),
                                                ),
                                                ReusableButton(
                                                  text: 'Reject',
                                                  onPressed: () {
                                                    Navigator.of(
                                                      dialogContext,
                                                    ).pop();
                                                    _handleLeaveAction(
                                                      () =>
                                                          CrudLeaveService.rejectUserLeave(
                                                            context: context,
                                                            fromdate:
                                                                leaveDateFrom,
                                                            todate: leaveDateTo,
                                                            id: id,
                                                            userId: userId,
                                                            leaveday: leaveDay,
                                                          ),
                                                      id,
                                                    );
                                                  },
                                                  backgroundColor:
                                                      Colors.orange,
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 24,
                                                        vertical: 12,
                                                      ),
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                      },
                                      icon: const Icon(
                                        size: 20,
                                        Icons.cancel_outlined,
                                        color: Colors.yellow,
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (BuildContext dialogContext) {
                                            return AlertDialog(
                                              backgroundColor: Colors.white,
                                              title: const Text('Delete Leave'),
                                              content: Text(
                                                'Are you sure you want to delete leave for $name?',
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () {
                                                    Navigator.of(
                                                      dialogContext,
                                                    ).pop();
                                                  },
                                                  child: const Text('Cancel'),
                                                ),
                                                ReusableButton(
                                                  text: 'Delete',
                                                  onPressed: () {
                                                    Navigator.of(
                                                      dialogContext,
                                                    ).pop();
                                                    _handleLeaveAction(
                                                      () =>
                                                          CrudLeaveService.deleteUserLeave(
                                                            context: context,
                                                            id: id,
                                                          ),
                                                      id,
                                                    );
                                                  },
                                                  backgroundColor: Colors.red,
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 24,
                                                        vertical: 12,
                                                      ),
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                      },
                                      icon: Icon(
                                        size: 20,
                                        Icons.delete,
                                        color: Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
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

import 'package:dashboard_clone/widgets/elevated_button.dart';
import 'package:flutter/material.dart';
import '../constants/constants.dart';
import '../services/activity_service.dart';
import '../widgets/reusable_data_table.dart';

class ViewActivityScreen extends StatefulWidget {
  const ViewActivityScreen({super.key});

  @override
  State<ViewActivityScreen> createState() => _ViewActivityScreenState();
}

class _ViewActivityScreenState extends State<ViewActivityScreen> {
  @override
  void initState() {
    super.initState();
    _getActivityData();
  }

  int _entriesPerPage = 10;
  bool _isLoading = false;
  List<Map<String, dynamic>> _activityData = [];
  TextEditingController _searchController = TextEditingController();

  void _showDeleteConfirmation(String deviceId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text('Confirm Delete'),
          content: const Text('Are you sure you want to remove this device?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ReusableButton(
              padding: EdgeInsets.all(10),
              fontSize: 16,
              text: 'Delete',
              onPressed: () {
                Navigator.of(context).pop();
                _handleRemoveDevice(deviceId);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleRemoveDevice(String deviceId) async {
    try {
      final response = await ActivityService.removeDevice(deviceId);

      if (response != null && response['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                response['message'] ?? 'Device removed successfully',
              ),
              backgroundColor: Colors.green,
            ),
          );
          _getActivityData();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response?['message'] ?? 'Failed to remove device'),
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

  Future<void> _handleDownloadLog() async {
    try {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Downloading log file...'),
            duration: Duration(seconds: 2),
          ),
        );
      }

      final response = await ActivityService.downloadLogOfActivitiesList(
        action: 'download',
      );

      if (response != null && response['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                response['message'] ?? 'Log downloaded successfully',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response?['message'] ?? 'Failed to download log'),
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

  Future<void> _handleDeleteLog() async {
    try {
      final response = await ActivityService.downloadLogOfActivitiesList(
        action: 'delete',
      );

      if (response != null && response['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? 'Log deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
          _getActivityData();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response?['message'] ?? 'Failed to delete log'),
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

  Future<void> _handleEnableDeviceNotification(
    String deviceId,
    int currentStatus,
  ) async {
    try {
      final newStatus = currentStatus == 1 ? 0 : 1;

      final response = await ActivityService.enableNotificationOfDevice(
        deviceId,
        newStatus,
      );

      if (response != null && response['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                newStatus == 1
                    ? 'Notifications enabled'
                    : 'Notifications disabled',
              ),
              backgroundColor: Colors.green,
            ),
          );
          _getActivityData();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                response?['message'] ?? 'Failed to update notification',
              ),
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

  Future<void> _getActivityData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      var response = await ActivityService.getActivitiesList(
        perPage: _entriesPerPage,
        search: _searchController.text,
      );

      if (response != null && response['success'] == true) {
        final data = response['data'];
        if (data != null && data['data'] != null) {
          setState(() {
            _activityData = List<Map<String, dynamic>>.from(data['data']);
          });
        }
      }
    } catch (e) {
      print('Error loading activity data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildSkeletonRow(int index) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: List.generate(
          6,
          (i) => Expanded(
            flex: i == 5 ? 1 : 2,
            child: Container(
              height: 16,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVehicleTable() {
    if (_isLoading) {
      return Column(
        children: List.generate(5, (index) => _buildSkeletonRow(index)),
      );
    }

    return Column(
      children: [
        if (_activityData.isEmpty)
          Container(
            padding: const EdgeInsets.all(40),
            child: Center(
              child: Text(
                'No Activities found',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            ),
          )
        else if (_activityData.isNotEmpty)
          ReusableDataTable(
            columns: [
              TableColumnConfig(
                title: 'Browser',
                flex: 1,
                builder: (data, index) => Text(
                  data['browser'] ?? '--',
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                ),
              ),
              TableColumnConfig(
                title: 'Device Platform',
                flex: 1,
                builder: (data, index) => Text(
                  data['device_name'] ?? '--',
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                ),
              ),
              TableColumnConfig(
                title: 'IP Address',
                flex: 1,
                builder: (data, index) => Text(
                  data['ip_address'] ?? '-',
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                ),
              ),
              TableColumnConfig(
                title: 'Last Login At',
                flex: 1,
                builder: (data, index) => Text(
                  data['last_login_at'] ?? '-',
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                ),
              ),
              TableColumnConfig(
                title: 'Created At',
                flex: 1,
                builder: (data, index) => Text(
                  data['created_at'] ?? '-',
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                ),
              ),
              TableColumnConfig(
                title: 'Actions',
                flex: 1,
                builder: (data, index) => Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        data['is_notification_enable'] == 1
                            ? Icons.remove_circle
                            : Icons.radio_button_checked,
                        color: data['is_notification_enable'] == 1
                            ? Colors.yellow
                            : Colors.green,
                        size: 18,
                      ),
                      onPressed: () => _handleEnableDeviceNotification(
                        data['id'].toString(),
                        data['is_notification_enable'] ?? 0,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      tooltip: data['is_notification_enable'] == 1
                          ? 'Disable notifications'
                          : 'Enable notifications',
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete,
                        color: Colors.red,
                        size: 18,
                      ),
                      onPressed: () =>
                          _showDeleteConfirmation(data['id'].toString()),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      tooltip: 'Remove device',
                    ),
                  ],
                ),
              ),
            ],
            data: _activityData,
          ),
        const SizedBox(height: 20),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[50],
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 10,),
              const Text(
                'View Account Activities',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Spacer(),
                  ReusableButton(
                    text: 'Download Log',
                    fontSize: 14,
                    padding: EdgeInsets.all(10),
                    backgroundColor: Colors.blueAccent,
                    onPressed: _handleDownloadLog,
                  ),
                  const SizedBox(width: 20),
                  ReusableButton(
                    text: 'Delete Log',
                    fontSize: 14,
                    padding: EdgeInsets.all(10),
                    backgroundColor: primaryColor,
                    onPressed: _handleDeleteLog,
                  ),
                ],
              ),

              const SizedBox(height: 20),
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
                    Row(
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
                                borderRadius: const BorderRadius.all(
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
                                  _getActivityData();
                                },
                              ),
                            ),
                            const Text(
                              ' entries',
                              style: TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                        const Spacer(),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: 300,
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) {
                          Future.delayed(
                            const Duration(milliseconds: 500),
                                () {
                              if (_searchController.text == value) {
                                _getActivityData();
                              }
                            },
                          );
                        },
                        decoration: InputDecoration(
                          hintText: 'Search',
                          hintStyle: TextStyle(color: Colors.grey[400]),
                          prefixIcon: Icon(
                            Icons.search,
                            color: Colors.grey[600],
                            size: 20,
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
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildVehicleTable(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

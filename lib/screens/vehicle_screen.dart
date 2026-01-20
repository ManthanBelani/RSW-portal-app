import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../constants/constants.dart';
import '../services/vehicle_service.dart';
import '../widgets/reusable_data_table.dart';

class VehicleScreen extends StatefulWidget {
  final String? currentUserName;
  
  const VehicleScreen({super.key, this.currentUserName});

  @override
  State<VehicleScreen> createState() => _VehicleScreenState();
}

class _VehicleScreenState extends State<VehicleScreen> {
  final TextEditingController _searchController = TextEditingController();
  int _entriesPerPage = 50;
  bool _isLoading = false;
  List<Map<String, dynamic>> _vehicleData = [];
  
  // For adding new vehicle row
  bool _isAddingRow = false;
  final TextEditingController _newPersonNameController = TextEditingController();
  final TextEditingController _newVehicleNameController = TextEditingController();
  final TextEditingController _newVehicleNumberController = TextEditingController();
  String _newWheeler = '2 wheeler';

  @override
  void initState() {
    super.initState();
    _loadVehicleData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _newPersonNameController.dispose();
    _newVehicleNameController.dispose();
    _newVehicleNumberController.dispose();
    super.dispose();
  }

  void _addNewRow() {
    setState(() {
      _isAddingRow = true;
    });
  }

  void _cancelNewRow() {
    setState(() {
      _isAddingRow = false;
      _newPersonNameController.clear();
      _newVehicleNameController.clear();
      _newVehicleNumberController.clear();
      _newWheeler = '2 wheeler';
    });
  }

  Future<void> _submitNewVehicle() async {
    // Validate fields
    if (_newVehicleNameController.text.isEmpty ||
        _newVehicleNumberController.text.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please fill in all fields'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      final result = await VehicleService.addVehicle(
        personName: widget.currentUserName ?? 'User',
        vehicleName: _newVehicleNameController.text,
        vehicleNumber: _newVehicleNumberController.text,
        wheelerType: _newWheeler,
      );

      if (result != null && result['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Vehicle added successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
        _cancelNewRow();
        await _loadVehicleData();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                result?['message'] ?? 'Failed to add vehicle',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Error adding vehicle: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleDelete(Map<String, dynamic> vehicle) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shadowColor: Colors.white,
        title: const Text('Confirm Delete'),
        content: Text(
          'Are you sure you want to delete ${vehicle['personName']}\'s vehicle?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final result = await VehicleService.deleteVehicle(
          vehicleId: vehicle['id'],
        );

        if (result != null && result['success'] == true) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Vehicle deleted successfully'),
                backgroundColor: Colors.green,
              ),
            );
          }
          // Reload the data after successful deletion
          await _loadVehicleData();
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  result?['message'] ?? 'Failed to delete vehicle',
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        print('Error deleting vehicle: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _loadVehicleData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await VehicleService.getVehicleList(
        perPage: _entriesPerPage,
        search: _searchController.text,
      );

      if (response != null && response['success'] == true) {
        print('Vehicle API Response: $response');

        if (response['data'] != null) {
          final responseData = response['data'];
          print('Response data keys: ${responseData.keys}');

          List dataList = [];
          if (responseData['data'] != null) {
            dataList = responseData['data'] as List;
          } else if (responseData['aaData'] != null) {
            dataList = responseData['aaData'] as List;
          }

          print('Data list length: ${dataList.length}');
          if (dataList.isNotEmpty) {
            print('First item: ${dataList[0]}');
          }

          setState(() {
            _vehicleData = dataList.map((vehicle) {
              return {
                'id': vehicle['id']?.toString() ?? '',
                'personName': vehicle['user_name'] ?? '',
                'wheeler': vehicle['2/4_wheeler'] ?? '',
                'vehicleName': vehicle['vehicle_name'] ?? '',
                'vehicleNumber': vehicle['vehicle_number'] ?? '',
              };
            }).toList();
          });

          print('Mapped vehicle data count: ${_vehicleData.length}');
        }
      } else {
        print('API response failed or success is false');
        print('Response: $response');
      }
    } catch (e) {
      print('Error loading vehicle data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading vehicles: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildSkeletonCell({required double height}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      alignment: Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: 0.7,
        child: Container(
          height: height,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }

  Widget _buildSkeletonRow(int index) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: index % 2 == 0 ? Colors.white : Colors.grey[50],
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Row(
          children: [
            Expanded(flex: 2, child: _buildSkeletonCell(height: 16)),
            Expanded(flex: 2, child: _buildSkeletonCell(height: 16)),
            Expanded(flex: 2, child: _buildSkeletonCell(height: 16)),
            Expanded(flex: 2, child: _buildSkeletonCell(height: 16)),
            Expanded(flex: 1, child: _buildSkeletonCell(height: 32)),
          ],
        ),
      ),
    );
  }

  Widget _buildEditableRow() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        // color: Colors.blue[50],
        // border: Border.all(color: Colors.blue[200]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                SizedBox(
                  width: 250,
                  child: TextField(
                    controller: TextEditingController(text: widget.currentUserName ?? 'User'),
                    readOnly: true,
                    decoration: InputDecoration(
                      hoverColor: primaryColor,
                      focusColor: primaryColor,
                      labelText: 'Person Name',
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    style: const TextStyle(color: Colors.black54),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 200,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: DropdownButton<String>(
                      borderRadius: BorderRadius.circular(10),
                      dropdownColor: Colors.white,
                      value: _newWheeler,
                      isExpanded: true,
                      underline: const SizedBox(),
                      items: ['2 wheeler', '4 wheeler']
                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _newWheeler = value!;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 250,
                  child: TextField(
                    controller: _newVehicleNameController,
                    decoration: InputDecoration(
                      labelText: 'Vehicle Name',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 250,
                  child: TextField(
                    controller: _newVehicleNumberController,
                    decoration: InputDecoration(
                      labelText: 'Vehicle Number',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton(
                onPressed: _cancelNewRow,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadiusGeometry.circular(10)),
                  backgroundColor: Colors.grey[400],
                  foregroundColor: Colors.white,
                ),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _submitNewVehicle,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadiusGeometry.circular(10)),
                  backgroundColor: const Color(0xFFFF1744),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Submit'),
              ),
            ],
          ),
        ],
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
        // Data table
        if (_vehicleData.isEmpty && !_isAddingRow)
          Container(
            padding: const EdgeInsets.all(40),
            child: Center(
              child: Text(
                'No vehicles found',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            ),
          )
        else if (_vehicleData.isNotEmpty)
          ReusableDataTable(
      columns: [
        // Person Name column
        TableColumnConfig(
          title: 'Person Name',
          flex: 2,
          builder: (data, index) => Text(
            data['personName'],
            style: const TextStyle(fontSize: 13, color: Colors.black87),
          ),
        ),
        // 2/4 Wheeler column
        TableColumnConfig(
          title: '2/4 Wheeler',
          flex: 2,
          builder: (data, index) => Text(
            data['wheeler'],
            style: const TextStyle(fontSize: 13, color: Colors.black87),
          ),
        ),
        // Vehicle Name column
        TableColumnConfig(
          title: 'Vehicle Name',
          flex: 2,
          builder: (data, index) => Text(
            data['vehicleName'],
            style: const TextStyle(fontSize: 13, color: Colors.black87),
          ),
        ),
        // Vehicle Number column
        TableColumnConfig(
          title: 'Vehicle Number',
          flex: 2,
          builder: (data, index) => Text(
            data['vehicleNumber'],
            style: const TextStyle(fontSize: 13, color: Colors.black87),
          ),
        ),
        // Actions column
        TableColumnConfig(
          title: 'Actions',
          flex: 1,
          builder: (data, index) => IconButton(
            icon: const Icon(Icons.delete, color: Colors.red, size: 18),
            onPressed: () => _handleDelete(data),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ),
      ],
      data: _vehicleData,
    ),
        
        const SizedBox(height: 20),
        
        // Editable row
        if (_isAddingRow) ...[
          _buildEditableRow(),
          const SizedBox(height: 12),
        ],
        
        // Add button at the end
        if (!_isAddingRow)
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: _addNewRow,
              icon: const Icon(Icons.add),
              label: const Text('Add Vehicle'),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadiusGeometry.circular(10)),
                backgroundColor: const Color(0xFFFF1744),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[50],
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              const Text(
                'Vehicles',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 20),

              // Table Section
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
                    // Show entries and Search
                    Row(
                      children: [
                        // Show entries dropdown
                        Row(
                          children: [
                            const Text('Show ', style: TextStyle(fontSize: 14)),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
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
                                  _loadVehicleData();
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
                        // Search field
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: 300,
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) {
                          // Debounce search
                          Future.delayed(
                            const Duration(milliseconds: 500),
                                () {
                              if (_searchController.text == value) {
                                _loadVehicleData();
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
                    // Table
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

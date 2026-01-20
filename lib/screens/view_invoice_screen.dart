import 'package:custom_date_range_picker/custom_date_range_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../constants/constants.dart';
import '../models/invoice_record.dart';
import '../services/invoice_service.dart';
import '../services/client_list.dart';
import '../widgets/reusable_data_table.dart';
import '../widgets/searchable_dropdown.dart';
import '../widgets/multi_select_dropdown.dart';
import '../widgets/percentage_border_chip.dart';
import 'package:shimmer/shimmer.dart';

import 'add_invoice_screen.dart';
import 'edit_invoice_screen.dart';

class ViewInvoiceScreen extends StatefulWidget {
  const ViewInvoiceScreen({super.key});

  @override
  State<ViewInvoiceScreen> createState() => _ViewInvoiceScreenState();
}

class _ViewInvoiceScreenState extends State<ViewInvoiceScreen> {
  // Filter states
  int _entriesPerPage = 50;
  String? _selectedClients;
  List<String> _selectedPaidStatuses = [];
  List<String> _selectedWorkStatuses = [];
  DateTimeRange? _selectedDateRange;
  String _searchQuery = '';
  bool _showArchivedOnly = false; // Archive filter

  // Data states
  List<Map<String, dynamic>> _clients = [];
  List<InvoiceRecord> _invoiceRecords = [];
  List<Map<String, dynamic>> _currencyTotals = [];
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';

  // Controllers
  late TextEditingController _dateController;
  late TextEditingController _searchController;

  // Pagination
  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    _dateController = TextEditingController();
    _searchController = TextEditingController();
    _loadDropdownData();
    _loadInvoices(); // Load default data
  }

  @override
  void dispose() {
    _dateController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openExpenseDialog(InvoiceRecord record) async {
    // Show loading dialog first
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          Center(child: CircularProgressIndicator(color: primaryColor)),
    );

    try {
      print('🔍 Opening expense dialog for invoice ID: ${record.id}');

      // Fetch detailed invoice data
      final response = await InvoiceService.getInvoiceById(record.id);

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      print('📦 Response received: ${response != null ? 'Yes' : 'No'}');
      if (response != null) {
        print('📋 Response keys: ${response.keys.toList()}');
        print('📋 Success: ${response['success']}');
      }

      if (response == null || response['success'] != true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to load expense details: ${response?['message'] ?? 'Unknown error'}',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final invoiceData = response['data'];
      print('📋 Invoice data keys: ${invoiceData?.keys.toList()}');

      final userDetails = invoiceData['user_details'] as List<dynamic>? ?? [];
      print('👥 User details count: ${userDetails.length}');

      final workInfo = invoiceData['work_info'] as Map<String, dynamic>? ?? {};
      print('💼 Work info keys: ${workInfo.keys.toList()}');

      // Extract data with multiple fallback options
      String workStartDate = '';
      String workEndDate = '';

      // Try work_info first, then direct invoice data
      if (workInfo.isNotEmpty) {
        workStartDate = workInfo['work_start_date']?.toString() ?? '';
        workEndDate = workInfo['work_end_date']?.toString() ?? '';
      }

      if (workStartDate.isEmpty) {
        workStartDate =
            invoiceData['work_start_date']?.toString() ??
            invoiceData['invoice_date']?.toString() ??
            '';
      }

      if (workEndDate.isEmpty) {
        workEndDate =
            invoiceData['work_end_date']?.toString() ??
            invoiceData['due_date']?.toString() ??
            '';
      }

      print('📅 Work dates: $workStartDate to $workEndDate');

      // Parse numeric values safely
      double expenseAmount = 0.0;
      try {
        final expenseValue = invoiceData['expense_amount'];
        expenseAmount = expenseValue is num
            ? expenseValue.toDouble()
            : double.tryParse(expenseValue?.toString() ?? '0') ?? 0.0;
      } catch (e) {
        print('⚠️ Error parsing expense_amount: $e');
      }

      double convertedExpenseAmount = 0.0;
      try {
        final convertedValue = invoiceData['converted_expense_amount'];
        convertedExpenseAmount = convertedValue is num
            ? convertedValue.toDouble()
            : double.tryParse(convertedValue?.toString() ?? '0') ?? 0.0;
      } catch (e) {
        print('⚠️ Error parsing converted_expense_amount: $e');
      }

      double todayCurrencyRate = 1.0;
      try {
        final rateValue = invoiceData['today_currency_rate'];
        todayCurrencyRate = rateValue is num
            ? rateValue.toDouble()
            : double.tryParse(rateValue?.toString() ?? '1') ?? 1.0;
      } catch (e) {
        print('⚠️ Error parsing today_currency_rate: $e');
      }

      print(
        '💰 Expense: $expenseAmount, Converted: $convertedExpenseAmount, Rate: $todayCurrencyRate',
      );

      // Calculate total hours
      double totalHours = 0.0;
      for (var user in userDetails) {
        final hours = user['total_hours'];
        final hoursValue = hours is num
            ? hours.toDouble()
            : double.tryParse(hours?.toString() ?? '0') ?? 0.0;
        totalHours += hoursValue;
      }

      print('⏱️ Total hours: $totalHours');

      // Show expense dialog
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Container(
                width: 600,
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.8,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Expense Amount Calculation [$workStartDate - $workEndDate]',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ),

                    // Table
                    Flexible(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: DataTable(
                                headingRowColor: MaterialStateProperty.all(
                                  Colors.grey[100],
                                ),
                                columns: const [
                                  DataColumn(
                                    label: Text(
                                      'User',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      'Start Date',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      'End Date',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      'Total Hours',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      'Rate',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      'Expense',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                                rows: userDetails.map<DataRow>((user) {
                                  final username = user['username'] ?? 'N/A';
                                  final startDate = user['start_date'] ?? '';
                                  final endDate = user['end_date'] ?? '';
                                  final hours =
                                      (user['total_hours'] as num?)
                                          ?.toDouble() ??
                                      0.0;
                                  final rate =
                                      (user['per_hour_salary'] as num?)
                                          ?.toDouble() ??
                                      0.0;
                                  final expense =
                                      (user['total_expense'] as num?)
                                          ?.toDouble() ??
                                      0.0;
                                  final currency = user['currency'] ?? '';

                                  return DataRow(
                                    color: WidgetStateColor.resolveWith(
                                      (states) => Colors.white,
                                    ),
                                    cells: [
                                      DataCell(Text(username)),
                                      DataCell(Text(startDate)),
                                      DataCell(Text(endDate)),
                                      DataCell(
                                        Text(
                                          hours.toStringAsFixed(1),
                                          style: const TextStyle(
                                            color: Colors.red,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          '${rate.toStringAsFixed(2)} $currency',
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          '${expense.toStringAsFixed(2)} $currency',
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),

                            // Summary Section
                            Container(
                              color: Colors.white,
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Divider(),
                                  const SizedBox(height: 10),
                                  _buildSummaryRow(
                                    'Total Hours',
                                    '$totalHours Hours',
                                  ),
                                  const SizedBox(height: 8),
                                  _buildSummaryRow(
                                    'Total Expense',
                                    '${_formatCurrency(expenseAmount)} ${userDetails.isNotEmpty ? userDetails[0]['currency'] ?? '' : ''}',
                                  ),
                                  const SizedBox(height: 8),
                                  _buildSummaryRow(
                                    'Conversion Rate',
                                    '1 ${record.currencyCode} = ${todayCurrencyRate.toStringAsFixed(2)} ${userDetails.isNotEmpty ? userDetails[0]['currency'] ?? '' : ''}',
                                  ),
                                  const SizedBox(height: 8),
                                  _buildSummaryRow(
                                    'Total Converted Expense',
                                    '${record.currencyCode} ${_formatCurrency(convertedExpenseAmount)}',
                                    // isBold: true,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }
    } catch (e) {
      // Close loading dialog if still open
      if (mounted) Navigator.pop(context);

      print('Error loading expense details: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading expense details: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: Colors.black87,
            ),
          ),
        ),
        const SizedBox(width: 20),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _loadDropdownData() async {
    try {
      final result = await ClientList.getClientList();
      if (!mounted) return;

      if (result != null && result['success'] == true) {
        final clientData = result['data'] as List<dynamic>;
        setState(() {
          _clients = clientData
              .map(
                (client) => {
                  'id': client['id']?.toString() ?? '',
                  'name': client['client_name'] ?? client['name'] ?? '',
                },
              )
              .toList();
        });
      } else {
        setState(() {
          _clients = [];
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _clients = [];
        });
      }
    }
  }

  Future<void> _loadInvoices() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      // Build filter parameters
      String? isPaidParam;
      if (_selectedPaidStatuses.isNotEmpty) {
        isPaidParam = _selectedPaidStatuses.join(',');
      }

      String? isCompletedParam;
      if (_selectedWorkStatuses.isNotEmpty) {
        isCompletedParam = _selectedWorkStatuses.join(',');
      }

      String? startDateParam;
      String? endDateParam;
      if (_selectedDateRange != null) {
        startDateParam = DateFormat(
          'yyyy-MM-dd',
        ).format(_selectedDateRange!.start);
        endDateParam = DateFormat('yyyy-MM-dd').format(_selectedDateRange!.end);
      }

      final response = await InvoiceService.getInvoiceList(
        perPage: _entriesPerPage,
        pageCount: _currentPage,
        search: _searchQuery.trim(),
        clientId: _selectedClients,
        startDate: startDateParam,
        endDate: endDateParam,
        isPaid: isPaidParam,
        isCompleted: isCompletedParam,
        isArchive: _showArchivedOnly ? 1 : 0, // Pass archive filter
      );

      if (!mounted) return;

      print('Invoice Response Keys: ${response.keys}');
      print('Invoice Response: $response');

      // Handle different response structures
      List<dynamic> invoiceData;
      List<dynamic> currencyTotalsData = [];

      if (response.containsKey('success') && response['success'] == true) {
        // Structure: {success: true, data: {data: [...]}}
        final dataObj = response['data'];
        if (dataObj is Map && dataObj.containsKey('data')) {
          invoiceData = dataObj['data'];
          // Extract currency totals
          if (dataObj.containsKey('currencyTotalRates')) {
            currencyTotalsData = dataObj['currencyTotalRates'];
          }
        } else if (dataObj is List) {
          invoiceData = dataObj;
        } else {
          invoiceData = [];
        }
      } else if (response.containsKey('data')) {
        // Structure: {data: [...]} or {data: {data: [...]}}
        final dataObj = response['data'];
        if (dataObj is Map && dataObj.containsKey('data')) {
          invoiceData = dataObj['data'];
          // Extract currency totals
          if (dataObj.containsKey('currencyTotalRates')) {
            currencyTotalsData = dataObj['currencyTotalRates'];
          }
        } else if (dataObj is List) {
          invoiceData = dataObj;
        } else {
          invoiceData = [];
        }
      } else if (response is List) {
        // Structure: [...]
        invoiceData = response as List<dynamic>;
      } else {
        // Unknown structure
        invoiceData = [];
      }

      print('Parsed invoice count: ${invoiceData.length}');
      final invoices = InvoiceService.parseInvoices(invoiceData);
      print('Invoice records created: ${invoices.length}');

      setState(() {
        _invoiceRecords = invoices;
        _currencyTotals = currencyTotalsData
            .map((e) => e as Map<String, dynamic>)
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      String errorMsg =
          'Network error. Please check your connection and try again.';
      if (e.toString().contains('Connection closed')) {
        errorMsg = 'Connection interrupted. Please try again.';
      } else if (e.toString().contains('SocketException')) {
        errorMsg = 'No internet connection. Please check your network.';
      } else if (e.toString().contains('TimeoutException')) {
        errorMsg = 'Request timed out. Please try again.';
      }

      setState(() {
        _hasError = true;
        _errorMessage = errorMsg;
        _isLoading = false;
      });
    }
  }

  void _updateDateText() {
    if (_selectedDateRange != null) {
      _dateController.text =
          '${DateFormat('dd/MM/yyyy').format(_selectedDateRange!.start)} - ${DateFormat('dd/MM/yyyy').format(_selectedDateRange!.end)}';
    } else {
      _dateController.text = '';
    }
  }

  void _openDateRangePicker() {
    showCustomDateRangePicker(
      context,
      dismissible: true,
      maximumDate: DateTime.now().add(const Duration(days: 365)),
      minimumDate: DateTime.now().subtract(const Duration(days: 365)),
      primaryColor: primaryColor,
      backgroundColor: Colors.white,
      startDate: _selectedDateRange?.start,
      endDate: _selectedDateRange?.end,
      onApplyClick: (DateTime startDate, DateTime endDate) {
        setState(() {
          _selectedDateRange = DateTimeRange(start: startDate, end: endDate);
          _updateDateText();
        });
      },
      onCancelClick: () {},
    );
  }

  void _applyFilters() {
    setState(() {
      _currentPage = 1;
    });
    _loadInvoices();
  }

  void _resetFilters() {
    setState(() {
      _selectedClients = null;
      _selectedPaidStatuses = [];
      _selectedWorkStatuses = [];
      _selectedDateRange = null;
      _searchQuery = '';
      _searchController.clear();
      _dateController.clear();
      _currentPage = 1;
    });
    _loadInvoices();
  }

  String _formatCurrency(dynamic value) {
    if (value == null) return '0.00';
    final numValue = value is String
        ? double.tryParse(value) ?? 0.0
        : value.toDouble();
    final formatter = NumberFormat('#,##0.00', 'en_US');
    return formatter.format(numValue);
  }

  void _showDatePicker(BuildContext context, InvoiceRecord record) {
    // Use current date if work end date is invalid
    final initialDate = record.workEndDate.year == 1970 
        ? DateTime.now() 
        : record.workEndDate;
    
    showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: primaryColor),
          ),
          child: child!,
        );
      },
    ).then((selectedDate) async {
      if (selectedDate != null) {
        print('📅 Updating work end date for invoice ${record.id} to $selectedDate');
        
        final formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate);
        
        try {
          final success = await InvoiceService.updateWorkEndDate(
            invoiceId: record.id,
            workEndDate: formattedDate,
          );

          if (success) {
            print('✅ Work end date updated successfully');
            
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✅ Work end date updated successfully'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 2),
                ),
              );
              
              // Reload invoices to show updated date
              _loadInvoices();
            }
          } else {
            print('❌ Failed to update work end date');
            
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('❌ Failed to update work end date'),
                  backgroundColor: Colors.red,
                  duration: Duration(seconds: 2),
                ),
              );
            }
          }
        } catch (e) {
          print('❌ Error updating work end date: $e');
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('❌ Error: $e'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      }
    });
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return Colors.green[100]!;
      case 'unpaid':
        return Colors.red[100]!;
      case 'partially paid':
        return Colors.orange[100]!;
      case 'completed':
        return Colors.green[100]!;
      case 'pending':
        return Colors.red[100]!;
      default:
        return Colors.grey[100]!;
    }
  }

  Color _getStatusTextColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return Colors.green[800]!;
      case 'unpaid':
        return Colors.red[800]!;
      case 'partially paid':
        return Colors.orange[800]!;
      case 'completed':
        return Colors.green[800]!;
      case 'pending':
        return Colors.red[700]!;
      default:
        return Colors.grey[800]!;
    }
  }

  InputDecoration _buildDropdownDecoration(String hint) {
    return InputDecoration(
      focusColor: Colors.white,
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[400]),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: primaryColor),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scaffold = Scaffold.maybeOf(context);
    final isEmbedded = scaffold != null;

    final content = SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [_buildHeader(), _buildFilterSection(), _buildTableSection()],
      ),
    );

    if (isEmbedded) {
      return Container(color: Colors.white, child: content);
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(child: content),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'View Invoices',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _showArchivedOnly = !_showArchivedOnly;
                    _currentPage = 1; // Reset to first page
                  });
                  _loadInvoices(); // Reload with archive filter
                },
                style: ElevatedButton.styleFrom(
                  foregroundColor: _showArchivedOnly
                      ? Colors.white
                      : primaryColor,
                  backgroundColor: _showArchivedOnly
                      ? primaryColor
                      : Colors.white,
                  shape: RoundedRectangleBorder(
                    side: BorderSide(color: primaryColor),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text(
                  _showArchivedOnly ? 'Archived' : 'Archived',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
          const Spacer(),
          Column(
            children: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: backButtonColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
                child: const Text('Back', style: TextStyle(fontSize: 15)),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AddInvoiceScreen()),
                  );
                },
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
                child: const Text(
                  'Add Invoice',
                  style: TextStyle(fontSize: 15),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Project Dropdown
            SearchableDropdown(
              value: _selectedClients,
              hint: 'Select Project',
              items: _clients,
              onChanged: (value) {
                setState(() {
                  _selectedClients = value;
                });
              },
            ),
            const SizedBox(height: 10),

            // Date Range Picker
            TextFormField(
              controller: _dateController,
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'Select date range',
                labelStyle: TextStyle(color: Colors.grey[500]),
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
                suffixIcon: IconButton(
                  onPressed: _openDateRangePicker,
                  icon: Icon(
                    Icons.calendar_today_outlined,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Invoice Status Multi-Select
            MultiSelectDropdown(
              hint: 'Invoice Status (Paid/Unpaid)',
              items: [
                MultiSelectItem(value: '1', label: 'Paid'),
                MultiSelectItem(value: '0', label: 'Unpaid'),
                MultiSelectItem(value: '2', label: 'Partially Paid'),
              ],
              selectedValues: _selectedPaidStatuses,
              onChanged: (values) {
                setState(() {
                  _selectedPaidStatuses = values;
                });
              },
              decoration: _buildDropdownDecoration('Invoice Status'),
            ),
            const SizedBox(height: 10),

            // Work Status Multi-Select
            MultiSelectDropdown(
              hint: 'Work Status (Pending/Completed)',
              items: [
                MultiSelectItem(value: '0', label: 'Pending'),
                MultiSelectItem(value: '1', label: 'Completed'),
              ],
              selectedValues: _selectedWorkStatuses,
              onChanged: (values) {
                setState(() {
                  _selectedWorkStatuses = values;
                });
              },
              decoration: _buildDropdownDecoration('Work Status'),
            ),
            const SizedBox(height: 20),

            // Filter Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _applyFilters,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      'Apply Filters',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _resetFilters,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: backButtonColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      'Reset',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            const Center(
              child: Text(
                'Total Amount:',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 15),
            _isLoading
                ? Column(
                    children: [
                      Row(
                        children: [
                          Shimmer.fromColors(
                            baseColor: Colors.grey[300]!,
                            highlightColor: Colors.grey[100]!,
                            child: Container(
                              height: 20,
                              width: 150,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                          SizedBox(width: 10),
                          Shimmer.fromColors(
                            baseColor: Colors.grey[300]!,
                            highlightColor: Colors.grey[100]!,
                            child: Container(
                              height: 20,
                              width: 150,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      Row(
                        children: [
                          Shimmer.fromColors(
                            baseColor: Colors.grey[300]!,
                            highlightColor: Colors.grey[100]!,
                            child: Container(
                              height: 20,
                              width: 150,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                          SizedBox(width: 10),
                          Shimmer.fromColors(
                            baseColor: Colors.grey[300]!,
                            highlightColor: Colors.grey[100]!,
                            child: Container(
                              height: 20,
                              width: 150,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  )
                : _currencyTotals.isEmpty
                ? const Center(
                    child: Text(
                      'No currency data available',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  )
                : Center(
                    child: Wrap(
                      spacing: 20,
                      runSpacing: 10,
                      children: _currencyTotals.map((currency) {
                        final symbol = currency['currency_symbol'] ?? '';
                        final code = currency['currency_code'] ?? '';
                        final total = currency['total_invoice_rate'] ?? 0;

                        return Text(
                          '$symbol ${_formatCurrency(total)} ${code.isNotEmpty ? code : ''}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
            const SizedBox(height: 15),
            const Divider(thickness: 1),
            const SizedBox(height: 15),
            _isLoading
                ? Column(
                    children: [
                      Row(
                        children: [
                          Shimmer.fromColors(
                            baseColor: Colors.grey[300]!,
                            highlightColor: Colors.grey[100]!,
                            child: Container(
                              height: 20,
                              width: 150,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                          SizedBox(width: 10),
                          Shimmer.fromColors(
                            baseColor: Colors.grey[300]!,
                            highlightColor: Colors.grey[100]!,
                            child: Container(
                              height: 20,
                              width: 150,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      Row(
                        children: [
                          Shimmer.fromColors(
                            baseColor: Colors.grey[300]!,
                            highlightColor: Colors.grey[100]!,
                            child: Container(
                              height: 20,
                              width: 150,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                          SizedBox(width: 10),
                          Shimmer.fromColors(
                            baseColor: Colors.grey[300]!,
                            highlightColor: Colors.grey[100]!,
                            child: Container(
                              height: 20,
                              width: 150,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  )
                : _currencyTotals.isEmpty
                ? const Center(
                    child: Text(
                      'No currency data available',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  )
                : Center(
                    child: Wrap(
                      spacing: 20,
                      runSpacing: 10,
                      children: _currencyTotals.map((currency) {
                        final paid_symbol = currency['currency_symbol'] ?? '';
                        final paid_code = currency['currency_code'] ?? '';
                        final paid_total = currency['total_paid_amount'] ?? 0;

                        return Text(
                          '$paid_symbol ${_formatCurrency(paid_code)} ${paid_total != 0 ? paid_total : '0'}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      "Show",
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: DropdownButton<int>(
                        dropdownColor: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        value: _entriesPerPage,
                        underline: Container(),
                        items: [25, 50, 100, 500].map((e) {
                          return DropdownMenuItem<int>(
                            value: e,
                            child: Text(
                              e.toString(),
                              style: const TextStyle(fontSize: 14),
                            ),
                          );
                        }).toList(),
                        onChanged: (v) {
                          setState(() {
                            _entriesPerPage = v!;
                            _currentPage = 1;
                          });
                          _loadInvoices();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "entries",
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    prefixIcon: Icon(
                      Icons.search,
                      size: 20,
                      color: Colors.grey[500],
                    ),
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
                    hintText: 'Search',
                    hintStyle: TextStyle(color: Colors.grey[500]),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                      _currentPage = 1;
                    });
                    _loadInvoices();
                  },
                  onFieldSubmitted: (value) {
                    setState(() {
                      _currentPage = 1;
                    });
                    _loadInvoices();
                  },
                ),
              ],
            ),
          ),
          if (_isLoading)
            _buildSkeletonLoader()
          else if (_hasError)
            Padding(
              padding: const EdgeInsets.all(40.0),
              child: Center(
                child: Column(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadInvoices,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          else if (_invoiceRecords.isEmpty)
            const Padding(
              padding: EdgeInsets.all(40.0),
              child: Center(
                child: Text(
                  'No invoices found',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
            )
          else
            _buildInvoiceTable(context),
        ],
      ),
    );
  }

  Widget _buildSkeletonLoader() {
    final screenWidth = MediaQuery.of(context).size.width;
    bool isMobile = screenWidth < 600;

    return Column(
      children: List.generate(8, (index) => _buildSkeletonRow(isMobile, index)),
    );
  }

  Widget _buildSkeletonRow(bool isMobile, int index) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        decoration: BoxDecoration(
          color: index % 2 == 0 ? Colors.white : Colors.grey[50],
          border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
        ),
        child: Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: isMobile
              ? Row(
                  children: [
                    _buildSkeletonCell(width: 120, height: 16),
                    _buildSkeletonCell(width: 140, height: 16),
                    _buildSkeletonCell(width: 100, height: 16),
                    _buildSkeletonCell(width: 100, height: 16),
                    _buildSkeletonCell(width: 100, height: 16),
                    _buildSkeletonCell(width: 130, height: 24),
                    _buildSkeletonCell(width: 120, height: 24),
                    _buildSkeletonCell(width: 200, height: 16),
                    _buildSkeletonCell(width: 200, height: 16),
                  ],
                )
              : IntrinsicHeight(
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: _buildFlexSkeletonCell(height: 16),
                      ),
                      Expanded(
                        flex: 2,
                        child: _buildFlexSkeletonCell(height: 16),
                      ),
                      Expanded(
                        flex: 2,
                        child: _buildFlexSkeletonCell(height: 16),
                      ),
                      Expanded(
                        flex: 2,
                        child: _buildFlexSkeletonCell(height: 16),
                      ),
                      Expanded(
                        flex: 2,
                        child: _buildFlexSkeletonCell(height: 16),
                      ),
                      Expanded(
                        flex: 2,
                        child: _buildFlexSkeletonCell(height: 24),
                      ),
                      Expanded(
                        flex: 2,
                        child: _buildFlexSkeletonCell(height: 24),
                      ),
                      Expanded(
                        flex: 3,
                        child: _buildFlexSkeletonCell(height: 16),
                      ),
                      Expanded(
                        flex: 2,
                        child: _buildFlexSkeletonCell(height: 16),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildSkeletonCell({required double width, required double height}) {
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        alignment: Alignment.centerLeft,
        child: Container(
          width: width * 0.7,
          height: height,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }

  Widget _buildFlexSkeletonCell({required double height}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      alignment: Alignment.centerLeft,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }

  Widget _buildInvoiceTable(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    bool isMobile = screenWidth < 600;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: isMobile ? 1000 : screenWidth - 72,
        ),
        child: ReusableDataTable(
          columns: [
            TableColumnConfig(
              title: 'Invoice Ref',
              flex: 2,
              fixedWidth: 120,
              builder: (data, index) {
                final record = data as InvoiceRecord;
                return Center(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        record.invoiceRef,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        record.createdBy,
                        style: TextStyle(
                          fontWeight: FontWeight.w400,
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            TableColumnConfig(
              title: 'Client',
              flex: 2,
              fixedWidth: 140,
              builder: (data, index) {
                final record = data as InvoiceRecord;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      record.client,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      record.project,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                );
              },
            ),
            TableColumnConfig(
              title: 'Amount',
              flex: 2,
              fixedWidth: 100,
              builder: (data, index) {
                final record = data as InvoiceRecord;
                return Center(
                  child: Column(
                    children: [
                      Text(
                        '${record.currencyCode} ${record.amount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      record.paidamount == 0.00 ? SizedBox() : Divider(),
                      record.paidamount == 0.00
                          ? SizedBox()
                          : Text(
                              '${record.currencyCode} ${record.paidamount.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                    ],
                  ),
                );
              },
            ),
            TableColumnConfig(
              title: 'Expense',
              flex: 2,
              fixedWidth: 120,
              builder: (data, index) {
                final record = data as InvoiceRecord;
                return Center(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          record.expenseAmount == 0.00
                              ? '--'
                              : '${record.currencyCode} ${record.expenseAmount.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[700],
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      if (record.expenseAmount != 0.00) ...[
                        SizedBox(width: 5),
                        GestureDetector(
                          child: Icon(
                            Icons.info_outline,
                            color: Colors.blue,
                            size: 18,
                          ),
                          onTap: () => _openExpenseDialog(record),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
            TableColumnConfig(
              title: 'Profit/Loss',
              flex: 2,
              fixedWidth: 140,
              builder: (data, index) {
                final record = data as InvoiceRecord;

                // Check if we should show profit/loss
                if (record.expenseAmount <= 0) {
                  return const Center(child: Text('-'));
                }

                // Check if work dates are missing (using year 1970 as indicator of invalid date)
                if (record.workStartDate.year == 1970 ||
                    record.workEndDate.year == 1970) {
                  return const Center(child: Text('-'));
                }

                final isProfit = record.profitLoss >= 0;
                final invoiceAmount = record.amount;

                // Calculate percentage
                double percentage = 0.0;
                if (invoiceAmount > 0) {
                  percentage = (record.profitLoss.abs() / invoiceAmount) * 100;
                }

                // Calculate border percentage (expense vs invoice amount)
                double borderPercentage = 0.0;
                if (invoiceAmount > 0) {
                  borderPercentage =
                      (record.expenseAmount / invoiceAmount) * 100;
                }

                // Get currency symbol ($ for USD, etc.)
                String currencySymbol = '\$';
                if (record.currencyCode == 'INR') {
                  currencySymbol = '₹';
                } else if (record.currencyCode == 'EUR') {
                  currencySymbol = '€';
                } else if (record.currencyCode == 'GBP') {
                  currencySymbol = '£';
                }

                // Format the profit/loss text
                final profitLossText = isProfit
                    ? '$currencySymbol ${_formatCurrency(record.profitLoss)} ${record.currencyCode}'
                    : '- $currencySymbol ${_formatCurrency(record.profitLoss.abs())} ${record.currencyCode}';

                // Format the tooltip text
                final tooltipText = percentage < 0
                    ? '${_formatCurrency(percentage.abs())}% Loss'
                    : '${_formatCurrency(percentage)}% Profit';

                return Center(
                  child: Tooltip(
                    message: tooltipText,
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    textStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                    child: PercentageBorderChip(
                      percentage: borderPercentage,
                      isProfit: isProfit,
                      size: 'large',
                      label: Text(
                        profitLossText,
                        style: const TextStyle(fontSize: 11),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                );
              },
            ),
            TableColumnConfig(
              title: 'Invoice Status',
              flex: 2,
              fixedWidth: 130,
              builder: (data, index) {
                final record = data as InvoiceRecord;
                return Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(record.invoiceStatus),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(
                      record.invoiceStatus,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        color: _getStatusTextColor(record.invoiceStatus),
                      ),
                    ),
                  ),
                );
              },
            ),
            TableColumnConfig(
              title: 'Work Status',
              flex: 2,
              fixedWidth: 120,
              builder: (data, index) {
                final record = data as InvoiceRecord;
                return Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(record.workStatus),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(
                      record.workStatus,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        color: _getStatusTextColor(record.workStatus),
                      ),
                    ),
                  ),
                );
              },
            ),
            TableColumnConfig(
              title: 'Work Date',
              flex: 3,
              fixedWidth: 160,
              builder: (data, index) {
                final record = data as InvoiceRecord;
                
                // Check if work start date is valid (not year 1970 which indicates no date)
                final hasValidStartDate = record.workStartDate.year != 1970;
                
                // If no valid start date, don't show anything
                if (!hasValidStartDate) {
                  return const Center(child: Text('-'));
                }
                
                // Check if end date is past due
                final now = DateTime.now();
                final endDate = record.workEndDate;
                final isPastDue = endDate.isBefore(now) && endDate.year != 1970;
                
                return Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Start Date (non-editable)
                        Text(
                          DateFormat('dd/MM/yyyy').format(record.workStartDate),
                          textAlign: TextAlign.left,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Divider
                        Divider(
                          height: 1,
                          thickness: 1,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 4),
                        // End Date (editable) with icon
                        InkWell(
                          onTap: () => _showDatePicker(context, record),
                          borderRadius: BorderRadius.circular(4),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 2,
                              horizontal: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: Colors.grey[300]!,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Expanded(
                                  child: Text(
                                    endDate.year == 1970
                                        ? DateFormat('dd/MM/yyyy').format(DateTime.now())
                                        : DateFormat('dd/MM/yyyy').format(endDate),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: isPastDue ? Colors.red[700] : Colors.black87,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.calendar_today,
                                  size: 12,
                                  color: primaryColor,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            TableColumnConfig(
              title: 'Created At',
              builder: (data, index) {
                final record = data as InvoiceRecord;
                return Text(
                  '${record.createdAt}',
                  style: TextStyle(fontSize: 12),
                );
              },
            ),
            TableColumnConfig(
              title: 'Action',
              flex: 2,
              fixedWidth: 130,
              builder: (data, index) {
                final record = data as InvoiceRecord;
                return Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                EditInvoiceScreen(invoiceId: record.id),
                          ),
                        ).then((_) => _loadInvoices());
                      },
                      child: Icon(
                        Icons.edit,
                        color: Colors.green[700],
                        size: 18,
                      ),
                    ),
                    SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {},
                      child: Icon(
                        Icons.delete,
                        color: Colors.red[700],
                        size: 18,
                      ),
                    ),
                    SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {},
                      child: Icon(
                        Icons.copy,
                        color: Colors.green[700],
                        size: 18,
                      ),
                    ),
                    SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {},
                      child: Icon(
                        Icons.more_vert,
                        color: Colors.grey[700],
                        size: 18,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
          data: _invoiceRecords,
          isMobile: isMobile,
        ),
      ),
    );
  }
}

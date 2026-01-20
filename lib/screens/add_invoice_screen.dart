import 'dart:convert';

import 'package:dashboard_clone/screens/invoice_preview_screen.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../services/invoice_service.dart';
import '../services/client_list.dart';
import '../widgets/searchable_dropdown.dart';
import '../constants/constants.dart';

class AddInvoiceScreen extends StatefulWidget {
  const AddInvoiceScreen({super.key});

  @override
  State<AddInvoiceScreen> createState() => _AddInvoiceScreenState();
}

class _AddInvoiceScreenState extends State<AddInvoiceScreen> {
  bool _isLoading = true;

  // Dropdown data lists (initially empty, will be populated with invoice data first)
  List<Map<String, dynamic>> _projectList = [];
  List<Map<String, dynamic>> _clientList = [];
  List<Map<String, dynamic>> _proposalList = [];
  List<Map<String, dynamic>> _bankList = [];
  List<Map<String, dynamic>> _currencyList = [];

  // Selected IDs
  String? _selectedProjectId;
  String? _selectedClientId;
  String? _selectedProposalId;
  String? _selectedBankId;
  String? _selectedCurrencyId;

  final TextEditingController _projectController = TextEditingController();
  final TextEditingController _clientController = TextEditingController();
  final TextEditingController _proposalController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _bankController = TextEditingController();
  final TextEditingController _currencyController = TextEditingController();
  final TextEditingController _totalAmountController = TextEditingController();
  final TextEditingController _workTitleController = TextEditingController();

  // File attachment
  PlatformFile? _selectedFile;

  // List of payment entries
  List<Map<String, TextEditingController>> payments = [];

  String _isPaid = 'No';
  String _isCompleted = 'Pending';

  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _invoiceDateController = TextEditingController();
  final TextEditingController _dueDateController = TextEditingController();
  final TextEditingController _noticeController = TextEditingController();
  final TextEditingController _invoiceNumberController =
      TextEditingController();
  final TextEditingController _currencyRateController = TextEditingController();
  final TextEditingController _discountLabelController =
      TextEditingController();
  final TextEditingController _discountAmountController =
      TextEditingController();
  final TextEditingController _workStartDateController =
      TextEditingController();
  final TextEditingController _workEndDateController = TextEditingController();
  final TextEditingController _hourlyRateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initialize with one empty payment entry
    payments.add({
      'amount': TextEditingController(text: ''),
      'date': TextEditingController(text: ''),
      'note': TextEditingController(text: ''),
    });

    // Generate initial invoice reference with today's date
    _generateInvoiceReference();

    setState(() {
      _isLoading = false;
    });
  }

  /// Generate invoice reference from project name initials and today's date
  /// Format: [ProjectInitials]/[DD-MM-YYYY]
  /// Example: "TP/07-11-2025" for "Today Project"
  void _generateInvoiceReference() {
    final now = DateTime.now();
    final dateStr =
        '${now.day.toString().padLeft(2, '0')}${now.month.toString().padLeft(2, '0')}${now.year}';

    String projectInitials = 'INV';
    if (_projectController.text.isNotEmpty) {
      // Get initials from project name
      final words = _projectController.text.trim().split(RegExp(r'\s+'));
      if (words.length == 1) {
        // Single word: take first 2-3 characters
        projectInitials = words[0]
            .substring(0, words[0].length >= 3 ? 3 : words[0].length)
            .toUpperCase();
      } else {
        // Multiple words: take first letter of each word (max 3)
        projectInitials = words
            .take(3)
            .map((word) => word.isNotEmpty ? word[0].toUpperCase() : '')
            .join('');
      }
    }

    final reference = '$projectInitials/$dateStr';
    _invoiceNumberController.text = reference;
    print('📋 Generated invoice reference: $reference');
  }

  Future<void> _findAndSelectCurrency(
    String currencyCode,
    String? countryName,
  ) async {
    try {
      print('🔍 Searching for currency: $currencyCode (Country: $countryName)');

      // Fetch currency list
      final response = await ClientList.getCurrencyList();

      if (response?['success'] == true && response?['data'] != null) {
        final data = response!['data'];
        final currencyList = List<Map<String, dynamic>>.from(
          data is List ? data : [data],
        );

        print('📋 Searching in ${currencyList.length} currencies');

        // Try to find currency by code or country name
        Map<String, dynamic>? matchedCurrency;

        // First try: exact match by currency code
        matchedCurrency = currencyList.firstWhere((item) {
          final itemCode = item['currency_code']?.toString().toUpperCase();
          final itemCurrency = item['currency']?.toString().toUpperCase();
          return itemCode == currencyCode.toUpperCase() ||
              itemCurrency == currencyCode.toUpperCase();
        }, orElse: () => {});

        // Second try: match by country name
        if (matchedCurrency.isEmpty && countryName != null) {
          matchedCurrency = currencyList.firstWhere((item) {
            final itemName = item['name']?.toString().toUpperCase();
            return itemName?.contains(countryName.toUpperCase()) ?? false;
          }, orElse: () => {});
        }

        if (matchedCurrency.isNotEmpty) {
          final currencyId =
              (matchedCurrency['currency_id'] ?? matchedCurrency['id'])
                  ?.toString();
          final currencyName =
              (matchedCurrency['name'] ?? matchedCurrency['currency'])
                  ?.toString();

          if (currencyId != null && currencyName != null) {
            setState(() {
              _selectedCurrencyId = currencyId;
              _currencyController.text = currencyName;
              // Also update the currency list to include this currency
              _currencyList = currencyList;
            });
            print(
              '✅ Currency auto-selected: ID=$currencyId, Name=$currencyName',
            );
          } else {
            print('⚠️ Currency found but missing ID or name: $matchedCurrency');
          }
        } else {
          print('⚠️ No matching currency found for code: $currencyCode');
        }
      } else {
        print('❌ Failed to fetch currency list');
      }
    } catch (e) {
      print('❌ Error finding currency: $e');
    }
  }

  Future<void> _fetchClientData(String clientId) async {
    try {
      print('🔍 Fetching client data for ID: $clientId');
      final response = await ClientList.getClientDataOnSelect(clientId);

      print('📦 Full API response: $response');

      if (response?['success'] == true && response?['data'] != null) {
        final clientData = response!['data'];
        print('✅ Client data received');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        print('📋 Raw data structure:');
        print('  - address: ${clientData['address']}');
        print('  - country: ${clientData['country']}');
        print('  - project: ${clientData['project']}');
        print('  - company: ${clientData['company']}');
        print('  - currency_rate: ${clientData['currency_rate']}');
        print('  - currency_code: ${clientData['currency_code']}');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

        setState(() {
          // 1. Update address field from address.address
          if (clientData['address'] != null) {
            final addressData = clientData['address'];
            print('📍 Processing address data: $addressData');

            if (addressData is Map) {
              if (addressData['address'] != null) {
                final addressText = addressData['address'].toString();
                _addressController.text = addressText;
                print('✅ Address field updated: "$addressText"');
              } else {
                print('⚠️ address.address is null');
              }

              // Log other address fields
              if (addressData['client_name'] != null) {
                print(
                  '   Client name in address: ${addressData['client_name']}',
                );
              }
              if (addressData['client_id'] != null) {
                print('   Client ID in address: ${addressData['client_id']}');
              }
              if (addressData['hours'] != null) {
                print('   Hours: ${addressData['hours']}');
              }
            } else {
              print('⚠️ Address data is not a Map: $addressData');
            }
          } else {
            print('⚠️ No address data in response');
          }

          // 2. Update currency rate from currency_rate
          if (clientData['currency_rate'] != null) {
            final rateText = clientData['currency_rate'].toString();
            _currencyRateController.text = rateText;
            print('✅ Currency rate field updated: "$rateText"');
          } else {
            print('⚠️ No currency_rate in response');
          }

          // 3. Log currency code
          if (clientData['currency_code'] != null) {
            print('💱 Currency code: ${clientData['currency_code']}');
          }

          // 4. Update project list from project array - ONLY show client's projects
          if (clientData['project'] != null && clientData['project'] is List) {
            final projects = clientData['project'] as List;
            print('📋 Processing ${projects.length} projects:');

            // Convert to the format expected by the dropdown
            _projectList = projects.map((proj) {
              final projectId = proj['id'].toString();
              final projectName = proj['project'].toString();
              print('   ✓ Project ID: $projectId, Name: "$projectName"');
              return {
                'id': projectId,
                'project_id': projectId,
                'project_name': projectName,
              };
            }).toList();

            // Clear the selected project since we're showing new list
            _selectedProjectId = null;
            _projectController.clear();

            print(
              '✅ Project dropdown updated with ${_projectList.length} items',
            );
          } else {
            // If no projects, clear the list
            _projectList = [];
            _selectedProjectId = null;
            _projectController.clear();
            print('⚠️ No projects array in response');
          }

          // 5. Handle country/currency info
          if (clientData['country'] != null) {
            final country = clientData['country'];
            print('🌍 Country data:');
            print('   Name: ${country['name']}');
            print('   Currency symbol: ${country['currency']}');

            // Try to find and select the matching currency
            if (clientData['currency_code'] != null) {
              final currencyCode = clientData['currency_code'].toString();
              print('💱 Looking for currency with code: $currencyCode');

              // We'll need to fetch the currency list to find the matching currency
              _findAndSelectCurrency(currencyCode, country['name']?.toString());
            }
          } else {
            print('⚠️ No country data in response');
          }

          // 6. Log company info
          if (clientData['company'] != null) {
            print('🏢 Company data: ${clientData['company']}');
          } else {
            print('⚠️ No company data in response (null)');
          }
        });

        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        print('✅ All fields processed successfully');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      } else {
        print('❌ Failed to fetch client data');
        print('   Success: ${response?['success']}');
        print('   Message: ${response?['message']}');
        print('   Data: ${response?['data']}');
      }
    } catch (e, stackTrace) {
      print('❌ Error fetching client data: $e');
      print('❌ Stack trace: $stackTrace');
    }
  }

  // New methods to load each dropdown data individually
  Future<List<Map<String, dynamic>>> _loadProjectDropdownData() async {
    try {
      // If a client is selected and we have client-specific projects, use those
      if (_selectedClientId != null && _projectList.isNotEmpty) {
        print(
          '📋 Using client-specific project list (${_projectList.length} projects)',
        );
        return _projectList;
      }

      // Otherwise, load all projects from API
      print('📋 Loading all projects from API');
      final response = await ClientList.getProjectUserList();
      List<Map<String, dynamic>> apiData = [];

      if (response!['success'] == true && response['data'] != null) {
        final data = response['data'];
        apiData = List<Map<String, dynamic>>.from(data is List ? data : [data]);
      }

      // Update the state list
      setState(() {
        _projectList = apiData;
      });

      return apiData;
    } catch (e) {
      print('Error loading project dropdown data: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _loadClientDropdownData() async {
    try {
      final response = await ClientList.getClientList();
      List<Map<String, dynamic>> apiData = [];

      if (response!['success'] == true && response['data'] != null) {
        final data = response['data'];
        apiData = List<Map<String, dynamic>>.from(data is List ? data : [data]);
      }

      // Update the state list
      setState(() {
        _clientList = apiData;
      });

      return apiData;
    } catch (e) {
      print('Error loading client dropdown data: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _loadProposalDropdownData() async {
    try {
      final response = await ClientList.getActiveProposalList();
      List<Map<String, dynamic>> apiData = [];

      if (response!['success'] == true && response['data'] != null) {
        final data = response['data'];
        apiData = List<Map<String, dynamic>>.from(data is List ? data : [data]);
      }

      // Update the state list
      setState(() {
        _proposalList = apiData;
      });

      return apiData;
    } catch (e) {
      print('Error loading proposal dropdown data: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _loadBankDropdownData() async {
    try {
      final response = await ClientList.getBankList();
      List<Map<String, dynamic>> apiData = [];

      if (response!['success'] == true && response['data'] != null) {
        final data = response['data'];
        apiData = List<Map<String, dynamic>>.from(data is List ? data : [data]);
      }

      // Update the state list
      setState(() {
        _bankList = apiData;
      });

      return apiData;
    } catch (e) {
      print('Error loading bank dropdown data: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _loadCurrencyDropdownData() async {
    try {
      final response = await ClientList.getCurrencyList();
      List<Map<String, dynamic>> apiData = [];

      if (response!['success'] == true && response['data'] != null) {
        final data = response['data'];
        apiData = List<Map<String, dynamic>>.from(data is List ? data : [data]);
      }

      // Update the state list
      setState(() {
        _currencyList = apiData;
      });

      return apiData;
    } catch (e) {
      print('Error loading currency dropdown data: $e');
      return [];
    }
  }

  Future<bool> _saveInvoice() async {
    // Validate required fields
    if (_selectedCurrencyId == null || _selectedCurrencyId!.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Please select a currency'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
      return false;
    }

    if (_totalAmountController.text.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Please enter the invoice amount'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
      return false;
    }

    // Validate that invoice amount is a valid number
    final invoiceAmount = double.tryParse(_totalAmountController.text);
    if (invoiceAmount == null || invoiceAmount <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Please enter a valid invoice amount greater than 0'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
      return false;
    }

    // Prepare task_filter JSON
    final taskFilter = {
      'pay': null,
      'bill': null,
      'active': null,
      'column': 4,
      'userId': null,
      'direction': 'desc',
      'projectId': _selectedProjectId != null
          ? int.tryParse(_selectedProjectId!)
          : null,
      'taskdateto': _dueDateController.text.isNotEmpty
          ? _dueDateController.text
          : null,
      'taskdatefrom': _invoiceDateController.text.isNotEmpty
          ? _invoiceDateController.text
          : null,
    };

    // Convert is_paid to numeric value
    int isPaidValue = 0;
    if (_isPaid == 'Yes') {
      isPaidValue = 1;
    } else if (_isPaid == 'Partially') {
      isPaidValue = 2;
    }

    // Convert is_completed to numeric value
    int isCompletedValue = _isCompleted == 'Completed' ? 1 : 0;

    // Prepare work_paid_amount JSON array
    final workPaidAmountList = payments
        .where((payment) {
          // Only include payments with amount
          return payment['amount']?.text.trim().isNotEmpty ?? false;
        })
        .map((payment) {
          // Convert DD/MM/YYYY to YYYY-MM-DD format for API
          String dateText = payment['date']?.text ?? '';
          String formattedDate = dateText;
          if (dateText.contains('/')) {
            final parts = dateText.split('/');
            if (parts.length == 3) {
              formattedDate =
                  '${parts[2]}-${parts[1].padLeft(2, '0')}-${parts[0].padLeft(2, '0')}';
            }
          }

          return {
            'paid_amount': payment['amount']?.text ?? '',
            'date': formattedDate,
            'note': payment['note']?.text ?? '',
          };
        })
        .toList();

    print('💾 Saving ${workPaidAmountList.length} payment entries to API');
    for (var i = 0; i < workPaidAmountList.length; i++) {
      print('  Payment $i: ${workPaidAmountList[i]}');
    }

    // Format dates for API (YYYY-MM-DD format)
    String formattedStartDate = '';
    if (_workStartDateController.text.isNotEmpty) {
      final parts = _workStartDateController.text.split('/');
      if (parts.length == 3) {
        formattedStartDate =
            '${parts[2]}-${parts[1].padLeft(2, '0')}-${parts[0].padLeft(2, '0')}';
      }
      print(
        '📅 Work Start Date: ${_workStartDateController.text} → $formattedStartDate',
      );
    } else {
      print('⚠️ Work Start Date is empty');
    }

    String formattedEndDate = '';
    if (_workEndDateController.text.isNotEmpty) {
      final parts = _workEndDateController.text.split('/');
      if (parts.length == 3) {
        formattedEndDate =
            '${parts[2]}-${parts[1].padLeft(2, '0')}-${parts[0].padLeft(2, '0')}';
      }
      print(
        '📅 Work End Date: ${_workEndDateController.text} → $formattedEndDate',
      );
    } else {
      print('⚠️ Work End Date is empty');
    }

    // Prepare work_info JSON object (matching API structure)
    final workInfo = {
      'work_paid_amount': workPaidAmountList,
      'price_amount': _totalAmountController.text.isNotEmpty
          ? _totalAmountController.text
          : '0',
      'is_paid': isPaidValue,
      'is_completed': isCompletedValue,
      'work_start_date': formattedStartDate,
      'work_end_date': formattedEndDate,
      'work_title': _workTitleController.text,
    };

    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('   WORK INFO OBJECT BEING SENT TO API:');
    print('   work_start_date: "$formattedStartDate"');
    print('   work_end_date: "$formattedEndDate"');
    print('   work_title: "${workInfo['work_title']}"');
    print('   price_amount: "${workInfo['price_amount']}"');
    print('   is_paid: ${workInfo['is_paid']}');
    print('   is_completed: ${workInfo['is_completed']}');
    print('   Full JSON: ${jsonEncode(workInfo)}');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    // Prepare attachment as base64 if file is selected
    String? attachmentBase64;
    String? attachmentFileName;
    if (_selectedFile != null && _selectedFile!.bytes != null) {
      attachmentBase64 = base64Encode(_selectedFile!.bytes!);
      attachmentFileName = _selectedFile!.name;
      print(
        '📎 Attachment: ${attachmentFileName} (${_selectedFile!.size} bytes)',
      );
    }

    // Convert invoice_date and due_date to YYYY-MM-DD format
    String formattedInvoiceDate = '';
    if (_invoiceDateController.text.isNotEmpty) {
      final parts = _invoiceDateController.text.split('/');
      if (parts.length == 3) {
        formattedInvoiceDate =
            '${parts[2]}-${parts[1].padLeft(2, '0')}-${parts[0].padLeft(2, '0')}';
      }
      print(
        '📅 Invoice Date: ${_invoiceDateController.text} → $formattedInvoiceDate',
      );
    }

    String formattedDueDate = '';
    if (_dueDateController.text.isNotEmpty) {
      final parts = _dueDateController.text.split('/');
      if (parts.length == 3) {
        formattedDueDate =
            '${parts[2]}-${parts[1].padLeft(2, '0')}-${parts[0].padLeft(2, '0')}';
      }
      print('📅 Due Date: ${_dueDateController.text} → $formattedDueDate');
    }

    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('📤 SENDING ADD INVOICE REQUEST TO API:');
    print('   client_id: ${_selectedClientId ?? ""}');
    print('   client_name: ${_clientController.text}');
    print('   project_id: ${_selectedProjectId ?? ""}');
    print('   project_name: ${_projectController.text}');
    print('   proposal_id: ${_selectedProposalId ?? ""}');
    print('   currency_id: ${_selectedCurrencyId ?? ""}');
    print('   company_id: ${_selectedBankId ?? ""}');
    print('   invoice_rate: ${_totalAmountController.text}');
    print('   invoice_no: ${_invoiceNumberController.text}');
    print(
      '   currency_rate: ${_currencyRateController.text.isNotEmpty ? _currencyRateController.text : "1"}',
    );
    print('   invoice_date: $formattedInvoiceDate');
    print('   due_date: $formattedDueDate');
    print('   reference: ${_invoiceNumberController.text}');
    print(
      '   hourly_rate: ${_hourlyRateController.text.isNotEmpty ? _hourlyRateController.text : "0"}',
    );
    print('   expense_amount: 0');
    print('   is_paid: $isPaidValue');
    print(
      '   ⚠️ WORK TOTAL AMOUNT FIELD VALUE: "${_totalAmountController.text}"',
    );
    print('   ⚠️ INVOICE AMOUNT FIELD VALUE: "${_totalAmountController.text}"');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    try {
      final result = await InvoiceService.addInvoice(
        context: context,
        project_name: _projectController.text,
        client_id: _selectedClientId ?? '',
        client_name: _clientController.text,
        project_id: _selectedProjectId ?? '',
        proposal_id: _selectedProposalId ?? '',
        currency_id: _selectedCurrencyId ?? '',
        client_address: _addressController.text,
        company_id: _selectedBankId ?? '',
        invoice_rate: _totalAmountController.text.isNotEmpty
            ? _totalAmountController.text
            : '-',
        invoice_no: _invoiceNumberController.text,
        currency_rate: _currencyRateController.text.isNotEmpty
            ? _currencyRateController.text
            : '1',
        invoice_date: formattedInvoiceDate,
        due_date: formattedDueDate,
        discount_label: _discountLabelController.text,
        discount_amount: _discountAmountController.text.isNotEmpty
            ? _discountAmountController.text
            : '0',
        invoice_description: _descriptionController.text,
        is_paid: isPaidValue.toString(),
        reference: _invoiceNumberController.text,
        task_filter: jsonEncode(taskFilter),
        notice: _noticeController.text,
        hourly_rate: _hourlyRateController.text.isNotEmpty
            ? _hourlyRateController.text
            : '0',
        expense_amount: '0',
        direction: 'desc',
        work_info: jsonEncode(workInfo),
        attachment: attachmentBase64,
        attachmentFileName: attachmentFileName,
      );

      if (result?['success'] == true) {
        final invoiceId = result?['invoice_id']?.toString() ?? 
                         result?['data']?['invoice_id']?.toString() ??
                         result?['data']?['id']?.toString();
        
        print('✅ Invoice saved successfully');
        print('✅ Invoice Number: ${_invoiceNumberController.text}');
        if (invoiceId != null) {
          print('✅ Invoice ID: $invoiceId');
        }
        print('✅ Work Total Amount sent: ${_totalAmountController.text}');
        if (result?['data'] != null) {
          print('✅ API Response Data: ${result?['data']}');
        }
        return true;
      } else {
        // Error message already shown by service
        print('❌ Add invoice failed: ${result?['message']}');
        return false;
      }
    } catch (e) {
      print('Error saving invoice: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving invoice: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }
  }

  Future<void> _generateAndSaveInvoice() async {
    // Validate required fields
    if (_selectedCurrencyId == null || _selectedCurrencyId!.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Please select a currency'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    if (_totalAmountController.text.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Please enter the invoice amount'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    // Calculate total amount after discount
    double totalAmount = double.tryParse(_totalAmountController.text) ?? 0.0;
    
    // Validate that invoice amount is a valid number
    if (totalAmount <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Please enter a valid invoice amount greater than 0'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }
    
    double discountAmount =
        double.tryParse(_discountAmountController.text) ?? 0.0;
    double totalDue = totalAmount - discountAmount;

    print('💰 Invoice Amount Calculation:');
    print('   Work Total Amount: $totalAmount');
    print('   Discount Amount: $discountAmount');
    print('   Total Due: $totalDue');

    // Navigate directly to preview screen without saving
    // The preview screen will handle the save operation
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => InvoicePreviewScreen(
            invoiceData: {
              'invoice_no': _invoiceNumberController.text.isNotEmpty
                  ? _invoiceNumberController.text
                  : 'INV-${DateTime.now().millisecondsSinceEpoch}',
              'invoice_date': _invoiceDateController.text,
              'due_date': _dueDateController.text,
              'client_id': _selectedClientId,
              'project_id': _selectedProjectId,
              'currency_id': _selectedCurrencyId,
              'company_id': _selectedBankId,
              'reference': _invoiceNumberController.text,
              'client_address': _addressController.text,
              'currency_rate': _currencyRateController.text.isNotEmpty
                  ? _currencyRateController.text
                  : '1',
              'discount_label': _discountLabelController.text,
              'discount_amount': _discountAmountController.text.isNotEmpty
                  ? _discountAmountController.text
                  : '0',
              'notice': _noticeController.text,
              'description': _descriptionController.text,
              'is_paid': _isPaid == 'Yes' ? 1 : (_isPaid == 'Partially' ? 2 : 0),
              'hourly_rate': _hourlyRateController.text.isNotEmpty
                  ? _hourlyRateController.text
                  : '0',
              'work_title': _workTitleController.text,
              'work_start_date': _workStartDateController.text,
              'work_end_date': _workEndDateController.text,
              'total_amount': _totalAmountController.text,
              'tasks': [
                {
                  'description': _workTitleController.text.isNotEmpty
                      ? _workTitleController.text
                      : 'Work Description',
                  'date':
                      '${_workStartDateController.text}${_workEndDateController.text.isNotEmpty ? ' - ${_workEndDateController.text}' : ''}',
                  'hours':
                      '8', // You can calculate this from work dates if needed
                  'rate_per_hour': _hourlyRateController.text.isNotEmpty
                      ? _hourlyRateController.text
                      : '0',
                  'amount': _totalAmountController.text.isNotEmpty
                      ? _totalAmountController.text
                      : '0',
                },
              ],
              'total_hours': '8', // Calculate based on your logic
              'rate_per_hour': _hourlyRateController.text.isNotEmpty
                  ? _hourlyRateController.text
                  : '0',
              'subtotal': _totalAmountController.text.isNotEmpty
                  ? _totalAmountController.text
                  : '0',
              'total_due': totalDue.toStringAsFixed(2),
              'discount': _discountAmountController.text.isNotEmpty
                  ? _discountAmountController.text
                  : null,
            },
            selectedClient: {
              'client_name': _clientController.text.isNotEmpty
                  ? _clientController.text
                  : 'Client Name',
            },
            selectedCurrency: {
              'currency_code': _currencyController.text.isNotEmpty
                  ? _currencyController.text.split(' ').first
                  : 'USD',
            },
            values: {
              'client_address': _addressController.text,
              'notice': _noticeController.text,
            },
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _projectController.dispose();
    _clientController.dispose();
    _proposalController.dispose();
    _addressController.dispose();
    _bankController.dispose();
    _currencyController.dispose();
    _totalAmountController.dispose();
    _workTitleController.dispose();
    _descriptionController.dispose();
    _invoiceDateController.dispose();
    _dueDateController.dispose();
    _noticeController.dispose();
    _invoiceNumberController.dispose();
    _currencyRateController.dispose();
    _discountLabelController.dispose();
    _discountAmountController.dispose();
    _workStartDateController.dispose();
    _workEndDateController.dispose();
    _hourlyRateController.dispose();

    for (var payment in payments) {
      payment['amount']?.dispose();
      payment['date']?.dispose();
      payment['note']?.dispose();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with Back Button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Add Invoice',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Back',
                            style: TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withValues(alpha: 0.08),
                            spreadRadius: 0,
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _buildDropdownField(
                            'Select Project',
                            _projectController,
                            _projectList,
                            _selectedProjectId,
                            (id, name) {
                              setState(() {
                                _selectedProjectId = id;
                                _projectController.text = name ?? '';
                              });
                              // Regenerate invoice reference when project changes
                              _generateInvoiceReference();
                            },
                            idKey: 'id',
                            nameKey: 'project_name',
                            onDropdownOpen: _loadProjectDropdownData,
                          ),
                          _buildDropdownField(
                            'Select Client',
                            _clientController,
                            _clientList,
                            _selectedClientId,
                            (id, name) async {
                              setState(() {
                                _selectedClientId = id;
                                _clientController.text = name ?? '';
                              });

                              // Fetch client data when client is selected
                              if (id != null && id.isNotEmpty) {
                                await _fetchClientData(id);
                              }
                            },
                            idKey: 'id',
                            nameKey: 'client_name',
                            onDropdownOpen: _loadClientDropdownData,
                          ),
                          _buildDropdownField(
                            'Select Active Proposal',
                            _proposalController,
                            _proposalList,
                            _selectedProposalId,
                            (id, name) {
                              setState(() {
                                _selectedProposalId = id;
                                _proposalController.text = name ?? '';
                              });
                            },
                            idKey: 'id',
                            nameKey: 'project_title',
                            onDropdownOpen: _loadProposalDropdownData,
                          ),
                          _buildTextField(
                            'Client Address',
                            _addressController,
                            maxLines: 3,
                          ),
                          _buildDropdownField(
                            'Select Bank',
                            _bankController,
                            _bankList,
                            _selectedBankId,
                            (id, name) {
                              setState(() {
                                _selectedBankId = id;
                                _bankController.text = name ?? '';
                              });
                            },
                            idKey: 'id',
                            nameKey: 'display_name',
                            onDropdownOpen: _loadBankDropdownData,
                          ),
                          _buildDropdownField(
                            'Select Currency',
                            _currencyController,
                            _currencyList,
                            _selectedCurrencyId,
                            (id, name) {
                              print(
                                '💱 Currency manually selected: ID=$id, Name=$name',
                              );
                              setState(() {
                                _selectedCurrencyId = id;
                                _currencyController.text = name ?? '';
                              });
                            },
                            idKey: 'currency_id',
                            nameKey: 'name',
                            onDropdownOpen: _loadCurrencyDropdownData,
                          ),
                          _buildTextField(
                            'Work Total Amount',
                            _totalAmountController,
                          ),
                          _buildTextField('Work Title', _workTitleController),
                          _buildTextField('Hourly Rate', _hourlyRateController),

                          // Payment Entries
                          ...List.generate(payments.length, (index) {
                            final payment = payments[index];
                            return Column(
                              children: [
                                if (index > 0) const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildTextField(
                                        'Work Paid Amount',
                                        payment['amount']!,
                                        showLabel: index == 0,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    if (index > 0)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 0),
                                        child: IconButton(
                                          icon: const Icon(
                                            Icons.remove_circle,
                                            color: Colors.red,
                                            size: 28,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              payments.removeAt(index);
                                            });
                                          },
                                        ),
                                      ),
                                  ],
                                ),
                                _buildDatePickerField(
                                  'Date',
                                  payment['date']!,
                                  showLabel: index == 0,
                                ),
                                _buildTextField(
                                  'Note',
                                  payment['note']!,
                                  showLabel: index == 0,
                                ),
                              ],
                            );
                          }),

                          // Add Payment Button
                          Align(
                            alignment: Alignment.center,
                            child: IconButton(
                              icon: Icon(
                                Icons.add_circle,
                                color: Colors.blue,
                                size: 32,
                              ),
                              onPressed: () {
                                setState(() {
                                  payments.add({
                                    'amount': TextEditingController(text: ''),
                                    'date': TextEditingController(text: ''),
                                    'note': TextEditingController(text: ''),
                                  });
                                });
                              },
                            ),
                          ),

                          const SizedBox(height: 8),

                          // Work Start Date & End Date
                          _buildDatePickerField(
                            'Work Start Date',
                            _workStartDateController,
                          ),
                          _buildDatePickerField(
                            'Work End Date',
                            _workEndDateController,
                          ),

                          // Is Paid
                          _buildRadioGroup(
                            'Is paid',
                            ['No', 'Yes', 'Partially'],
                            _isPaid,
                            (value) {
                              setState(() => _isPaid = value);
                            },
                          ),

                          // Is Completed
                          _buildRadioGroup(
                            'Is completed',
                            ['Pending', 'Completed'],
                            _isCompleted,
                            (value) {
                              setState(() => _isCompleted = value);
                            },
                          ),

                          // Description
                          _buildTextField(
                            'Description',
                            _descriptionController,
                            maxLines: 4,
                          ),

                          // Attachments
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Attachments',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 32,
                                    horizontal: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                    color: Colors.grey.shade50,
                                  ),
                                  child: Column(
                                    children: [
                                      if (_selectedFile != null) ...[
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.attach_file,
                                              color: primaryColor,
                                            ),
                                            const SizedBox(width: 8),
                                            Flexible(
                                              child: Text(
                                                _selectedFile!.name,
                                                style: TextStyle(
                                                  color: primaryColor,
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                Icons.close,
                                                size: 18,
                                              ),
                                              onPressed: () {
                                                setState(() {
                                                  _selectedFile = null;
                                                });
                                              },
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                      ],
                                      Text(
                                        _selectedFile == null
                                            ? 'Drag & drop your file or Browse'
                                            : 'Change file',
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      ElevatedButton(
                                        onPressed: () async {
                                          FilePickerResult? result =
                                              await FilePicker.platform
                                                  .pickFiles();
                                          if (result != null) {
                                            setState(() {
                                              _selectedFile =
                                                  result.files.single;
                                            });
                                            print(
                                              'File selected: ${_selectedFile!.name} (${_selectedFile!.size} bytes)',
                                            );
                                          }
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(
                                            0xFFE74C3C,
                                          ),
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 32,
                                            vertical: 12,
                                          ),
                                          elevation: 0,
                                        ),
                                        child: const Text(
                                          'Browse',
                                          style: TextStyle(fontSize: 14),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Invoice Info Section
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withValues(alpha: 0.08),
                            spreadRadius: 0,
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Invoice Info',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 20),
                          _buildDatePickerField(
                            'Invoice Date',
                            _invoiceDateController,
                          ),
                          _buildDatePickerField('Due Date', _dueDateController),
                          _buildTextField('Notice', _noticeController),
                          _buildTextField(
                            'Invoice Number',
                            _invoiceNumberController,
                          ),
                          _buildTextField(
                            'Currency rate',
                            _currencyRateController,
                          ),
                          _buildTextField(
                            showLabel: true,
                            'Invoice Amount',
                            _totalAmountController,
                          ),
                          _buildTextField(
                            'Discount Label',
                            _discountLabelController,
                          ),
                          _buildTextField(
                            'Discount Amount',
                            _discountAmountController,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              final success = await _saveInvoice();
                              if (success && mounted) {
                                Navigator.pop(context);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Save Invoice',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _generateAndSaveInvoice,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Generate & Save Invoice',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildDropdownField(
    String label,
    TextEditingController controller,
    List<Map<String, dynamic>> items,
    String? selectedId,
    Function(String?, String?) onChanged, {
    String idKey = 'id',
    String nameKey = 'name',
    Future<List<Map<String, dynamic>>> Function()? onDropdownOpen,
  }) {
    // Remove duplicates based on ID
    final uniqueItems = <String, Map<String, dynamic>>{};
    for (var item in items) {
      final id = item[idKey]?.toString() ?? '';
      if (id.isNotEmpty && !uniqueItems.containsKey(id)) {
        uniqueItems[id] = item;
      }
    }
    final deduplicatedItems = uniqueItems.values.toList();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, child) {
              print(
                '$label - selectedId: $selectedId, displayText: ${value.text}',
              );
              return SearchableDropdown(
                value: selectedId,
                hint: 'Select',
                items: deduplicatedItems,
                idKey: idKey,
                nameKey: nameKey,
                displayText: value.text.isNotEmpty ? value.text : null,
                onDropdownOpen: onDropdownOpen,
                onChanged: (newId) {
                  print('$label - Item selected: $newId');
                  print(
                    '$label - deduplicatedItems count: ${deduplicatedItems.length}',
                  );
                  if (newId != null) {
                    print('$label - Looking for item with $idKey = $newId');
                    final selectedItem = deduplicatedItems.firstWhere(
                      (item) {
                        final itemId = item[idKey]?.toString();
                        print(
                          '$label - Checking item: $idKey=$itemId, $nameKey=${item[nameKey]}',
                        );
                        return itemId == newId;
                      },
                      orElse: () {
                        print('$label - Item not found! Using fallback');
                        return deduplicatedItems.isNotEmpty
                            ? deduplicatedItems.first
                            : {};
                      },
                    );
                    final name = selectedItem[nameKey]?.toString() ?? '';
                    print('$label - Found item: $selectedItem');
                    print('$label - Setting controller text to: $name');
                    controller.text = name;
                    onChanged(newId, name);
                  } else {
                    print('$label - Clearing selection');
                    controller.text = '';
                    onChanged(null, null);
                  }
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
    bool showLabel = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showLabel) ...[
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
          ],
          TextField(
            controller: controller,
            maxLines: maxLines,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
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
                borderSide: BorderSide(color: primaryColor, width: 2),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatePickerField(
    String label,
    TextEditingController controller, {
    bool showLabel = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showLabel) ...[
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
          ],
          TextField(
            controller: controller,
            readOnly: true,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
            decoration: InputDecoration(
              focusColor: primaryColor,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              suffixIcon: Icon(
                Icons.calendar_today,
                color: primaryColor,
                size: 20,
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
                borderSide: BorderSide(color: primaryColor, width: 2),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            onTap: () async {
              print('🔍 Opening date picker for $label');
              print('   Current controller value: "${controller.text}"');

              // Parse existing date from controller if available
              DateTime initialDate = DateTime.now();
              if (controller.text.isNotEmpty) {
                try {
                  final parts = controller.text.split('/');
                  if (parts.length == 3) {
                    initialDate = DateTime(
                      int.parse(parts[2]), // year
                      int.parse(parts[1]), // month
                      int.parse(parts[0]), // day
                    );
                    print('   Parsed initial date: $initialDate');
                  }
                } catch (e) {
                  print('   ❌ Error parsing date: $e');
                }
              } else {
                print('   Using today as initial date');
              }

              final date = await showDatePicker(
                builder: (context, child) {
                return Theme(
                  data: Theme.of(
                    context,
                  ).copyWith(colorScheme: ColorScheme.light(primary: primaryColor)),
                  child: child!,
                );
              },
                context: context,
                initialDate: initialDate,
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );

              if (date != null) {
                final formattedDate =
                    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
                print('✅ Date selected: $formattedDate');
                setState(() {
                  controller.text = formattedDate;
                });
                print('✅ Controller updated for $label: "${controller.text}"');
              } else {
                print('⚠️ Date picker cancelled');
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRadioGroup(
    String label,
    List<String> options,
    String selectedValue,
    void Function(String) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            // decoration: BoxDecoration(
            //   color: Colors.grey.shade50,
            //   borderRadius: BorderRadius.circular(8),
            //   border: Border.all(color: Colors.grey.shade200),
            // ),
            child: RadioGroup<String>(
              groupValue: selectedValue,
              onChanged: (value) {
                if (value != null) {
                  onChanged(value);
                }
              },
              child: Row(
                children: options.map((option) {
                  final isSelected = selectedValue == option;
                  return Expanded(
                    child: InkWell(
                      onTap: () => onChanged(option),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 4,
                        ),
                        decoration: BoxDecoration(
                          // color: isSelected ? primaryColor.withOpacity(0.1) : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Radio<String>(
                              value: option,
                              groupValue: selectedValue,
                              activeColor: primaryColor,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              onChanged: (value) {
                                if (value != null) {
                                  onChanged(value);
                                }
                              },
                            ),
                            Flexible(
                              child: Text(
                                option,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isSelected
                                      ? primaryColor
                                      : Colors.black87,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

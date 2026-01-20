import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../services/invoice_service.dart';
import '../services/client_list.dart';
import '../widgets/searchable_dropdown.dart';
import '../constants/constants.dart';
import 'invoice_preview_screen.dart';

class EditInvoiceScreen extends StatefulWidget {
  final String? invoiceId;

  const EditInvoiceScreen({super.key, this.invoiceId});

  @override
  State<EditInvoiceScreen> createState() => _EditInvoiceScreenState();
}

class _EditInvoiceScreenState extends State<EditInvoiceScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _invoiceData;

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

  @override
  void initState() {
    super.initState();
    _loadInvoiceData();
  }

  Future<void> _loadInvoiceData() async {
    // Check if invoiceId is provided
    if (widget.invoiceId == null || widget.invoiceId!.isEmpty) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Invoice ID is required')));
      }
      return;
    }

    try {
      print('Loading invoice data for ID: ${widget.invoiceId}');

      final response = await InvoiceService.getUpdateInvoiceData(
        invoiceId: widget.invoiceId!,
      );

      print('Invoice data response: $response');

      if (response['success'] == true && response['data'] != null) {
        print('Invoice data loaded successfully');
        print('=== FULL INVOICE DATA ===');
        print('project_id: ${response['data']['project_id']}');
        print('project_name: ${response['data']['project_name']}');
        print('client_id: ${response['data']['client_id']}');
        print('client_name: ${response['data']['client_name']}');
        print('proposal_id: ${response['data']['proposal_id']}');
        print('proposal_name: ${response['data']['proposal_name']}');
        print('bank_id: ${response['data']['bank_id']}');
        print('bank_name: ${response['data']['bank_name']}');
        print('currency_id: ${response['data']['currency_id']}');
        print('currency_name: ${response['data']['currency_name']}');
        print('=========================');

        setState(() {
          _invoiceData = response['data'];
          _populateFormFields();
          _initializeDropdownWithInvoiceData();
          _isLoading = false;
        });

        // Fetch actual names from dropdown APIs if names are empty
        await _fetchMissingNames();
      } else {
        print('Failed to load invoice data: $response');
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to load invoice data')),
          );
        }
      }
    } catch (e) {
      print('Error loading invoice data: $e');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading invoice: $e')));
      }
    }
  }

  void _initializeDropdownWithInvoiceData() {
    // Keep dropdown lists empty initially - they will be loaded when user opens the dropdown
    // The text controllers already have the current values from _populateFormFields
    _projectList = [];
    _clientList = [];
    _proposalList = [];
    _bankList = [];
    _currencyList = [];
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

  Future<void> _fetchMissingNames() async {
    try {
      // Fetch all dropdown data to get the actual names
      final results = await Future.wait([
        if (_selectedProjectId != null) ClientList.getProjectUserList(),
        if (_selectedClientId != null) ClientList.getClientList(),
        if (_selectedProposalId != null) ClientList.getActiveProposalList(),
        if (_selectedBankId != null) ClientList.getBankList(),
        if (_selectedCurrencyId != null) ClientList.getCurrencyList(),
      ]);

      int resultIndex = 0;

      // Update project name
      if (_selectedProjectId != null && resultIndex < results.length) {
        final projectResponse = results[resultIndex++];
        if (projectResponse?['success'] == true &&
            projectResponse?['data'] != null) {
          final data = projectResponse!['data'];
          final projectList = List<Map<String, dynamic>>.from(
            data is List ? data : [data],
          );
          print(
            'Looking for project ID: $_selectedProjectId in ${projectList.length} projects',
          );
          final project = projectList.firstWhere((item) {
            final itemId = (item['project_id'] ?? item['id'])?.toString();
            print('Checking project: id=$itemId, name=${item['project_name']}');
            return itemId == _selectedProjectId;
          }, orElse: () => {});
          if (project.isNotEmpty && project['project_name'] != null) {
            print('✅ Found project name: ${project['project_name']}');
            setState(() {
              _projectController.text = project['project_name'].toString();
            });
          }
        }
      }

      // Update client name
      if (_selectedClientId != null && resultIndex < results.length) {
        final clientResponse = results[resultIndex++];
        if (clientResponse?['success'] == true &&
            clientResponse?['data'] != null) {
          final data = clientResponse!['data'];
          final clientList = List<Map<String, dynamic>>.from(
            data is List ? data : [data],
          );
          print(
            'Looking for client ID: $_selectedClientId in ${clientList.length} clients',
          );
          final client = clientList.firstWhere((item) {
            final itemId = (item['client_id'] ?? item['id'])?.toString();
            return itemId == _selectedClientId;
          }, orElse: () => {});
          if (client.isNotEmpty && client['client_name'] != null) {
            print('✅ Found client name: ${client['client_name']}');
            setState(() {
              _clientController.text = client['client_name'].toString();
            });
          }
        }
      }

      // Update proposal name
      if (_selectedProposalId != null && resultIndex < results.length) {
        final proposalResponse = results[resultIndex++];
        if (proposalResponse?['success'] == true &&
            proposalResponse?['data'] != null) {
          final data = proposalResponse!['data'];
          final proposalList = List<Map<String, dynamic>>.from(
            data is List ? data : [data],
          );
          print(
            'Looking for proposal ID: $_selectedProposalId in ${proposalList.length} proposals',
          );
          final proposal = proposalList.firstWhere((item) {
            final itemId = (item['proposal_id'] ?? item['id'])?.toString();
            print(
              'Checking proposal: id=$itemId, title=${item['project_title']}',
            );
            return itemId == _selectedProposalId;
          }, orElse: () => {});
          // Proposal API uses 'project_title' not 'proposal_name'
          final proposalName =
              proposal['project_title'] ?? proposal['proposal_name'];
          if (proposal.isNotEmpty && proposalName != null) {
            print('✅ Found proposal name: $proposalName');
            setState(() {
              _proposalController.text = proposalName.toString();
            });
          }
        }
      }

      // Update bank name
      if (_selectedBankId != null && resultIndex < results.length) {
        final bankResponse = results[resultIndex++];
        if (bankResponse?['success'] == true && bankResponse?['data'] != null) {
          final data = bankResponse!['data'];
          final bankList = List<Map<String, dynamic>>.from(
            data is List ? data : [data],
          );
          print(
            'Looking for bank ID: $_selectedBankId in ${bankList.length} banks',
          );
          final bank = bankList.firstWhere((item) {
            final itemId = (item['company_id'] ?? item['id'])?.toString();
            print('Checking bank: id=$itemId, name=${item['display_name']}');
            return itemId == _selectedBankId;
          }, orElse: () => {});
          // Bank API uses 'display_name'
          final bankName = bank['display_name'] ?? bank['company_name'];
          if (bank.isNotEmpty && bankName != null) {
            print('✅ Found bank name: $bankName');
            setState(() {
              _bankController.text = bankName.toString();
            });
          }
        }
      }

      // Update currency name
      if (_selectedCurrencyId != null && resultIndex < results.length) {
        final currencyResponse = results[resultIndex++];
        if (currencyResponse?['success'] == true &&
            currencyResponse?['data'] != null) {
          final data = currencyResponse!['data'];
          final currencyList = List<Map<String, dynamic>>.from(
            data is List ? data : [data],
          );
          print(
            'Looking for currency ID: $_selectedCurrencyId in ${currencyList.length} currencies',
          );
          final currency = currencyList.firstWhere((item) {
            final itemId = (item['currency_id'] ?? item['id'])?.toString();
            print(
              'Checking currency: id=$itemId, name=${item['name']}, currency=${item['currency']}',
            );
            return itemId == _selectedCurrencyId;
          }, orElse: () => {});
          // Currency API uses 'name' or 'currency' not 'currency_name'
          final currencyName =
              currency['name'] ??
              currency['currency'] ??
              currency['currency_name'];
          if (currency.isNotEmpty && currencyName != null) {
            print('✅ Found currency name: $currencyName');
            setState(() {
              _currencyController.text = currencyName.toString();
            });
          }
        }
      }
    } catch (e) {
      print('Error fetching missing names: $e');
    }
  }

  // New methods to load each dropdown data individually - loads from API and ensures current item is included
  Future<List<Map<String, dynamic>>> _loadProjectDropdownData() async {
    try {
      // If a client is selected and we have client-specific projects, use those
      if (_selectedClientId != null && _projectList.isNotEmpty) {
        print(
          '📋 Using client-specific project list (${_projectList.length} projects)',
        );
        return _projectList;
      }

      // Otherwise, load all projects from API (fallback for backward compatibility)
      print('📋 Loading all projects from API');
      final response = await ClientList.getProjectUserList();
      List<Map<String, dynamic>> apiData = [];

      if (response!['success'] == true && response['data'] != null) {
        final data = response['data'];
        apiData = List<Map<String, dynamic>>.from(data is List ? data : [data]);
      }

      // Ensure the current invoice project is in the list
      if (_invoiceData != null &&
          _invoiceData!['project_id'] != null &&
          _invoiceData!['project_name'] != null) {
        final currentProjectId = _invoiceData!['project_id'].toString();
        final exists = apiData.any(
          (item) =>
              (item['project_id'] ?? item['id'])?.toString() ==
              currentProjectId,
        );

        if (!exists) {
          // Add current project at the beginning if not in API data
          apiData.insert(0, {
            'id': _invoiceData!['project_id'].toString(),
            'project_id': _invoiceData!['project_id'].toString(),
            'project_name': _invoiceData!['project_name'].toString(),
          });
        }
      }

      // Update the state list so it's available in onChanged callback
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

      // Ensure the current invoice client is in the list
      if (_invoiceData != null &&
          _invoiceData!['client_id'] != null &&
          _invoiceData!['client_name'] != null) {
        final currentClientId = _invoiceData!['client_id'].toString();
        final exists = apiData.any(
          (item) => item['client_id']?.toString() == currentClientId,
        );

        if (!exists) {
          apiData.insert(0, {
            'client_id': _invoiceData!['client_id'].toString(),
            'client_name': _invoiceData!['client_name'].toString(),
          });
        }
      }

      // Update the state list so it's available in onChanged callback
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

      // Ensure the current invoice proposal is in the list
      if (_invoiceData != null &&
          _invoiceData!['proposal_id'] != null &&
          _invoiceData!['proposal_name'] != null) {
        final currentProposalId = _invoiceData!['proposal_id'].toString();
        final exists = apiData.any(
          (item) => item['proposal_id']?.toString() == currentProposalId,
        );

        if (!exists) {
          apiData.insert(0, {
            'proposal_id': _invoiceData!['proposal_id'].toString(),
            'proposal_name': _invoiceData!['proposal_name'].toString(),
          });
        }
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

      // Ensure the current invoice bank is in the list
      if (_invoiceData != null &&
          _invoiceData!['bank_id'] != null &&
          _invoiceData!['bank_name'] != null) {
        final currentBankId = _invoiceData!['bank_id'].toString();
        final exists = apiData.any(
          (item) =>
              (item['company_id'] ?? item['id'])?.toString() == currentBankId,
        );

        if (!exists) {
          apiData.insert(0, {
            'id': _invoiceData!['bank_id'].toString(),
            'display_name': _invoiceData!['bank_name'].toString(),
          });
        }
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

      // Ensure the current invoice currency is in the list
      if (_invoiceData != null &&
          _invoiceData!['currency_id'] != null &&
          _invoiceData!['currency_name'] != null) {
        final currentCurrencyId = _invoiceData!['currency_id'].toString();
        final exists = apiData.any(
          (item) => item['currency_id']?.toString() == currentCurrencyId,
        );

        if (!exists) {
          apiData.insert(0, {
            'currency_id': _invoiceData!['currency_id'].toString(),
            'currency_name': _invoiceData!['currency_name'].toString(),
          });
        }
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

  void _populateFormFields() {
    if (_invoiceData == null) {
      print('Invoice data is null, cannot populate fields');
      return;
    }

    print('Populating form fields with invoice data');
    print('Available keys in invoice data: ${_invoiceData!.keys.toList()}');

    // Populate basic fields with IDs and names
    _selectedProjectId = _invoiceData!['project_id']?.toString();
    final projectName = _invoiceData!['project_name']?.toString() ?? '';
    // If name is empty, show placeholder with ID
    _projectController.text = projectName.trim().isNotEmpty
        ? projectName
        : (_selectedProjectId != null ? 'Project #$_selectedProjectId' : '');
    print(
      '✅ Project: ID=$_selectedProjectId, Name=$projectName, Controller=${_projectController.text}',
    );

    _selectedClientId = _invoiceData!['client_id']?.toString();
    final clientName = _invoiceData!['client_name']?.toString() ?? '';
    // If name is empty, show placeholder with ID
    _clientController.text = clientName.trim().isNotEmpty
        ? clientName
        : (_selectedClientId != null ? 'Client #$_selectedClientId' : '');
    print(
      '✅ Client: ID=$_selectedClientId, Name=$clientName, Controller=${_clientController.text}',
    );

    _selectedProposalId = _invoiceData!['proposal_id']?.toString();
    final proposalName = _invoiceData!['proposal_name']?.toString() ?? '';
    // If name is empty, show placeholder with ID
    _proposalController.text = proposalName.trim().isNotEmpty
        ? proposalName
        : (_selectedProposalId != null ? 'Proposal #$_selectedProposalId' : '');
    print(
      '✅ Proposal: ID=$_selectedProposalId, Name=$proposalName, Controller=${_proposalController.text}',
    );

    _selectedBankId = _invoiceData!['company_id']?.toString();
    final bankName = _invoiceData!['bank_name']?.toString() ?? '';
    // If name is empty, show placeholder with ID
    _bankController.text = bankName.trim().isNotEmpty
        ? bankName
        : (_selectedBankId != null ? 'Bank #$_selectedBankId' : '');
    print(
      '✅ Bank: ID=$_selectedBankId, Name=$bankName, Controller=${_bankController.text}',
    );

    _selectedCurrencyId = _invoiceData!['currency_id']?.toString();
    final currencyName = _invoiceData!['currency_name']?.toString() ?? '';
    // If name is empty, show placeholder with ID
    _currencyController.text = currencyName.trim().isNotEmpty
        ? currencyName
        : (_selectedCurrencyId != null ? 'Currency #$_selectedCurrencyId' : '');
    print(
      '✅ Currency: ID=$_selectedCurrencyId, Name=$currencyName, Controller=${_currencyController.text}',
    );

    _addressController.text = _invoiceData!['client_address']?.toString() ?? '';
    _invoiceNumberController.text =
        _invoiceData!['reference']?.toString() ?? '';
    _descriptionController.text =
        _invoiceData!['invoice_description']?.toString() ?? '';
    _noticeController.text = _invoiceData!['notice']?.toString() ?? '';
    _discountLabelController.text =
        _invoiceData!['discount_label']?.toString() ?? '';
    _discountAmountController.text =
        _invoiceData!['discount_amount']?.toString() ?? '0';
    _currencyRateController.text =
        _invoiceData!['invoice_rate']?.toString() ?? '1.00';

    // Parse dates
    if (_invoiceData!['invoice_date'] != null) {
      _invoiceDateController.text = _formatDate(_invoiceData!['invoice_date']);
    }
    if (_invoiceData!['due_date'] != null) {
      _dueDateController.text = _formatDate(_invoiceData!['due_date']);
    }

    // Work info
    if (_invoiceData!['work_info'] != null) {
      final workInfo = _invoiceData!['work_info'];

      _totalAmountController.text = workInfo['price_amount']?.toString() ?? '';

      // Parse work dates
      if (workInfo['work_start_date'] != null &&
          workInfo['work_start_date'].toString().isNotEmpty) {
        _workStartDateController.text = _formatDate(
          workInfo['work_start_date'],
        );
      }
      if (workInfo['work_end_date'] != null &&
          workInfo['work_end_date'].toString().isNotEmpty) {
        _workEndDateController.text = _formatDate(workInfo['work_end_date']);
      }

      // Is completed
      _isCompleted = (workInfo['is_completed'] == 1) ? 'Completed' : 'Pending';

      // Is paid - handle both work_info.is_paid and root level is_paid
      final isPaidValue = workInfo['is_paid'] ?? _invoiceData!['is_paid'] ?? 0;
      if (isPaidValue == 0) {
        _isPaid = 'No';
      } else if (isPaidValue == 1) {
        _isPaid = 'Yes';
      } else if (isPaidValue == 2) {
        _isPaid = 'Partially';
      }

      // Parse payment entries
      if (workInfo['work_paid_amount'] != null &&
          workInfo['work_paid_amount'] is List) {
        final paidAmounts = workInfo['work_paid_amount'] as List;
        print('📋 Loading ${paidAmounts.length} payment entries from API');
        if (paidAmounts.isNotEmpty) {
          payments = paidAmounts.map((payment) {
            // API returns 'paid_amount' not 'amount'
            final amount = payment['paid_amount']?.toString() ?? '';
            final date = payment['date']?.toString() ?? '';
            final note = payment['note']?.toString() ?? '';
            print('  - Amount: $amount, Date: $date, Note: $note');
            return {
              'amount': TextEditingController(text: amount),
              'date': TextEditingController(text: _formatDate(date)),
              'note': TextEditingController(text: note),
            };
          }).toList();
        }
      }

      // Add empty payment entry if none exist
      if (payments.isEmpty) {
        print('📋 No payment entries found, adding empty entry');
        payments.add({
          'amount': TextEditingController(text: ''),
          'date': TextEditingController(text: ''),
          'note': TextEditingController(text: ''),
        });
      }
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  Future<void> _saveInvoice() async {
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
      // Convert DD/MM/YYYY to YYYY-MM-DD format for API
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
      // Convert DD/MM/YYYY to YYYY-MM-DD format for API
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
    };

    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('📦 WORK INFO OBJECT BEING SENT TO API:');
    print('   work_start_date: "$formattedStartDate"');
    print('   work_end_date: "$formattedEndDate"');
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

    try {
      final result = await InvoiceService.postUpdateInvoice(
        context: context,
        invoice_id: widget.invoiceId ?? '',
        client_id: _selectedClientId ?? '',
        project_id: _selectedProjectId ?? '',
        currency_id: _selectedCurrencyId ?? '',
        client_address: _addressController.text,
        company_id: _selectedBankId ?? '',
        invoice_rate: _currencyRateController.text.isNotEmpty
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
        direction: 'desc',
        work_info: jsonEncode(workInfo),
        attachment: attachmentBase64,
        attachmentFileName: attachmentFileName,
      );

      if (result?['success'] == true) {
        if (mounted) {
          Navigator.pop(context);
        }
      } else {
        print('❌ Update failed: ${result?['message']}');
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
    }
  }

  Future<void> _generateAndSaveInvoice() async {
    await _saveInvoice();
    if (mounted) {
      double totalAmount = double.tryParse(_totalAmountController.text) ?? 0.0;
      double discountAmount = double.tryParse(_discountAmountController.text) ?? 0.0;
      double totalDue = totalAmount - discountAmount;

      print('💰 Invoice Amount Calculation:');
      print('   Work Total Amount: $totalAmount');
      print('   Discount Amount: $discountAmount');
      print('   Total Due: $totalDue');

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
              'tasks': [
                {
                  'description': _workTitleController.text.isNotEmpty
                      ? _workTitleController.text
                      : 'Work Description',
                  'date': '${_workStartDateController.text}${_workEndDateController.text.isNotEmpty ? ' - ${_workEndDateController.text}' : ''}',
                  'hours': '8',
                  'amount': _totalAmountController.text.isNotEmpty
                      ? _totalAmountController.text
                      : '0',
                },
              ],
              'total_hours': '8',
              'subtotal': _totalAmountController.text.isNotEmpty
                  ? _totalAmountController.text
                  : '0',
              'total_due': totalDue.toStringAsFixed(2),
              'discount': _discountAmountController.text.isNotEmpty
                  ? _discountAmountController.text
                  : null,
              'discount_label': _discountLabelController.text.isNotEmpty
                  ? _discountLabelController.text
                  : null,
              'currency_rate': _currencyRateController.text.isNotEmpty
                  ? _currencyRateController.text
                  : '1',
              'description': _descriptionController.text,
              'is_paid': _isPaid == 'Yes' ? 1 : (_isPaid == 'Partially' ? 2 : 0),
            },
            invoiceId: widget.invoiceId,
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
          ? Center(
              child: CircularProgressIndicator(color: primaryColor),
            )
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
                          'Edit Invoice',
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
                                color: Colors.blueAccent,
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
                            onPressed: _saveInvoice,
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
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          RadioGroup<String>(
            groupValue: selectedValue,
            onChanged: (value) {
              if (value != null) {
                onChanged(value);
              }
            },
            child: Row(
              children: options.map((option) {
                return Expanded(
                  child: InkWell(
                    onTap: () => onChanged(option),
                    child: Row(
                      children: [
                        Radio<String>(
                          value: option,
                          activeColor: const Color(0xFF4A90E2),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                        Flexible(
                          child: Text(
                            option,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

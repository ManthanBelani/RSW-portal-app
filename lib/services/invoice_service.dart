import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'api_client.dart';
import '../models/invoice_record.dart';
import 'auth_service.dart';
import 'header_service.dart';

class InvoiceService {
  static const String baseUrl =
      'https://rainflowweb.com/demo/account-upgrade/api/invoice';

  /// Fetch invoice list with filters
  static Future<Map<String, dynamic>> getInvoiceList({
    String direction = 'desc',
    int column = 3,
    int perPage = 50,
    int pageCount = 1,
    String search = '',
    int isArchive = 0,
    String? clientId,
    String? startDate,
    String? endDate,
    String? isPaid,
    String? isCompleted,
  }) async {
    try {
      // Build query parameters
      final queryParams = <String, String>{
        'direction': direction,
        'column': column.toString(),
        'per_page': perPage.toString(),
        'page_count': pageCount.toString(),
        'search': search, // Always include search, even if empty
        'is_archive': isArchive.toString(),
      };

      if (clientId != null && clientId.isNotEmpty) {
        queryParams['client_id'] = clientId;
      }
      if (startDate != null && startDate.isNotEmpty) {
        queryParams['startDate'] = startDate;
      }
      if (endDate != null && endDate.isNotEmpty) {
        queryParams['endDate'] = endDate;
      }
      if (isPaid != null && isPaid.isNotEmpty) {
        queryParams['is_paid'] = isPaid;
      }
      if (isCompleted != null && isCompleted.isNotEmpty) {
        queryParams['is_completed'] = isCompleted;
      }

      final uri = Uri.parse(
        '$baseUrl/list_invoice.php',
      ).replace(queryParameters: queryParams);

      final response = await ApiClient.get(uri.toString());

      if (response.statusCode == 200) {
        print('Invoice API Response Body Length: ${response.body.length}');
        print(
          'Invoice API Response Body: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}...',
        );

        // Check if response body is empty or whitespace
        if (response.body.trim().isEmpty) {
          print('Warning: Empty response body from invoice API');
          throw Exception('Empty response from server');
        }

        final data = json.decode(response.body);
        print('Invoice API Response Decoded Successfully');
        return data;
      } else {
        throw Exception('Failed to load invoices: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching invoices: $e');
      rethrow;
    }
  }

  /// Parse invoice data from API response
  static List<InvoiceRecord> parseInvoices(List<dynamic> invoiceData) {
    return invoiceData.map((json) {
      return InvoiceRecord.fromApiJson(json as Map<String, dynamic>);
    }).toList();
  }

  /// Update invoice work end date
  static Future<bool> updateWorkEndDate({
    required String invoiceId,
    required String workEndDate,
  }) async {
    try {
      final response = await ApiClient.post(
        '$baseUrl/update_work_end_date.php',
        {'invoice_id': invoiceId, 'work_end_date': workEndDate},
        isFormData: true,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      print('Error updating work end date: $e');
      return false;
    }
  }

  /// Get invoice by ID with full details including user_details
  static Future<Map<String, dynamic>?> getInvoiceById(String invoiceId) async {
    try {
      print('🔍 Fetching invoice details for ID: $invoiceId');

      final uri = Uri.parse('$baseUrl/list_invoice.php').replace(
        queryParameters: {
          'direction': 'desc',
          'column': '4',
          'per_page': '500',
          'search': '',
        },
      );

      print('📡 API URL: ${uri.toString()}');
      final response = await ApiClient.get(uri.toString());

      if (response.statusCode == 200) {
        print('✅ Response received (${response.body.length} bytes)');
        
        if (response.body.trim().isEmpty) {
          print('❌ Empty response body from invoice API');
          return null;
        }

        final data = json.decode(response.body);
        print('📦 Decoded data keys: ${data.keys.toList()}');
        
        // Handle different response structures
        if (data['success'] == true) {
          print('✅ API returned success');
          
          // Check if data is in 'data' key
          if (data['data'] != null) {
            print('📋 Data type: ${data['data'].runtimeType}');
            
            // If data.data is a Map with 'data' key (nested structure)
            if (data['data'] is Map && data['data']['data'] != null) {
              final innerData = data['data']['data'] as List;
              print('📋 Inner data list count: ${innerData.length}');
              
              // Find the invoice with matching ID
              final invoice = innerData.firstWhere(
                (item) => item['id'].toString() == invoiceId,
                orElse: () => null,
              );
              
              if (invoice != null) {
                print('✅ Found invoice with ID $invoiceId');
                print('📋 Invoice keys: ${invoice.keys.toList()}');
                print('📋 Has user_details: ${invoice.containsKey('user_details')}');
                print('📋 User details count: ${invoice['user_details']?.length ?? 0}');
                print('📋 Has work_info: ${invoice.containsKey('work_info')}');
                return {
                  'success': true,
                  'data': invoice,
                };
              } else {
                print('❌ Invoice with ID $invoiceId not found in ${innerData.length} records');
                return null;
              }
            }
            // If data is a direct Map (single invoice)
            else if (data['data'] is Map && data['data']['id'].toString() == invoiceId) {
              print('✅ Found invoice in direct Map structure');
              print('📋 Invoice keys: ${data['data'].keys.toList()}');
              return data;
            }
            // If data is a List
            else if (data['data'] is List) {
              final dataList = data['data'] as List;
              print('📋 Data list count: ${dataList.length}');
              
              // Find the invoice with matching ID
              final invoice = dataList.firstWhere(
                (item) => item['id'].toString() == invoiceId,
                orElse: () => null,
              );
              
              if (invoice != null) {
                print('✅ Found invoice with ID $invoiceId');
                print('📋 Invoice keys: ${invoice.keys.toList()}');
                return {
                  'success': true,
                  'data': invoice,
                };
              } else {
                print('❌ Invoice with ID $invoiceId not found in ${dataList.length} records');
                return null;
              }
            }
          }
        }
        
        print('⚠️ Unexpected response structure');
        return null;
      } else {
        print('❌ Failed to load invoice: ${response.statusCode}');
        return null;
      }
    } catch (e, stackTrace) {
      print('❌ Error fetching invoice by ID: $e');
      print('Stack trace: $stackTrace');
      return null;
    }
  }

  static Future<Map<String, dynamic>> getUpdateInvoiceData({
    required String invoiceId,
  }) async {
    final baseUrl1 = dotenv.env['BASE_URL'];
    final getUpdateInvoiceApiUrl =
        '$baseUrl1/invoice/update_invoice.php?invoice_id=$invoiceId';

    try {
      final response = await ApiClient.get(getUpdateInvoiceApiUrl);
      if (response.statusCode == 200) {
        print('Invoice API Response Body Length: ${response.body.length}');
        print(
          'Invoice API Response Body: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}...',
        );

        if (response.body.trim().isEmpty) {
          print('Warning: Empty response body from invoice API');
          throw Exception('Empty response from server');
        }
        final data = json.decode(response.body);
        print('Invoice API Response Decoded Successfully');
        return data;
      } else {
        throw Exception('Failed to load invoices: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching invoices: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> getProjectClientData() async {
    final baseUrl1 = dotenv.env['BASE_URL'];
    final getProjectClientApiUrl =
        '$baseUrl1/invoice/get_project_client_data.php?value=481';

    try {
      final response = await ApiClient.get(getProjectClientApiUrl);
      if (response.statusCode == 200) {
        print('Invoice API Response Body Length: ${response.body.length}');
        print(
          'Invoice API Response Body: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}...',
        );

        if (response.body.trim().isEmpty) {
          print('Warning: Empty response body from invoice API');
          throw Exception('Empty response from server');
        }
        final data = json.decode(response.body);
        print('Invoice API Response Decoded Successfully');
        return data;
      } else {
        throw Exception('Failed to load invoices: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching invoices: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>?> postUpdateInvoice({
    required BuildContext context,
    required String invoice_id,
    required String client_id,
    required String project_id,
    required String currency_id,
    required String client_address,
    required String company_id,
    required String invoice_rate,
    required String invoice_date,
    required String due_date,
    required String discount_label,
    required String discount_amount,
    required String invoice_description,
    required String is_paid,
    required String reference,
    required String task_filter,
    required String notice,
    required String direction,
    String? work_info,
    String? attachment,
    String? attachmentFileName,
  }) async {
    final postupdateApiUrl = '$baseUrl/update_invoice.php';
    try {
      final header = await HeadersService.getAuthHeaders();
      final Map<String, String> leaveDataToApprove = {
        'invoice_id': invoice_id,
        'client_id': client_id,
        'project_id': project_id,
        'currency_id': currency_id,
        'client_address': client_address,
        'company_id': company_id,
        'invoice_rate': invoice_rate,
        'invoice_date': invoice_date,
        'due_date': due_date,
        'discount_label': discount_label,
        'discount_amount': discount_amount,
        'invoice_description': invoice_description,
        'is_paid': is_paid,
        'reference': reference,
        'task_filter': task_filter,
        'notice': notice,
        'direction': direction,
        'invoice_type': 'invoice',
      };

      // Add work_info JSON if provided
      if (work_info != null) {
        leaveDataToApprove['work_info'] = work_info;
        print('📤 Sending work_info to API: $work_info');
      }

      // Add attachment if provided
      if (attachment != null && attachmentFileName != null) {
        leaveDataToApprove['attachment'] = attachment;
        leaveDataToApprove['attachment_name'] = attachmentFileName;
        print('📤 Sending attachment: $attachmentFileName');
      }

      print('📤 Full API request data: $leaveDataToApprove');

      final response = await AuthService.makeAuthenticatedPost(
        postupdateApiUrl,
        leaveDataToApprove,
        extraHeaders: header,
        isFormData: true,
      );

      if (!context.mounted) return null;

      print('📥 API Response Status: ${response.statusCode}');
      print('📥 API Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Parse the response body to check actual success
        try {
          final responseData = jsonDecode(response.body);
          print('📥 Parsed Response: $responseData');

          if (responseData['success'] == true ||
              responseData['status'] == 'success') {
            print('✅ Invoice Updated Successfully!');
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Invoice Updated Successfully!'),
                backgroundColor: Colors.green,
              ),
            );
            return {
              'success': true,
              'message': 'Invoice Updated successfully!',
              'data': responseData,
            };
          } else {
            // API returned error in response body
            final errorMessage =
                responseData['message'] ??
                responseData['error'] ??
                'Failed to update invoice';
            print('❌ API Error: $errorMessage');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(errorMessage),
                backgroundColor: Colors.red,
              ),
            );
            return {'success': false, 'message': errorMessage};
          }
        } catch (e) {
          print('❌ Error parsing response: $e');
          // If we can't parse the response, assume success based on status code
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invoice Updated Successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          return {'success': true, 'message': 'Invoice Updated successfully!'};
        }
      } else {
        print('❌ HTTP Error: ${response.statusCode}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update invoice.'),
            backgroundColor: Colors.red,
          ),
        );
        return {'success': false, 'message': 'Failed to update invoice.'};
      }
    } catch (e) {
      print(e);
      if (!context.mounted) return null;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>?> addInvoice({
    required BuildContext context,
    required String project_name,
    required String client_id,
    required String project_id,
    required String currency_id,
    required String client_address,
    required String company_id,
    required String invoice_rate,
    required String invoice_date,
    required String due_date,
    required String discount_label,
    required String discount_amount,
    required String invoice_description,
    required String is_paid,
    required String reference,
    required String task_filter,
    required String notice,
    required String hourly_rate,
    required String direction,
    String? proposal_id,
    String? client_name,
    String? invoice_no,
    String? currency_rate,
    String? expense_amount,
    String? work_info,
    String? attachment,
    String? attachmentFileName,
  }) async {
    final postupdateApiUrl = '$baseUrl/add_invoice.php';
    try {
      final header = await HeadersService.getAuthHeaders();
      final Map<String, String> leaveDataToApprove = {
        'client_id': client_id,
        'project_id': project_id,
        'project_name': project_name,
        'currency_id': currency_id,
        'client_address': client_address,
        'company_id': company_id,
        'invoice_rate': invoice_rate,
        'invoice_date': invoice_date,
        'due_date': due_date,
        'discount_label': discount_label,
        'discount_amount': discount_amount,
        'invoice_description': invoice_description,
        'is_paid': is_paid,
        'hourly_rate': hourly_rate,
        'reference': reference,
        'task_filter': task_filter,
        'notice': notice,
        'direction': direction,
        'invoice_type': 'invoice',
      };

      // Add optional fields if provided
      if (proposal_id != null && proposal_id.isNotEmpty) {
        leaveDataToApprove['proposal_id'] = proposal_id;
      }
      if (client_name != null && client_name.isNotEmpty) {
        leaveDataToApprove['client_name'] = client_name;
      }
      if (invoice_no != null && invoice_no.isNotEmpty) {
        leaveDataToApprove['invoice_no'] = invoice_no;
      }
      if (currency_rate != null && currency_rate.isNotEmpty) {
        leaveDataToApprove['currency_rate'] = currency_rate;
      }
      if (expense_amount != null && expense_amount.isNotEmpty) {
        leaveDataToApprove['expense_amount'] = expense_amount;
      }

      // Add work_info JSON if provided
      if (work_info != null) {
        leaveDataToApprove['work_info'] = work_info;
        print('📤 Sending work_info to API: $work_info');
      }

      // Add attachment if provided
      if (attachment != null && attachmentFileName != null) {
        leaveDataToApprove['attachment'] = attachment;
        leaveDataToApprove['attachment_name'] = attachmentFileName;
        print('📤 Sending attachment: $attachmentFileName');
      }

      print('📤 Full API request data: $leaveDataToApprove');

      final response = await AuthService.makeAuthenticatedPost(
        postupdateApiUrl,
        leaveDataToApprove,
        extraHeaders: header,
        isFormData: true,
      );

      if (!context.mounted) return null;

      print('📥 API Response Status: ${response.statusCode}');
      print('📥 API Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Parse the response body to check actual success
        try {
          final responseData = jsonDecode(response.body);
          print('📥 Parsed Response: $responseData');

          if (responseData['success'] == true ||
              responseData['status'] == 'success') {
            print('✅ Invoice Added Successfully!');

            // Extract invoice ID from response if available
            final invoiceId =
                responseData['data']?['invoice_id']?.toString() ??
                responseData['data']?['id']?.toString() ??
                responseData['invoice_id']?.toString() ??
                responseData['id']?.toString();

            if (invoiceId != null) {
              print('✅ Invoice ID from API: $invoiceId');
            }

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Invoice Added Successfully!'),
                backgroundColor: Colors.green,
              ),
            );
            return {
              'success': true,
              'message': 'Invoice added successfully!',
              'data': responseData,
              'invoice_id': invoiceId,
            };
          } else {
            // API returned error in response body
            final errorMessage =
                responseData['message'] ??
                responseData['error']?['message'] ??
                responseData['error'] ??
                'Failed to add invoice';
            print('❌ API Error: $errorMessage');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(errorMessage),
                backgroundColor: Colors.red,
              ),
            );
            return {'success': false, 'message': errorMessage};
          }
        } catch (e) {
          print('❌ Error parsing response: $e');
          // If we can't parse the response, assume success based on status code
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invoice Added Successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          return {'success': true, 'message': 'Invoice added successfully!'};
        }
      } else {
        print('❌ HTTP Error: ${response.statusCode}');

        // Try to parse error message from response body
        try {
          final errorData = jsonDecode(response.body);
          final errorMessage =
              errorData['error']?['message'] ??
              errorData['message'] ??
              'Failed to add invoice';
          print('❌ Error message: $errorMessage');

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
          );
          return {'success': false, 'message': errorMessage};
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to add invoice.'),
              backgroundColor: Colors.red,
            ),
          );
          return {'success': false, 'message': 'Failed to add invoice.'};
        }
      }
    } catch (e) {
      print(e);
      if (!context.mounted) return null;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>?> postGenerateInvoice({
    required BuildContext context,
    required String invoice_id,
    required String client_id,
    required String project_id,
    required String currency_id,
    required String client_address,
    required String company_id,
    required String invoice_rate,
    required String invoice_date,
    required String due_date,
    required String discount_label,
    required String discount_amount,
    required String invoice_description,
    required String is_paid,
    required String reference,
    required String task_filter,
    required String notice,
    required String direction,
    String? work_info,
    String? attachment,
    String? attachmentFileName,
  }) async {
    final postupdateApiUrl = '$baseUrl/generate_invoice.php';
    try {
      final header = await HeadersService.getAuthHeaders();
      final Map<String, String> invoiceDatatoGenerateInvoice = {
        'invoice_id': invoice_id,
        'client_id': client_id,
        'project_id': project_id,
        'currency_id': currency_id,
        'client_address': client_address,
        'company_id': company_id,
        'invoice_rate': invoice_rate,
        'invoice_date': invoice_date,
        'due_date': due_date,
        'discount_label': discount_label,
        'discount_amount': discount_amount,
        'invoice_description': invoice_description,
        'is_paid': is_paid,
        'reference': reference,
        'task_filter': task_filter,
        'notice': notice,
        'direction': direction,
        'invoice_type': 'invoice',
      };

      // Add work_info JSON if provided
      if (work_info != null) {
        invoiceDatatoGenerateInvoice['work_info'] = work_info;
        print('📤 Sending work_info to API: $work_info');
      }

      // Add attachment if provided
      if (attachment != null && attachmentFileName != null) {
        invoiceDatatoGenerateInvoice['attachment'] = attachment;
        invoiceDatatoGenerateInvoice['attachment_name'] = attachmentFileName;
        print('📤 Sending attachment: $attachmentFileName');
      }

      print('📤 Full API request data: $invoiceDatatoGenerateInvoice');

      final response = await AuthService.makeAuthenticatedPost(
        postupdateApiUrl,
        invoiceDatatoGenerateInvoice,
        extraHeaders: header,
        isFormData: true,
      );

      if (!context.mounted) return null;

      print('📥 API Response Status: ${response.statusCode}');
      print('📥 API Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Parse the response body to check actual success
        try {
          final responseData = jsonDecode(response.body);
          print('📥 Parsed Response: $responseData');

          if (responseData['success'] == true ||
              responseData['status'] == 'success') {
            print('✅ generate invoice details Successfully!');
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('generate invoice details Successfully!'),
                backgroundColor: Colors.green,
              ),
            );
            return {
              'success': true,
              'message': 'generate invoice details successfully!',
              'data': responseData,
            };
          } else {
            // API returned error in response body
            final errorMessage =
                responseData['message'] ??
                responseData['error'] ??
                'Failed to generate invoice details';
            print('❌ API Error: $errorMessage');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(errorMessage),
                backgroundColor: Colors.red,
              ),
            );
            return {'success': false, 'message': errorMessage};
          }
        } catch (e) {
          print('❌ Error parsing response: $e');
          // If we can't parse the response, assume success based on status code
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('generate invoice details Successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          return {
            'success': true,
            'message': 'generate invoice details successfully!',
          };
        }
      } else {
        print('❌ HTTP Error: ${response.statusCode}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update invoice.'),
            backgroundColor: Colors.red,
          ),
        );
        return {
          'success': false,
          'message': 'Failed to generate invoice details.',
        };
      }
    } catch (e) {
      print(e);
      if (!context.mounted) return null;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>?> postGenerateInvoicePDF({
    required BuildContext context,
    required String invoice_id,
  }) async {
    final postupdateApiUrl = '$baseUrl/generate_invoice_pdf.php';
    try {
      final header = await HeadersService.getAuthHeaders();
      final Map<String, String> generateInvoicePDF = {'invoice_id': invoice_id};

      print('📤 Full API request data: $generateInvoicePDF');

      final response = await AuthService.makeAuthenticatedPost(
        postupdateApiUrl,
        generateInvoicePDF,
        extraHeaders: header,
        isFormData: true,
      );

      if (!context.mounted) return null;

      print('📥 API Response Status: ${response.statusCode}');
      print('📥 API Response Headers: ${response.headers}');
      print('📥 API Response Body (first 500 chars): ${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}');

      // Check if response is actually a PDF (binary data)
      final contentType = response.headers['content-type'] ?? '';
      if (contentType.contains('application/pdf')) {
        print('✅ Response is a PDF file!');
        // Return the PDF bytes directly
        return {
          'success': true,
          'message': 'PDF generated successfully',
          'pdf_bytes': response.bodyBytes,
          'is_direct_pdf': true,
        };
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Parse the response body to check actual success
        try {
          final responseData = jsonDecode(response.body);
          print('📥 Parsed Response: $responseData');

          if (responseData['success'] == true ||
              responseData['status'] == 'success') {
            // Extract PDF URL from response
            final pdfUrl =
                responseData['data']?['pdf_url'] ??
                responseData['data']?['url'] ??
                responseData['data']?['pdf_path'] ??
                responseData['data']?['file_path'] ??
                responseData['pdf_url'] ??
                responseData['url'] ??
                responseData['pdf_path'];

            print('✅ Invoice PDF generated successfully!');
            print('📄 PDF URL: $pdfUrl');

            // Check if URL is a PHP script
            if (pdfUrl != null && pdfUrl.toString().contains('.php')) {
              print('⚠️ WARNING: PDF URL points to a PHP script: $pdfUrl');
              print('⚠️ This may cause download issues. The API should return a direct PDF file URL.');
            }

            return {
              'success': true,
              'message': 'Invoice PDF generated successfully!',
              'data': responseData,
              'pdf_url': pdfUrl,
              'is_direct_pdf': false,
            };
          } else {
            // API returned error in response body
            final errorMessage =
                responseData['message'] ??
                responseData['error']?['message'] ??
                responseData['error'] ??
                'Failed to generate invoice PDF';
            print('❌ API Error: $errorMessage');

            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(errorMessage),
                  backgroundColor: Colors.red,
                ),
              );
            }
            return {'success': false, 'message': errorMessage};
          }
        } catch (e) {
          print('❌ Error parsing response: $e');
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Error parsing PDF response'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return {'success': false, 'message': 'Error parsing response: $e'};
        }
      } else {
        print('❌ HTTP Error: ${response.statusCode}');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to generate invoice PDF.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return {'success': false, 'message': 'Failed to generate invoice PDF.'};
      }
    } catch (e) {
      print('❌ Exception in postGenerateInvoicePDF: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return {'success': false, 'message': e.toString()};
    }
  }
}

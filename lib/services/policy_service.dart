import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'auth_service.dart';
import 'header_service.dart';

class PolicyService {
  static final baseUrl = dotenv.env['BASE_URL'];
  static final downloadPolicyApiUrl = '$baseUrl/download_privacy_policy.php';

  static Future<Map<String, dynamic>?> postDownloadPolicyPDF({
    required BuildContext context,
    required List<String> privacy_policy,
  }) async {
    try {
      final header = await HeadersService.getAuthHeaders();
      
      // Convert list to JSON string for form data
      final Map<String, dynamic> formData = {
        'privacy_policy': jsonEncode(privacy_policy),
      };

      print('📤 Full API request data: $formData');

      final response = await AuthService.makeAuthenticatedPost(
        downloadPolicyApiUrl,
        formData,
        extraHeaders: header,
        isFormData: true,
      );

      if (!context.mounted) return null;

      print('📥 API Response Status: ${response.statusCode}');
      print('📥 API Response Headers: ${response.headers}');
      print('📥 API Response Body (first 500 chars): ${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}');

      final contentType = response.headers['content-type'] ?? '';
      if (contentType.contains('application/pdf')) {
        print('✅ Response is a PDF file!');
        return {
          'success': true,
          'message': 'PDF generated successfully',
          'pdf_bytes': response.bodyBytes,
          'is_direct_pdf': true,
        };
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final responseData = jsonDecode(response.body);
          print('📥 Parsed Response: $responseData');

          if (responseData['success'] == true) {
            final downloadLink = responseData['data']?['download_link'];
            final message = responseData['data']?['message'] ?? 'Policy PDF generated successfully';

            print('✅ Policy PDF generated successfully!');
            print('📄 Download Link: $downloadLink');

            if (downloadLink != null) {
              // Download the PDF from the link
              print('📥 Downloading PDF from: $downloadLink');
              final pdfResponse = await AuthService.makeAuthenticatedGet(
                downloadLink,
                extraHeaders: header,
              );

              if (pdfResponse.statusCode == 200) {
                print('✅ PDF downloaded successfully! Size: ${pdfResponse.bodyBytes.length} bytes');
                return {
                  'success': true,
                  'message': message,
                  'pdf_bytes': pdfResponse.bodyBytes,
                  'is_direct_pdf': true,
                };
              } else {
                print('❌ Failed to download PDF. Status: ${pdfResponse.statusCode}');
                return {
                  'success': false,
                  'message': 'Failed to download PDF file',
                };
              }
            }

            return {
              'success': true,
              'message': message,
              'data': responseData,
              'is_direct_pdf': false,
            };
          } else {
            final errorMessage =
                responseData['message'] ??
                    responseData['error']?['message'] ??
                    responseData['error'] ??
                    'Failed to generate Policy PDF';
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
              content: Text('Failed to generate Policy PDF.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return {'success': false, 'message': 'Failed to generate Policy PDF.'};
      }
    } catch (e) {
      print('❌ Exception in PolicyPDF: $e');
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
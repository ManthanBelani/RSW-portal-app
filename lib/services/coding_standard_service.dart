import 'dart:convert';

import 'package:dashboard_clone/services/api_client.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class CodingStandardService {
  static final baseUrl = dotenv.env['BASE_URL'];
  static final codingStandardListApiUrl =
      '$baseUrl/utils/coding_standard_list.php';
  static final getCodingStandardApiUrl =
      '$baseUrl/coding_standard/view_coding_standard.php';

  static Future<Map<String, dynamic>?> getCodingStandardList() async {
    try {
      print('=== Coding Standard Service ===');
      print('Making authenticated request to: $codingStandardListApiUrl');

      final response = await ApiClient.get(codingStandardListApiUrl);

      print('CodingStandard Response Status: ${response.statusCode}');
      print('CodingStandard Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final responseData = json.decode(response.body);
          if (responseData['success'] == true) {
            print('CodingStandard Retrieved successfully');
            return {
              'success': true,
              'data': responseData['data'] ?? [],
              'message':
                  responseData['message'] ??
                  'CodingStandard Retrieved successfully',
            };
          } else {
            return {
              'success': false,
              'message':
                  responseData['message'] ??
                  'Failed to Retrieve CodingStandard',
            };
          }
        } catch (e) {
          print('Error parsing response: $e');
          return {'success': false, 'message': 'Error parsing response'};
        }
      } else {
        return {
          'success': false,
          'message':
              'Failed to retrieve coding standards. Status: ${response.statusCode}',
        };
      }
    } on ApiException catch (e) {
      print('API Exception: $e');
      return {'success': false, 'message': e.message};
    } catch (e) {
      print('Error in getCodingStandardList: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  static String _viewCodingStandardApiUrl({required int coding_standard_id}) {
    String url =
        '$getCodingStandardApiUrl?coding_standard_id=$coding_standard_id';
    return url;
  }

  static Future<Map<String, dynamic>?> getCodingStandardDetails({
    int coding_standard_id = 0,
  }) async {
    try {
      final url = _viewCodingStandardApiUrl(
        coding_standard_id: coding_standard_id,
      );

      print('=== CodingStandard Service ===');
      print('Making authenticated request to: $url');

      final response = await ApiClient.get(url);

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = ApiClient.parseJsonResponse(response);
        print('SUCCESS! CodingStandard data retrieved');
        print('Response Data: $responseData');
        return responseData;
      } else {
        print('HTTP Error: ${response.statusCode}');
        print('Error body: ${response.body}');
        return null;
      }
    } on ApiException catch (e) {
      print('API Exception: $e');
      return {
        'success': false,
        'error': {'code': e.errorCode ?? 'UNKNOWN', 'message': e.message},
      };
    } catch (e, stackTrace) {
      print('Exception in getNotesList: $e');
      print('Stack trace: $stackTrace');
      return null;
    }
  }
}

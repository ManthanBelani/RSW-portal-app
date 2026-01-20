import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'auth_service.dart';
import 'header_service.dart';

class FillHoursService {
  static String get _apiUrl {
    final baseUrl =
        dotenv.env['BASE_URL'] ??
        'https://rainflowweb.com/demo/account-upgrade/api';
    return '$baseUrl/dashboard/fill_hours.php?start=2024-01-01&end=2024-12-31';
  }

  static Future<Map<String, dynamic>?> getFillHoursData() async {
    try {
      print('=== Fill Hours Service ===');
      print('Making authenticated request to: $_apiUrl');
      final header = await HeadersService.getAuthHeaders();
      final response = await AuthService.makeAuthenticatedGet(
        _apiUrl,
        extraHeaders: header,
      );

      print('Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        try {
          final Map<String, dynamic> responseData = json.decode(response.body);
          print('SUCCESS! Fill hours data retrieved');
          return responseData;
        } catch (jsonError) {
          print('JSON Parse Error: $jsonError');
          print('Raw response body: ${response.body}');
          return null;
        }
      } else if (response.statusCode == 401) {
        print('Authentication failed - session may have expired');
        print('Response body: ${response.body}');
        // Clear expired session
        await AuthService.clearToken();
        return {
          'success': false,
          'error': {
            'code': 'UNAUTHORIZED',
            'message': 'Session expired. Please login again.',
          },
        };
      } else {
        print('HTTP Error: ${response.statusCode}');
        print('Error body: ${response.body}');
        return null;
      }
    } catch (e, stackTrace) {
      print('Exception in getFillHoursData: $e');
      print('Stack trace: $stackTrace');
      return null;
    }
  }
}

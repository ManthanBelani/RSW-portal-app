import 'dart:convert';
import 'dart:math';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'auth_service.dart';
import 'header_service.dart';

class GeneralCalendarService {
  static Future<Map<String, dynamic>?> getGeneralCalendarData() async {
    final baseUrl =
    dotenv.env['BASE_URL'];
    final generalCalenderApiUrl = '$baseUrl/dashboard/calendar.php';
    try {
      print('=== General Calendar Service ===');
      print('Making authenticated request to: $generalCalenderApiUrl');
      final header = await HeadersService.getAuthHeaders();
      final response = await AuthService.makeAuthenticatedGet(generalCalenderApiUrl,extraHeaders: header);

      print('Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        try {
          final Map<String, dynamic> responseData = json.decode(response.body);
          print('Response data: $responseData');
          print('SUCCESS! Calendar data retrieved');
          return responseData;
        } catch (jsonError) {
          print('JSON Parse Error: $jsonError');
          print('Raw response body: ${response.body}');
          return null;
        }
      } else if (response.statusCode == 401) {
        print('Authentication failed - session may have expired');
        print('Response body: ${response.body}');
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
      print('Exception in getGeneralCalendarData: $e');
      print('Stack trace: $stackTrace');
      return null;
    }
  }
}

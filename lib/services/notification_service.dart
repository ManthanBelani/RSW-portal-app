import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'api_client.dart';

class NotificationService {
  static Future<Map<String, dynamic>?> getNotificationData() async {
    final baseUrl = dotenv.env['BASE_URL'];
    final generalCalenderApiUrl = '$baseUrl/hr_management/get_notifications.php';
    
    try {
      print('=== Notification Service ===');
      print('Making authenticated request to: $generalCalenderApiUrl');
      
      // Use ApiClient for authenticated request
      final response = await ApiClient.get(generalCalenderApiUrl);

      print('Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = ApiClient.parseJsonResponse(response);
        print('Response data: $responseData');
        print('SUCCESS! Notification data retrieved');
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
        'error': {
          'code': e.errorCode ?? 'UNKNOWN',
          'message': e.message,
        },
      };
    } catch (e, stackTrace) {
      print('Exception in getNotificationData: $e');
      print('Stack trace: $stackTrace');
      return null;
    }
  }
}

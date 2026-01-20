  import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'api_client.dart';

class DashboardSmallContainerService {
  static String get _apiUrl {
    final baseUrl = dotenv.env['BASE_URL'] ?? 'https://rainflowweb.com/demo/account-upgrade/api';
    return '$baseUrl/dashboard/card.php';
  }

  static Future<Map<String, dynamic>?> getDashboardCardData() async {
    try {
      print('=== Dashboard Card Service ===');

      // Use ApiClient for authenticated request
      final response = await ApiClient.get(_apiUrl);

      if (response.statusCode == 200) {
        final responseData = ApiClient.parseJsonResponse(response);
        print('SUCCESS! Dashboard data retrieved');
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
      print('Exception in getDashboardCardData: $e');
      print('Stack trace: $stackTrace');
      return null;
    }
  }
}

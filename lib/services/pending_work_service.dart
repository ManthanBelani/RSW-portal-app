import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'api_client.dart';

class PendingWorkService {
  static String get _apiUrl {
    final baseUrl =
        dotenv.env['BASE_URL'] ??
            'https://rainflowweb.com/demo/account-upgrade/api';
    return '$baseUrl/dashboard/pending_work.php';
  }

  static Future<Map<String, dynamic>?> getPendingInvoiceData() async {
    try {
      print('=== Pending Work Service ===');
      print('Making authenticated request to: $_apiUrl');
      
      // Use ApiClient for authenticated request
      final response = await ApiClient.get(_apiUrl);

      print('Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = ApiClient.parseJsonResponse(response);
        print('SUCCESS! Pending work data retrieved');
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
      print('Exception in getPendingInvoiceData: $e');
      print('Stack trace: $stackTrace');
      return null;
    }
  }
}

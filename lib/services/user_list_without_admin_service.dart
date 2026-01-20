import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'api_client.dart';

class UserListWithoutAdminService {
  static final baseUrl = dotenv.env['BASE_URL'];
  static final userListApiUrl = '$baseUrl/utils/user_list_withoutadmin.php';

  static Future<Map<String, dynamic>?> getUserList() async {
    try {
      print('=== Get User List Without Admin API Call ===');
      print('URL: $userListApiUrl');

      final response = await ApiClient.get(userListApiUrl);

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = ApiClient.parseJsonResponse(response);
        print('SUCCESS! User list retrieved');
        return responseData;
      } else {
        print('HTTP Error: ${response.statusCode}');
        return null;
      }
    } on ApiException catch (e) {
      print('API Exception: $e');
      return {
        'success': false,
        'error': {'code': e.errorCode ?? 'UNKNOWN', 'message': e.message},
      };
    } catch (e, stackTrace) {
      print('Exception in getUserList: $e');
      print('Stack trace: $stackTrace');
      return null;
    }
  }
}

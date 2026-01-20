import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'api_client.dart';

class ProjectListUserService {
  static final baseUrl = dotenv.env['BASE_URL'];
  static final projectlistApiUrl = '$baseUrl/utils/project_list_user.php';

  static Future<Map<String, dynamic>?> getProjectList() async {
    try {
      final response = await ApiClient.get(projectlistApiUrl);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = ApiClient.parseJsonResponse(response);
        print('Project List Fetch Successfully: $data');
        return data;
      } else {
        print('Failed to fetch project list. Status: ${response.statusCode}');
        return {'success': false, 'message': 'Failed to Fetch Project Data'};
      }
    } on ApiException catch (e) {
      print('API Exception: $e');
      return {'success': false, 'message': e.message};
    } catch (e) {
      print('Error fetching project list: $e');
      return {'success': false, 'message': e.toString()};
    }
  }
}

class UserListWithOutAdminService {
  static final baseUrl = dotenv.env['BASE_URL'];
  static final usersWithOutAdminApiUrl =
      '$baseUrl/utils/user_list_withoutadmin.php';

  static Future<Map<String, dynamic>?> getUserListWithOutAdmin() async {
    try {
      final response = await ApiClient.get(usersWithOutAdminApiUrl);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = ApiClient.parseJsonResponse(response);
        print('User List Fetch Successfully: $data');
        return data;
      } else {
        print('Failed to fetch user list. Status: ${response.statusCode}');
        return {'success': false, 'message': 'Failed to Fetch User Data'};
      }
    } on ApiException catch (e) {
      print('API Exception: $e');
      return {'success': false, 'message': e.message};
    } catch (e) {
      print('Error fetching user list: $e');
      return {'success': false, 'message': e.toString()};
    }
  }
}

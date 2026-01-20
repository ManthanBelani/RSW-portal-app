import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'api_client.dart';

class TeamDataService {
  final baseUrl = dotenv.env['BASE_URL'];
  late final projectMemberApiUrl =
      '$baseUrl/hr_management/userprojectresources.php';

  Future<Map<String, dynamic>?> getProjectMemberData() async {
    try {
      print('=== Project Member Details Service ===');
      print('Making authenticated request to: $projectMemberApiUrl');

      final response = await ApiClient.get(projectMemberApiUrl);

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = ApiClient.parseJsonResponse(response);
        print('SUCCESS! project member details retrieved');
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
      print('Exception in getDetailsNotesList: $e');
      print('Stack trace: $stackTrace');
      return null;
    }
  }
}

import 'dart:convert';
import 'package:dashboard_clone/services/api_client.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ResourceManagmentService {
  final baseUrl = dotenv.env['BASE_URL'];
  late final HRListAPiUrl =
      '$baseUrl/hr_management/humanresource_list.php?column=0&page_count=1&per_page=50&direction=asc&search=&type=';
  late final teamLeaderListApiUrl =
      '$baseUrl/hr_management/teamleader_list.php';
  late final projectManagerListApiUrl =
      '$baseUrl//hr_management/projectmanager_list.php';
  late final addHRinvolvementApiUrl = '$baseUrl/hr_management/humanresource_addinvolvement.php';

  Future<Map<String, dynamic>?> getClientList() async {
    try {
      final response = await ApiClient.get(HRListAPiUrl);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'message': 'Human Resource List fetched successfully',
          'data': data['data'] ?? data,
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to fetch Human Resource list',
        };
      }
    } on ApiException catch (e) {
      return {'success': false, 'message': e.message};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>?> getTeamLeaderList() async {
    try {
      final response = await ApiClient.get(teamLeaderListApiUrl);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'message': 'Team Leader list fetched successfully',
          'data': data['data'] ?? data,
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to fetch Team Leader list',
        };
      }
    } on ApiException catch (e) {
      return {'success': false, 'message': e.message};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>?> getProjectManagerList() async {
    try {
      final response = await ApiClient.get(projectManagerListApiUrl);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'message': 'Project manager list fetched successfully',
          'data': data['data'] ?? data,
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to fetch Project Manager list',
        };
      }
    } on ApiException catch (e) {
      return {'success': false, 'message': e.message};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
}

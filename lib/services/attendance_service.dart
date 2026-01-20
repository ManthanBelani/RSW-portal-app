import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'api_client.dart';

class AttendanceService {
  static String get _baseUrl {
    return dotenv.env['BASE_URL'] ?? 'https://rainflowweb.com/demo/account-upgrade/api';
  }
  
  static Future<Map<String, dynamic>?> fetchAttendanceData({
    String? startDate,
    String? endDate,
  }) async {
    try {
      String url = '$_baseUrl/attendance/attendance_list.php';

      final response = await ApiClient.get(url);

      if (response.statusCode == 200) {
        final json = ApiClient.parseJsonResponse(response);
        return json;
      } else {
        throw Exception('Failed to load attendance data: ${response.statusCode}');
      }
    } on ApiException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Error fetching attendance data: $e');
    }
  }


}
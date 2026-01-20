import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'api_client.dart';

class TaskService {
  static final baseUrl = dotenv.env['BASE_URL'];
  static final taskListApiUrl = '$baseUrl/task/list_task.php';

  static Future<Map<String, dynamic>?> getTaskList({
    String? startDate,
    String? endDate,
    String? projectId,
    String? userId,
    String? active,
    String? billable,
    String? paid,
    String? search,
    int? perPage,
  }) async {
    try {
      Map<String, String> queryParams = {
        'column': '5',
        'direction': 'asc',
        'search': search ?? '',
        'per_page': perPage?.toString() ?? '50',
        'page_count': '1',
      };

      // Add optional parameters only if they have values
      if (projectId != null && projectId.isNotEmpty) {
        queryParams['projectId'] = projectId;
      }
      if (paid != null && paid.isNotEmpty) {
        queryParams['pay'] = paid;
      }
      if (billable != null && billable.isNotEmpty) {
        queryParams['bill'] = billable;
      }
      if (userId != null && userId.isNotEmpty) {
        queryParams['userId'] = userId;
      }
      if (active != null && active.isNotEmpty) {
        queryParams['active'] = active;
      }
      if (startDate != null && startDate.isNotEmpty) {
        queryParams['taskdatefrom'] = startDate;
      }
      if (endDate != null && endDate.isNotEmpty) {
        queryParams['taskdateto'] = endDate;
      }

      // Build URL with query parameters - URL encode values
      String url =
          '$taskListApiUrl?${queryParams.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&')}';

      print('=== Task List API Call ===');
      print('URL: $url');
      print(
        'Filters: startDate=$startDate, endDate=$endDate, projectId=$projectId, userId=$userId, active=$active, billable=$billable, paid=$paid',
      );

      // Use ApiClient for authenticated request
      final response = await ApiClient.get(url);

      if (response.statusCode == 200) {
        final data = ApiClient.parseJsonResponse(response);
        print('Task List Response: $data');
        return data;
      } else {
        print('Failed to fetch task list. Status: ${response.statusCode}');
        print('Response body: ${response.body}');
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
    } catch (e) {
      print('Error fetching task list: $e');
      return null;
    }
  }
}

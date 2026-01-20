import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'api_client.dart';

class LeaveRequestService {
  static String get _apiUrl {
    final baseUrl =
        dotenv.env['BASE_URL'] ??
            'https://rainflowweb.com/demo/account-upgrade/api';
    return '$baseUrl/dashboard/leave_request.php';
  }
  static String _getMainPageUrl({
    String direction = 'desc',
    String column = '2',
    int perPage = 50,
    int pageCount = 1,
    String search = '',
    String? userId,
    String? fromDate,
    String? toDate,
  }) {
    final baseUrl = dotenv.env['BASE_URL'] ?? 'https://rainflowweb.com/demo/account-upgrade/api';
    String url = '$baseUrl/leave_request/list_leave.php?direction=$direction&column=$column&per_page=$perPage&page_count=$pageCount&search=$search';

    if (userId != null && userId.isNotEmpty) {
      url += '&user_id=$userId';
    }

    if (fromDate != null && fromDate.isNotEmpty) {
      url += '&startDate=$fromDate';
    }

    if (toDate != null && toDate.isNotEmpty) {
      url += '&endDate=$toDate';
    }

    return url;
  }

  static Future<Map<String, dynamic>?> getLeaveRequestDashboardData() async {
    try {
      print('=== Leave Request Service ===');
      print('Making authenticated request to: $_apiUrl');

      final response = await ApiClient.get(_apiUrl);

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = ApiClient.parseJsonResponse(response);
        print('SUCCESS! Leave request data retrieved');
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
        'error': {
          'code': e.errorCode ?? 'UNKNOWN',
          'message': e.message,
        },
      };
    } catch (e, stackTrace) {
      print('Exception in getLeaveRequestData: $e');
      print('Stack trace: $stackTrace');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getLeaveRequestMainPageData({
    String direction = 'desc',
    String column = '2',
    int perPage = 50,
    int pageCount = 1,
    String search = '',
    String? userId,
    String? fromDate,
    String? toDate,
  }) async {
    try {
      final url = _getMainPageUrl(
        direction: direction,
        column: column,
        perPage: perPage,
        pageCount: pageCount,
        search: search,
        userId: userId,
        fromDate: fromDate,
        toDate: toDate,
      );

      print('=== Leave Request Service ===');
      print('Making authenticated request to: $url');

      final response = await ApiClient.get(url);

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = ApiClient.parseJsonResponse(response);
        print('SUCCESS! Leave request data retrieved on leave request page');
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
        'error': {
          'code': e.errorCode ?? 'UNKNOWN',
          'message': e.message,
        },
      };
    } catch (e, stackTrace) {
      print('Exception in getLeaveRequestDataOnMainPage: $e');
      print('Stack trace: $stackTrace');
      return null;
    }
  }

}

import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'api_client.dart';

class ActivityService {
  static final baseUrl = dotenv.env['BASE_URL'];
  static final getActivitiesApiUrl =
      '$baseUrl/device_activity/user_device_info.php';
  static final deleteActivitiesApiUrl =
      '$baseUrl/device_activity/remove_device.php';
  static final notificationActivitiesApiUrl =
      '$baseUrl/device_activity/enable_notification.php';

  static String _getActivitiesListUrl({
    String direction = 'desc',
    String column = '0',
    int perPage = 50,
    int pageCount = 1,
    String search = '',
  }) {
    final baseUrl = dotenv.env['BASE_URL'];
    String url =
        '$baseUrl/device_activity/get_devices.php?direction=$direction&column=$column&per_page=$perPage&page_count=$pageCount&search=$search';

    return url;
  }

  static String _downloadLogOfActivitiesListUrl({required String action}) {
    final baseUrl = dotenv.env['BASE_URL'];
    String url = '$baseUrl/device_activity/log_file.php?action=$action';
    return url;
  }

  static Future<Map<String, dynamic>?> getActivitiesList({
    String direction = 'desc',
    String column = '0',
    int perPage = 50,
    int pageCount = 1,
    String search = '',
  }) async {
    try {
      final url = _getActivitiesListUrl(
        direction: direction,
        column: column,
        perPage: perPage,
        pageCount: pageCount,
        search: search,
      );

      print('=== Activity Service ===');
      print('Making authenticated request to: $url');

      final response = await ApiClient.get(url);

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = ApiClient.parseJsonResponse(response);
        print('SUCCESS! activity data retrieved');
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
      print('Exception in getNotesList: $e');
      print('Stack trace: $stackTrace');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> removeDevice(String id) async {
    try {
      final Map<String, String> deleteActivityId = {'device_id': id};

      print('=== remove Device API Call ===');
      print('URL: $deleteActivitiesApiUrl');
      print('Task ID: $id');

      final response = await ApiClient.post(
        deleteActivitiesApiUrl,
        deleteActivityId,
        isFormData: true,
      );

      print('device removed Response Status: ${response.statusCode}');
      print('device removed Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final responseData = json.decode(response.body);
          if (responseData['success'] == true) {
            print('remove device Successfully');
            return {
              'success': true,
              'message':
                  responseData['message'] ?? 'device removed successfully',
            };
          } else {
            return {
              'success': false,
              'message': responseData['message'] ?? 'Failed to remove device',
            };
          }
        } catch (e) {
          print('device removed Successfully (non-JSON response)');
          return {'success': true, 'message': 'device removed successfully'};
        }
      } else {
        return {
          'success': false,
          'message': 'Failed to remove device. Status: ${response.statusCode}',
        };
      }
    } on ApiException catch (e) {
      print('API Exception: $e');
      return {'success': false, 'message': e.message};
    } catch (e) {
      print('Error deleting task: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>?> enableNotificationOfDevice(
    String id,
    int is_notification_enable,
  ) async {
    try {
      final Map<String, dynamic> notificationData = {
        'device_id': id,
        'is_notification_enable': is_notification_enable,
      };

      print('=== Enable Notification API Call ===');
      print('URL: $notificationActivitiesApiUrl');
      print('Device ID: $id');
      print('Notification Status: $is_notification_enable');

      final response = await ApiClient.post(
        notificationActivitiesApiUrl,
        notificationData,
        isFormData: true,
      );

      print('Notification Response Status: ${response.statusCode}');
      print('Notification Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final responseData = json.decode(response.body);
          if (responseData['success'] == true) {
            print('Notification updated successfully');
            return {
              'success': true,
              'message':
                  responseData['message'] ??
                  'Notification updated successfully',
            };
          } else {
            return {
              'success': false,
              'message':
                  responseData['message'] ?? 'Failed to update notification',
            };
          }
        } catch (e) {
          print('Notification updated successfully (non-JSON response)');
          return {
            'success': true,
            'message': 'Notification updated successfully',
          };
        }
      } else {
        return {
          'success': false,
          'message':
              'Failed to update notification. Status: ${response.statusCode}',
        };
      }
    } on ApiException catch (e) {
      print('API Exception: $e');
      return {'success': false, 'message': e.message};
    } catch (e) {
      print('Error updating notification: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>?> downloadLogOfActivitiesList({
    required String action,
  }) async {
    try {
      final url = _downloadLogOfActivitiesListUrl(action: action);

      print('=== Activity Log Service ===');
      print('Making authenticated request to: $url');
      print('Action: $action');

      final response = await ApiClient.get(url);

      print('Response Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        // Check if response is JSON or file download
        final contentType = response.headers['content-type'] ?? '';
        
        if (contentType.contains('application/json')) {
          // JSON response
          final responseData = ApiClient.parseJsonResponse(response);
          print('SUCCESS! Log action completed');
          print('Response Data: $responseData');
          return responseData;
        } else {
          // File download response
          print('SUCCESS! File download initiated');
          print('Content-Type: $contentType');
          print('Content-Length: ${response.headers['content-length']}');
          
          return {
            'success': true,
            'message': action == 'download' 
                ? 'Log file downloaded successfully' 
                : 'Log deleted successfully',
            'isFile': true,
            'fileData': response.bodyBytes,
            'contentType': contentType,
          };
        }
      } else {
        print('HTTP Error: ${response.statusCode}');
        print('Error body: ${response.body}');
        return {
          'success': false,
          'message': 'Failed to $action log. Status: ${response.statusCode}',
        };
      }
    } on ApiException catch (e) {
      print('API Exception: $e');
      return {
        'success': false,
        'message': e.message,
      };
    } catch (e, stackTrace) {
      print('Exception in downloadLogOfActivitiesList: $e');
      print('Stack trace: $stackTrace');
      return {
        'success': false,
        'message': 'Error: ${e.toString()}',
      };
    }
  }
}

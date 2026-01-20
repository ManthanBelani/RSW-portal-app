import 'package:dashboard_clone/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'header_service.dart';

class CrudLeaveService {
  static final baseUrl = dotenv.env['BASE_URL'];
  static final leaveApproveApiUrl = '$baseUrl/leave_request/approve_leave.php';
  static final leaveRejectApiUrl = '$baseUrl/leave_request/reject_leave.php';
  static final leaveDeleteApiUrl = '$baseUrl/leave_request/delete_leave.php';
  static final leaveAddApiUrl = '$baseUrl/leave_request/add_leave.php';

  static Future<Map<String, dynamic>?> approveUserLeave({
    required BuildContext context,
    required String fromdate,
    required String todate,
    required String id,
    required String userId,
    required String leaveday,
  }) async {
    try {
      final header = await HeadersService.getAuthHeaders();
      final Map<String, String> leaveDataToApprove = {
        'fromdate': fromdate,
        'todate': todate,
        'id': id,
        'user_id': userId,
        'leaveday': leaveday,
      };
      final response = await AuthService.makeAuthenticatedPost(
        leaveApproveApiUrl,
        leaveDataToApprove,
        extraHeaders: header,
        isFormData: true,
      );

      if (!context.mounted) return null;

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('Leave Approved Successfully');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Leave Approved Successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        return {'success': true, 'message': 'Leave approved successfully'};
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to approve leave'),
            backgroundColor: Colors.red,
          ),
        );
        return {'success': false, 'message': 'Failed to approve leave'};
      }
    } catch (e) {
      print(e);
      if (!context.mounted) return null;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>?> addUserLeave({
    required BuildContext context,
    required String user_name,
    required String user_id,
    required String leave_type,
    required String leaveday,
    required String leaveday1,
    required String startdate,
    required String enddate,
    required String leavereason,
  }) async {
    try {
      final header = await HeadersService.getAuthHeaders();
      final Map<String, String> leaveDataToApprove = {
        'user_name': user_name,
        'user_id': user_id,
        'leave_type': leave_type,
        'leaveday': leaveday,
        'leaveday1': leaveday1,
        'startdate': startdate,
        'enddate': enddate,
        'leavereason': leavereason,
      };
      final response = await AuthService.makeAuthenticatedPost(
        leaveAddApiUrl,
        leaveDataToApprove,
        extraHeaders: header,
        isFormData: true,
      );

      if (!context.mounted) return null;

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('Leave Approved Successfully');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Leave Approved Successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        return {'success': true, 'message': 'Leave approved successfully'};
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to approve leave'),
            backgroundColor: Colors.red,
          ),
        );
        return {'success': false, 'message': 'Failed to approve leave'};
      }
    } catch (e) {
      print(e);
      if (!context.mounted) return null;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>?> rejectUserLeave({
    required BuildContext context,
    required String fromdate,
    required String todate,
    required String id,
    required String userId,
    required String leaveday,
  }) async {
    try {
      final header = await HeadersService.getAuthHeaders();
      final Map<String, String> leaveDataToApprove = {
        'fromdate': fromdate,
        'todate': todate,
        'id': id,
        'user_id': userId,
        'leaveday': leaveday,
      };
      final response = await AuthService.makeAuthenticatedPost(
        leaveRejectApiUrl,
        leaveDataToApprove,
        extraHeaders: header,
        isFormData: true,
      );

      if (!context.mounted) return null;

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('Leave Rejected Successfully');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Leave Rejected Successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        return {'success': true, 'message': 'Leave Rejected successfully'};
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to Rejected leave'),
            backgroundColor: Colors.red,
          ),
        );
        return {'success': false, 'message': 'Failed to Rejected leave'};
      }
    } catch (e) {
      print(e);
      if (!context.mounted) return null;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>?> deleteUserLeave({
    required BuildContext context,
    required String id,
  }) async {
    try {
      final header = await HeadersService.getAuthHeaders();
      final Map<String, String> leaveDataToApprove = {'id': id};
      final response = await AuthService.makeAuthenticatedPost(
        leaveDeleteApiUrl,
        leaveDataToApprove,
        extraHeaders: header,
        isFormData: true,
      );

      if (!context.mounted) return null;

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('Leave Deleted Successfully');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Leave Deleted Successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        return {'success': true, 'message': 'Leave Deleted successfully'};
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to Rejected leave'),
            backgroundColor: Colors.red,
          ),
        );
        return {'success': false, 'message': 'Failed to Rejected leave'};
      }
    } catch (e) {
      print(e);
      if (!context.mounted) return null;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
      return {'success': false, 'message': e.toString()};
    }
  }
}

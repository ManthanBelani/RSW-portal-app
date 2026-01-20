import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'api_client.dart';

class CRUDForTask {
  static final baseUrl = dotenv.env['BASE_URL'];
  static final listTaskApiUrl =
      '$baseUrl/task/list_task.php?column=0&direction=desc&search=,&per_page=50&page_count=1';
  static final totalHourApiUrl = '$baseUrl/task/total_time.php';
  static final deleteTaskApiUrl = '$baseUrl/task/delete_task.php';
  static final updateTaskApiUrl = '$baseUrl/task/update_task.php';
  static final addTaskApiUrl = '$baseUrl/task/add_task.php';

  static Future<Map<String, dynamic>?> getListTask() async {
    try {
      final response = await ApiClient.get(listTaskApiUrl);

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('Task Data Fetch Successfully');
        return {'success': true, 'message': 'Task Data Fetch successfully'};
      } else {
        return {'success': false, 'message': 'Failed to Fetch Task Data '};
      }
    } on ApiException catch (e) {
      print('API Exception: $e');
      return {'success': false, 'message': e.message};
    } catch (e) {
      print(e);
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>?> getTotalTime() async {
    try {
      final response = await ApiClient.get(totalHourApiUrl);

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('Task Data Fetch Successfully');
        return {'success': true, 'message': 'Task Data Fetch successfully'};
      } else {
        return {'success': false, 'message': 'Failed to Fetch Task Data '};
      }
    } on ApiException catch (e) {
      print('API Exception: $e');
      return {'success': false, 'message': e.message};
    } catch (e) {
      print(e);
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>?> deleteTask(String id) async {
    try {
      final Map<String, String> deleteTaskId = {'id': id};

      print('=== Delete Task API Call ===');
      print('URL: $deleteTaskApiUrl');
      print('Task ID: $id');

      final response = await ApiClient.post(
        deleteTaskApiUrl,
        deleteTaskId,
        isFormData: true,
      );

      print('Delete Response Status: ${response.statusCode}');
      print('Delete Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Try to parse the response to check actual success
        try {
          final responseData = json.decode(response.body);
          if (responseData['success'] == true) {
            print('Task deleted Successfully');
            return {
              'success': true,
              'message': responseData['message'] ?? 'Task deleted successfully',
            };
          } else {
            return {
              'success': false,
              'message': responseData['message'] ?? 'Failed to delete task',
            };
          }
        } catch (e) {
          // If response is not JSON, assume success based on status code
          print('Task deleted Successfully (non-JSON response)');
          return {'success': true, 'message': 'Task deleted successfully'};
        }
      } else {
        return {
          'success': false,
          'message': 'Failed to delete task. Status: ${response.statusCode}',
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

  static Future<Map<String, dynamic>?> updateTask(
    String id,
    String project_id,
    String date,
    String hours,
    String other,
    String note,
    String ticketnumber,
    String bill,
    String active,
    String task_id,
    String user_id,
    // String team_id,
  ) async {
    try {
      final Map<String, String> updateTaskData = {
        'id': id,
        'project_id': project_id,
        'date': date,
        'hours': hours,
        'other': other,
        'note': note,
        'ticketnumber': ticketnumber,
        'bill': bill,
        'active': active,
        'task_id': id,
        'user_id': user_id,
      };

      // // Only add team_id if it's not empty
      // if (team_id.isNotEmpty) {
      //   updateTaskData['team_id'] = team_id;
      // }

      print('=== Update Task API Call ===');
      print('URL: $updateTaskApiUrl');
      print('Data: $updateTaskData');
      // print('Team ID provided: ${team_id.isNotEmpty ? team_id : "EMPTY - not included in request"}');

      final response = await ApiClient.post(
        updateTaskApiUrl,
        updateTaskData,
        isFormData: true,
      );

      print('Update Response Status: ${response.statusCode}');
      print('Update Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final responseData = json.decode(response.body);
          if (responseData['success'] == true) {
            print('Task Updated Successfully');
            return {
              'success': true,
              'message': responseData['message'] ?? 'Task updated successfully',
            };
          } else {
            return {
              'success': false,
              'message': responseData['message'] ?? 'Failed to update task',
            };
          }
        } catch (e) {
          print('Task Updated Successfully (non-JSON response)');
          return {'success': true, 'message': 'Task updated successfully'};
        }
      } else {
        try {
          final responseData = json.decode(response.body);
          return {
            'success': false,
            'message':
                responseData['error']?['message'] ?? 'Failed to update task',
          };
        } catch (e) {
          return {
            'success': false,
            'message': 'Failed to update task. Status: ${response.statusCode}',
          };
        }
      }
    } on ApiException catch (e) {
      print('API Exception: $e');
      return {'success': false, 'message': e.message};
    } catch (e) {
      print('Error updating task: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>?> addTask(
    String userId,
    List<Map<String, dynamic>> tasksData,
  ) async {
    try {
      // Prepare form data format similar to update task
      final Map<String, String> formData = {
        'user_id': userId,
        'data': json.encode(tasksData),
      };

      print('=== Add Task API Call ===');
      print('URL: $addTaskApiUrl');
      print('User ID: $userId');
      print('Tasks Data: ${json.encode(tasksData)}');
      print('Form Data: $formData');

      final response = await ApiClient.post(
        addTaskApiUrl,
        formData,
        isFormData: true,
      );

      print('Add Task Response Status: ${response.statusCode}');
      print('Add Task Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final responseData = json.decode(response.body);
          if (responseData['success'] == true) {
            print('Tasks Added Successfully');
            return {
              'success': true,
              'message': responseData['message'] ?? 'Tasks added successfully',
            };
          } else {
            return {
              'success': false,
              'message': responseData['message'] ?? 'Failed to add tasks',
            };
          }
        } catch (e) {
          print('Tasks Added Successfully (non-JSON response)');
          return {'success': true, 'message': 'Tasks added successfully'};
        }
      } else {
        try {
          final responseData = json.decode(response.body);
          return {
            'success': false,
            'message':
                responseData['error']?['message'] ??
                responseData['message'] ??
                'Failed to add tasks',
          };
        } catch (e) {
          return {
            'success': false,
            'message': 'Failed to add tasks. Status: ${response.statusCode}',
          };
        }
      }
    } on ApiException catch (e) {
      print('API Exception: $e');
      return {'success': false, 'message': e.message};
    } catch (e) {
      print('Error adding tasks: $e');
      return {'success': false, 'message': e.toString()};
    }
  }
}

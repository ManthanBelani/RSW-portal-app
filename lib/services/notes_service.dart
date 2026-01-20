import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'api_client.dart';
import 'header_service.dart';

class NotesService {
  static final baseUrl = dotenv.env['BASE_URL'];
  static final createNotesApiUrl = '$baseUrl/notes/create_note.php';
  static final updateNotesApiUrl = '$baseUrl/notes/update_note.php';
  static final deleteNotesApiUrl = '$baseUrl/notes/delete_note.php';
  static final logOfNotesApiUrl = '$baseUrl/notes/notes_log_details.php';
  static final removeUsersNotesApiUrl = '$baseUrl/notes/flush_note.php';
  static final detailNotesApiUrl = '$baseUrl/notes/detail_note.php?noteid=';
  static final userListApiUrl = '$baseUrl/utils/user_list_withoutadmin.php';
  static final addAccessApiUrl = '$baseUrl/notes/add_access.php';

  static String _getNotesListUrl({
    String direction = 'desc',
    String column = '0',
    int perPage = 50,
    int pageCount = 1,
    String search = '',
  }) {
    final baseUrl =
        dotenv.env['BASE_URL'] ??
        'https://rainflowweb.com/demo/account-upgrade/api';
    String url =
        '$baseUrl/notes/list_note.php?direction=$direction&column=$column&per_page=$perPage&page_count=$pageCount&search=$search';

    return url;
  }

  static Future<Map<String, dynamic>?> getNotesList({
    String direction = 'desc',
    String column = '0',
    int perPage = 50,
    int pageCount = 1,
    String search = '',
  }) async {
    try {
      final url = _getNotesListUrl(
        direction: direction,
        column: column,
        perPage: perPage,
        pageCount: pageCount,
        search: search,
      );

      print('=== Notes Service ===');
      print('Making authenticated request to: $url');

      final response = await ApiClient.get(url);

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = ApiClient.parseJsonResponse(response);
        print('SUCCESS! Notes data retrieved');
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

  static Future<Map<String, dynamic>?> getDetailsNotesList({
    required String noteId,
  }) async {
    try {
      final url = '$detailNotesApiUrl$noteId';

      print('=== Notes Details Service ===');
      print('Making authenticated request to: $url');

      final response = await ApiClient.get(url);

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = ApiClient.parseJsonResponse(response);
        print('SUCCESS! Note details retrieved');
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

  //delete Note
  static Future<Map<String, dynamic>?> deleteNotes(String id) async {
    try {
      final Map<String, String> deleteNoteId = {'id': id};

      print('=== Delete Notes API Call ===');
      print('URL: $detailNotesApiUrl');
      print('Task ID: $id');

      final response = await ApiClient.post(
        deleteNotesApiUrl,
        deleteNoteId,
        isFormData: true,
      );

      print('Delete Response Status: ${response.statusCode}');
      print('Delete Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final responseData = json.decode(response.body);
          if (responseData['success'] == true) {
            print('Note deleted Successfully');
            return {
              'success': true,
              'message': responseData['message'] ?? 'Note deleted successfully',
            };
          } else {
            return {
              'success': false,
              'message': responseData['message'] ?? 'Failed to delete note',
            };
          }
        } catch (e) {
          print('Note deleted Successfully (non-JSON response)');
          return {'success': true, 'message': 'Note deleted successfully'};
        }
      } else {
        return {
          'success': false,
          'message': 'Failed to delete Note. Status: ${response.statusCode}',
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


  //log of Notes
  static Future<Map<String, dynamic>?> getLogOfNotes(String id) async {
    try {
      final Map<String, String> NoteId = {'id': id};

      print('=== Get Notes Log API Call ===');
      print('URL: $logOfNotesApiUrl');
      print('Note ID: $id');

      final response = await ApiClient.post(
        logOfNotesApiUrl,
        NoteId,
        isFormData: true,
      );

      print('Log of Note Response Status: ${response.statusCode}');
      print('Log of Note Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final responseData = json.decode(response.body);
          if (responseData['success'] == true) {
            print('Log of Note retrieved Successfully');
            return {
              'success': true,
              'message':
                  responseData['message'] ??
                  'Log of Note retrieved successfully',
              'data': responseData['data'] ?? [],
            };
          } else {
            return {
              'success': false,
              'message':
                  responseData['message'] ?? 'Failed to retrieve Log of Note',
            };
          }
        } catch (e) {
          print('Error parsing log response: $e');
          return {
            'success': false,
            'message': 'Error parsing log response',
          };
        }
      } else {
        return {
          'success': false,
          'message':
              'Failed to retrieve Log Note. Status: ${response.statusCode}',
        };
      }
    } on ApiException catch (e) {
      print('API Exception: $e');
      return {'success': false, 'message': e.message};
    } catch (e) {
      print('Error getting note log: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  // remove specific user from note
  static Future<Map<String, dynamic>?> removeSpecificUserFromNote({
    required String noteId,
    required String userId,
  }) async {
    try {
      final Map<String, String> removeUserData = {
        'note_id': noteId,
        'user_id': userId,
      };

      print('=== Remove Specific User from Note API Call ===');
      print('URL: $baseUrl/notes/remove_access.php');
      print('Note ID: $noteId');
      print('User ID: $userId');

      final response = await ApiClient.post(
        '$baseUrl/notes/remove_access.php',
        removeUserData,
        isFormData: true,
      );

      print('Remove User Response Status: ${response.statusCode}');
      print('Remove User Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final responseData = json.decode(response.body);
          if (responseData['success'] == true) {
            print('User removed Successfully');
            return {
              'success': true,
              'message': responseData['message'] ?? 'User removed successfully',
            };
          } else {
            return {
              'success': false,
              'message': responseData['message'] ?? 'Failed to remove user',
            };
          }
        } catch (e) {
          print('User removed Successfully (non-JSON response)');
          return {'success': true, 'message': 'User removed successfully'};
        }
      } else {
        return {
          'success': false,
          'message': 'Failed to remove user. Status: ${response.statusCode}',
        };
      }
    } on ApiException catch (e) {
      print('API Exception: $e');
      return {'success': false, 'message': e.message};
    } catch (e) {
      print('Error removing user: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  // remove all user
  static Future<Map<String, dynamic>?> removeUsersNotes(String id) async {
    try {
      final Map<String, String> removeUserNoteId = {'note_id': id};

      print('=== Remove Users from Notes API Call ===');
      print('URL: $detailNotesApiUrl');
      print('Task ID: $id');

      final response = await ApiClient.post(
        removeUsersNotesApiUrl,
        removeUserNoteId,
        isFormData: true,
      );

      print('remove User Response Status: ${response.statusCode}');
      print('remove User  Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final responseData = json.decode(response.body);
          if (responseData['success'] == true) {
            print('Note deleted Successfully');
            return {
              'success': true,
              'message': responseData['message'] ?? 'User Removed successfully',
            };
          } else {
            return {
              'success': false,
              'message': responseData['message'] ?? 'Failed to remove user',
            };
          }
        } catch (e) {
          // If response is not JSON, assume success based on status code
          print('user removed  Successfully (non-JSON response)');
          return {'success': true, 'message': 'user Removed successfully'};
        }
      } else {
        return {
          'success': false,
          'message': 'Failed to remove user. Status: ${response.statusCode}',
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

  // get user list without admin
  static Future<Map<String, dynamic>?> getUserListWithoutAdmin() async {
    try {
      print('=== Get User List API Call ===');
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
    } catch (e) {
      print('Error getting user list: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  // add access to users
  static Future<Map<String, dynamic>?> addAccessToNote({
    required String noteId,
    required List<String> userIds,
  }) async {
    try {
      final Map<String, dynamic> formData = {
        'note_id': noteId,
      };

      // Add user IDs as indexed array
      for (int i = 0; i < userIds.length; i++) {
        formData['user_id[$i]'] = userIds[i];
      }

      print('=== Add Access API Call ===');
      print('URL: $addAccessApiUrl');
      print('Note ID: $noteId');
      print('User IDs: $userIds');
      print('Form Data: $formData');

      final response = await ApiClient.post(
        addAccessApiUrl,
        formData,
        isFormData: true,
      );

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final responseData = json.decode(response.body);
          if (responseData['success'] == true) {
            print('Access added successfully');
            return {
              'success': true,
              'message': responseData['message'] ?? 'Access added successfully',
            };
          } else {
            return {
              'success': false,
              'message': responseData['message'] ?? 'Failed to add access',
            };
          }
        } catch (e) {
          return {'success': true, 'message': 'Access added successfully'};
        }
      } else {
        return {
          'success': false,
          'message': 'Failed to add access. Status: ${response.statusCode}',
        };
      }
    } on ApiException catch (e) {
      print('API Exception: $e');
      return {'success': false, 'message': e.message};
    } catch (e) {
      print('Error adding access: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  //create Note
  static Future<Map<String, dynamic>?> createNote({
    required String projectId,
    required String editorHtml,
    List<PlatformFile>? attachments,
  }) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse(createNotesApiUrl));

      request.fields['project_id'] = projectId;
      request.fields['editor'] = editorHtml;

      if (attachments != null) {
        for (var file in attachments) {
          if (file.bytes != null) {
            request.files.add(
              http.MultipartFile.fromBytes(
                'attachments[]',
                file.bytes!,
                filename: file.name,
              ),
            );
          }
        }
      }
      final authHeaders = await HeadersService.getAuthHeaders();
      request.headers.addAll(authHeaders);

      print('=== Create Note Request ===');
      print('URL: $createNotesApiUrl');
      print('Project ID: $projectId');
      print('Editor HTML length: ${editorHtml.length}');
      print('Attachments count: ${attachments?.length ?? 0}');

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final responseData = json.decode(response.body);
          if (responseData['success'] == true) {
            print('Note Created Successfully');
            return {
              'success': true,
              'message': responseData['message'] ?? 'Note created successfully',
            };
          } else {
            return {
              'success': false,
              'message': responseData['message'] ?? 'Failed to create note',
            };
          }
        } catch (e) {
          print('Note Created Successfully (non-JSON response)');
          return {'success': true, 'message': 'Note created successfully'};
        }
      } else {
        try {
          final responseData = json.decode(response.body);
          return {
            'success': false,
            'message':
                responseData['error']?['message'] ??
                responseData['message'] ??
                'Failed to create note',
          };
        } catch (e) {
          return {
            'success': false,
            'message': 'Failed to create note. Status: ${response.statusCode}',
          };
        }
      }
    } on ApiException catch (e) {
      print('API Exception: $e');
      return {'success': false, 'message': e.message};
    } catch (e) {
      print('Error creating note: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  //update notes
  static Future<Map<String, dynamic>?> updateNote({
    required String noteId,
    required String projectId,
    required String editorHtml,
    List<PlatformFile>? attachments,
  }) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse(updateNotesApiUrl));

      request.fields['id'] = noteId;
      request.fields['project_id'] = projectId;
      request.fields['editor1'] = editorHtml;

      if (attachments != null) {
        for (var file in attachments) {
          if (file.bytes != null) {
            request.files.add(
              http.MultipartFile.fromBytes(
                'attachments[]',
                file.bytes!,
                filename: file.name,
              ),
            );
          }
        }
      }

      final authHeaders = await HeadersService.getAuthHeaders();
      request.headers.addAll(authHeaders);

      print('=== Update Note Request ===');
      print('URL: $updateNotesApiUrl');
      print('Note ID: $noteId');
      print('Project ID: $projectId');
      print('Editor HTML length: ${editorHtml.length}');
      print('Attachments count: ${attachments?.length ?? 0}');

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final responseData = json.decode(response.body);
          if (responseData['success'] == true) {
            print('Note Updated Successfully');
            return {
              'success': true,
              'message': responseData['message'] ?? 'Note Updated successfully',
            };
          } else {
            return {
              'success': false,
              'message': responseData['message'] ?? 'Failed to Update note',
            };
          }
        } catch (e) {
          print('Note Updated Successfully (non-JSON response)');
          return {'success': true, 'message': 'Note Updated successfully'};
        }
      } else {
        try {
          final responseData = json.decode(response.body);
          return {
            'success': false,
            'message':
                responseData['error']?['message'] ??
                responseData['message'] ??
                'Failed to create note',
          };
        } catch (e) {
          return {
            'success': false,
            'message': 'Failed to Update   note. Status: ${response.statusCode}',
          };
        }
      }
    } on ApiException catch (e) {
      print('API Exception: $e');
      return {'success': false, 'message': e.message};
    } catch (e) {
      print('Error creating note: $e');
      return {'success': false, 'message': e.toString()};
    }
  }
}

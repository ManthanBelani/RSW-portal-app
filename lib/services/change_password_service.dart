import 'dart:convert';
import 'dart:developer';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'auth_service.dart';

class ChangePasswordService {
  static String get _apiUrl {
    final baseUrl = dotenv.env['BASE_URL'] ?? 'https://rainflowweb.com/demo/account-upgrade/api';
    return '$baseUrl/authentication/change_user_password.php';
  }

  static Future<Map<String, dynamic>> changePassword(
    String oldPassword,
    String newPassword,
    String confirmPassword,
  ) async {
    try {
      log('=== Change Password Request ===');
      final loginToken = await AuthService.getLoginToken();
      if (loginToken == null || loginToken.isEmpty) {
        log('No login token found - user needs to login first');
        return {
          'success': false,
          'message': 'Please login first to change password',
        };
      }
      String? csrfToken = await AuthService.getToken();

      if (csrfToken == null || csrfToken.isEmpty) {
        log('No authentication token available, trying to get valid token...');
        csrfToken = await AuthService.getValidToken();
      }

      if (csrfToken == null || csrfToken.isEmpty) {
        log('No authentication token available');
        return {
          'success': false,
          'message': 'Authentication failed. Please login again.',
        };
      }

      log('Using CSRF token: $csrfToken');
      log('Using login token: $loginToken');
      log('Current session cookies: ${AuthService.getSessionCookies()}');
      log('Current stored token: ${await AuthService.getToken()}');
      log('Current token time: ${await AuthService.getTokenTime()}');

      final Map<String, String> passwordData = {
        'csrf_token': csrfToken,
        'old_password': oldPassword,
        'password': newPassword,
        'confirm_password': confirmPassword,
      };
      log('Request data: $passwordData');
      final sessionCookies = AuthService.getSessionCookies();
      final currentTokenTime = await AuthService.getTokenTime();

      log('Available session cookies: $sessionCookies');
      String currentPhpSessionId =
          'd0c02a858ae439aeafb8b2bc13dd9c86'; // From login session
      String existingLoginUserId = '1'; // From login response

      if (sessionCookies != null && sessionCookies.isNotEmpty) {
        final cookieParts = sessionCookies.split(';');
        for (final part in cookieParts) {
          final trimmedPart = part.trim();
          if (trimmedPart.startsWith('PHPSESSID=')) {
            currentPhpSessionId = trimmedPart.substring('PHPSESSID='.length);
            log('Found PHPSESSID in session cookies: $currentPhpSessionId');
          } else if (trimmedPart.startsWith('LoginUserId=')) {
            existingLoginUserId = trimmedPart.substring('LoginUserId='.length);
            log('Found LoginUserId in session cookies: $existingLoginUserId');
          }
        }
      }

      final cookieString =
          'PHPSESSID=$currentPhpSessionId; '
          'LoginUserId=$existingLoginUserId; '
          'token=$csrfToken; '
          'token_time=${currentTokenTime ?? DateTime.now().millisecondsSinceEpoch ~/ 1000}; '
          'login_token=$loginToken';

      log('Final cookie string: $cookieString');
      log('Making authenticated POST request to: $_apiUrl');
      final response = await AuthService.makeAuthenticatedPost(
        _apiUrl,
        passwordData,
        extraHeaders: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
          'Cookie': cookieString,
        },
        isFormData: true,
      );

      log('Response Status: ${response.statusCode}');
      log('Response Headers: ${response.headers}');
      log('Response Body: ${response.body}');

      // Handle response
      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final Map<String, dynamic> responseData = json.decode(response.body);

          if (responseData['success'] == true) {
            if (responseData['data'] != null &&
                responseData['data']['login_status'] != null) {
              final loginStatus = responseData['data']['login_status'];
              if (loginStatus == 'success') {
                log('Password changed successfully');
                await AuthService.clearToken();

                return {
                  'success': true,
                  'message':
                      responseData['data']['message'] ??
                      'Password changed successfully',
                };
              } else {
                log(
                  'Password change failed: ${responseData['data']['login_fail_message']}',
                );
                return {
                  'success': false,
                  'message':
                      responseData['data']['login_fail_message'] ??
                      'Failed to change password',
                };
              }
            } else {
              log('Password changed successfully');
              await AuthService.clearToken();
              return {
                'success': true,
                'message':
                    responseData['message'] ?? 'Password changed successfully',
              };
            }
          } else {
            String errorMessage = 'Failed to change password';
            if (responseData['error'] != null) {
              if (responseData['error']['message'] != null) {
                errorMessage = responseData['error']['message'];
              } else if (responseData['error'] is String) {
                errorMessage = responseData['error'];
              }
            } else if (responseData['message'] != null) {
              errorMessage = responseData['message'];
            }
            log('Password change failed: $errorMessage');
            return {'success': false, 'message': errorMessage};
          }
        } catch (jsonError) {
          log('JSON Parse Error: $jsonError');
          log('Raw response: ${response.body}');
          return {
            'success': false,
            'message': 'Invalid response from server. Please try again.',
          };
        }
      } else if (response.statusCode == 401) {
        log('Unauthorized (401) - Session expired or invalid credentials');
        String errorMessage =
            'Authentication failed. Please try logging in again.';
        try {
          final Map<String, dynamic> responseData = json.decode(response.body);
          if (responseData['error'] != null &&
              responseData['error']['message'] != null) {
            errorMessage = responseData['error']['message'];
          }
        } catch (e) {
          log('Could not parse 401 error response: $e');
        }
        return {'success': false, 'message': errorMessage};
      } else if (response.statusCode == 403) {
        log('Forbidden (403) - Access denied');
        return {
          'success': false,
          'message':
              'Access denied. Please verify your current password is correct.',
        };
      } else if (response.statusCode == 422) {
        log('Validation Error (422)');
        try {
          final Map<String, dynamic> responseData = json.decode(response.body);
          String errorMessage = responseData['message'] ?? 'Validation error';
          return {'success': false, 'message': errorMessage};
        } catch (e) {
          return {
            'success': false,
            'message': 'Validation error. Please check your input.',
          };
        }
      } else {
        log('HTTP Error: ${response.statusCode}');
        log('Response body: ${response.body}');
        return {
          'success': false,
          'message':
              'Server error (${response.statusCode}). Please try again later.',
        };
      }
    } catch (e, stackTrace) {
      log('Exception in changePassword: $e');
      log('Stack trace: $stackTrace');
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Connection')) {
        return {
          'success': false,
          'message':
              'Network connection error. Please check your internet connection.',
        };
      } else if (e.toString().contains('TimeoutException')) {
        return {
          'success': false,
          'message': 'Request timeout. Please try again.',
        };
      } else {
        return {
          'success': false,
          'message': 'An unexpected error occurred. Please try again.',
        };
      }
    }
  }
}

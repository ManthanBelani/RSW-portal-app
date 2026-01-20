import 'dart:convert';
import 'dart:developer';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'auth_service.dart';
import 'notification_helper.dart';

class LoginService {
  static String get _loginApiUrl {
    final baseUrl = dotenv.env['BASE_URL'] ?? 'https://rainflowweb.com/demo/account-upgrade/api';
    return '$baseUrl/authentication/login.php';
  }

  static Future<Map<String, dynamic>?> login(
    String email,
    String password,
  ) async {
    try {
      print('=== Starting Login Process ===');
      print('Generating fresh token for login...');
      String csrfToken = await _generateToken();
      if (csrfToken.isEmpty) {
        print('Failed to generate CSRF token');
        return {
          'success': false,
          'message': 'Failed to generate authentication token',
        };
      }

      print('CSRF Token: $csrfToken');
      print('Platform: ${kIsWeb ? "Web" : "Mobile"}');
      print('Session Cookies: ${AuthService.getSessionCookies()}');

      final Map<String, String> loginData = {
        'email': email,
        'password': password,
        'csrf_token': csrfToken,
      };

      print('Login data: $loginData');

      final response = await AuthService.makeAuthenticatedPost(
        _loginApiUrl,
        loginData,
        extraHeaders: {'Content-Type': 'application/x-www-form-urlencoded'},
        isFormData: true,
      );

      print('Login response status: ${response.statusCode}');
      log(response.body);

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData['success'] == true) {
          print('Login successful');
          print('User email: ${responseData['data']?['email'] ?? email}');

          // Store login_token from response if available
          if (responseData['data'] != null &&
              responseData['data']['login_token'] != null) {
            await AuthService.storeUserLoginToken(
              responseData['data']['login_token'],
            );
            print('Login token stored from response');
          }

          // Store username from response
          if (responseData['data'] != null &&
              responseData['data']['user'] != null &&
              responseData['data']['user']['username'] != null) {
            await AuthService.storeUsername(
              responseData['data']['user']['username'],
            );
            print('Username stored from response');
          }

          // Store user_id from response
          if (responseData['data'] != null &&
              responseData['data']['user'] != null &&
              responseData['data']['user']['id'] != null) {
            await AuthService.storeUserId(
              responseData['data']['user']['id'].toString(),
            );
            print('User ID stored from response');
          }

          await AuthService.storeTokenAfterLogin();
          
          // Store login state for persistent login
          await AuthService.setLoggedIn(true, responseData);
          
          // Show welcome notification with user's name
          if (responseData['data'] != null &&
              responseData['data']['user'] != null) {
            final user = responseData['data']['user'];
            final firstName = user['first_name'] ?? '';
            final lastName = user['last_name'] ?? '';
            
            if (firstName.isNotEmpty || lastName.isNotEmpty) {
              await NotificationHelper.showWelcomeNotification(
                firstName: firstName,
                lastName: lastName,
              );
            }
          }
          
          return responseData;
        } else {
          print(
            '❌ Login failed: ${responseData['message'] ?? 'Unknown error'}',
          );
          return responseData;
        }
      } else if (response.statusCode == 401) {
        print('Unauthorized (401) - Authentication failed');
        print('Clearing expired session data');
        await AuthService.clearToken();
        await AuthService.setLoggedIn(false);
        return {
          'success': false,
          'message':
              'Unauthorized - Invalid credentials or session expired. Please try again.',
        };
      } else {
        print('Login request failed. Status code: ${response.statusCode}');
        return {
          'success': false,
          'message': 'Login request failed with status ${response.statusCode}',
        };
      }
    } catch (e) {
      print('Error during login: $e');
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<String> _generateToken() async {
    try {
      final splashToken = AuthService.getSplashToken();
      if (splashToken != null && splashToken.isNotEmpty) {
        print('Using splash token for login: $splashToken');
        return splashToken;
      }
      print('No splash token found, generating new token...');
      final tokenData = await AuthService.generateToken();
      if (tokenData != null && tokenData['token'] != null) {
        print('New token generated: ${tokenData['token']}');
        return tokenData['token'];
      }
      return '';
    } catch (e) {
      print('Error generating token: $e');
      return '';
    }
  }
}

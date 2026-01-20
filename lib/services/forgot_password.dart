import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'auth_service.dart';
import 'web_request_handler.dart';

class ForgotPasswordService {
  static String get _apiUrl {
    final baseUrl = dotenv.env['BASE_URL'] ?? 'https://rainflowweb.com/demo/account-upgrade/api';
    return '$baseUrl/authentication/forget_password.php';
  }
  static Future<Map<String, dynamic>> forgetPassword(String email) async {
    try {
      print('Platform: ${kIsWeb ? "Web" : "Mobile"}');
      String? token = await AuthService.getValidToken();
      if (token == null) {
        print('No valid token found, generating new token...');
        try {
          final tokenData = await AuthService.generateToken();
          if (tokenData != null && tokenData['token'] != null) {
            token = tokenData['token'];
            print('New token generated for forgot password');
          }
        } catch (tokenError) {
          print('Token generation failed: $tokenError');
        }
      }

      final Map<String, String> formData = {'email': email};
      final url = _apiUrl;

      print('Sending forgot password request to: $url');
      print('Form data: $formData');

      final headers = <String, String>{
        'Content-Type': 'application/x-www-form-urlencoded',
        'Accept': 'application/json',
      };

      if (!kIsWeb) {
        final sessionCookies = AuthService.getSessionCookies();
        print('Session cookies: $sessionCookies');

        headers.addAll({
          'Accept': '*/*',
          'Accept-Encoding': 'gzip, deflate, br',
          'User-Agent': 'PostmanRuntime/7.49.0',
          'Host': Uri.parse(dotenv.env['BASE_URL'] ?? 'https://rainflowweb.com/demo/account-upgrade/api').host,
        });

        if (sessionCookies != null && sessionCookies.isNotEmpty) {
          headers['Cookie'] = sessionCookies;
          print('Mobile: Added cookies to headers');
        } else {
          print('Mobile: No session cookies available');
        }
      } else {
        print('Web: Browser will handle cookies automatically');
      }

      print('Request headers: $headers');

      final response =
          await WebRequestHandler.post(
            url,
            headers: headers,
            body: formData,
            isFormData: true,
          ).timeout(
            Duration(seconds: 30),
            onTimeout: () {
              throw Exception(
                'Request timeout: Server took too long to respond',
              );
            },
          );

      print('Forgot password response status: ${response.statusCode}');
      print('Forgot password response body: ${response.body}');
      print('Forgot password response headers: ${response.headers}');

      if (response.statusCode == 200) {
        if (response.body.isEmpty) {
          print('Empty response body received');
          return {
            'success': true,
            'message':
                'Password reset request sent successfully (empty response)',
          };
        }

        try {
          final Map<String, dynamic> responseData = json.decode(response.body);
          return responseData;
        } catch (jsonError) {
          print('JSON parsing error: $jsonError');
          print('Raw response: ${response.body}');

          return {
            'success': true,
            'message': 'Password reset request sent successfully',
          };
        }
      } else {
        print('HTTP Error ${response.statusCode}: ${response.body}');
        return {
          'success': false,
          'message':
              'Failed to send password reset request: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('Primary method failed: $e');
      String errorMessage = 'Network error: Unable to connect to server';
      if (e.toString().contains('timeout')) {
        errorMessage = 'Request timeout: Please try again';
      } else if (e.toString().contains('CORS') ||
          e.toString().contains('Cross-Origin')) {
        errorMessage = 'CORS error: Please check server configuration';
      } else if (e.toString().contains('Failed to fetch')) {
        errorMessage =
            'Network error: Failed to fetch. Check your internet connection.';
      }

      try {
        print('Trying fallback method...');
        return await _fallbackForgotPassword(email);
      } catch (fallbackError) {
        print('Fallback method also failed: $fallbackError');
        return {'success': false, 'message': errorMessage};
      }
    }
  }

  static Future<Map<String, dynamic>> _fallbackForgotPassword(
    String email,
  ) async {
    print('Using fallback forgot password method');

    final url = _apiUrl;

    final headers = <String, String>{
      'Content-Type': 'application/x-www-form-urlencoded',
      'Accept': 'application/json',
    };

    final body = {'email': email};
    final response = await WebRequestHandler.post(
      url,
      headers: headers,
      body: body,
      isFormData: true,
    );

    print('Fallback response status: ${response.statusCode}');
    print('Fallback response body: ${response.body}');

    if (response.statusCode == 200) {
      if (response.body.isEmpty) {
        return {
          'success': true,
          'message': 'Password reset request sent successfully',
        };
      }

      try {
        final Map<String, dynamic> responseData = json.decode(response.body);
        return responseData;
      } catch (jsonError) {
        return {
          'success': true,
          'message': 'Password reset request sent successfully',
        };
      }
    } else {
      return {
        'success': false,
        'message':
            'Failed to send password reset request: ${response.statusCode}',
      };
    }
  }
}

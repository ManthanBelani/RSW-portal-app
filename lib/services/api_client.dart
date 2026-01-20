import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import 'header_service.dart';

/// Centralized API client for making authenticated requests
/// This ensures all API calls use proper authentication with stored credentials
class ApiClient {
  /// Make an authenticated GET request
  /// 
  /// This method automatically:
  /// - Checks if user is logged in
  /// - Adds authentication headers (cookies, tokens)
  /// - Handles 401 errors (session expiration)
  /// - Auto-refreshes expired tokens
  static Future<http.Response>  get(
    String url, {
    Map<String, String>? extraHeaders,
    bool requireAuth = true,
  }) async {
    try {
      if (requireAuth) {
        final loginToken = await AuthService.getLoginToken();
        if (loginToken == null || loginToken.isEmpty) {
          throw ApiException(
            'User not logged in',
            statusCode: 401,
            errorCode: 'NOT_LOGGED_IN',
          );
        }

        // Get authentication headers with stored credentials
        final authHeaders = await HeadersService.getAuthHeaders();
        
        // Merge with any extra headers
        final headers = {...authHeaders, ...?extraHeaders};
        
        print('API GET: $url');
        print('Auth Headers: ${headers['Cookie']}');

        final response = await AuthService.makeAuthenticatedGet(
          url,
          extraHeaders: headers,
        );

        return _handleResponse(response);
      } else {
        // Non-authenticated request
        final response = await http.get(Uri.parse(url));
        return _handleResponse(response);
      }
    } catch (e) {
      print('API GET Error: $e');
      rethrow;
    }
  }

  /// Make an authenticated POST request
  /// 
  /// This method automatically:
  /// - Checks if user is logged in
  /// - Adds authentication headers (cookies, tokens)
  /// - Handles 401 errors (session expiration)
  /// - Auto-refreshes expired tokens
  static Future<http.Response> post(
    String url,
    Map<String, dynamic> body, {
    Map<String, String>? extraHeaders,
    bool isFormData = false,
    bool requireAuth = true,
  }) async {
    try {
      if (requireAuth) {
        // Verify user is logged in
        final loginToken = await AuthService.getLoginToken();
        if (loginToken == null || loginToken.isEmpty) {
          throw ApiException(
            'User not logged in',
            statusCode: 401,
            errorCode: 'NOT_LOGGED_IN',
          );
        }

        // Get authentication headers with stored credentials
        final authHeaders = await HeadersService.getAuthHeaders();
        
        // Merge with any extra headers
        final headers = {...authHeaders, ...?extraHeaders};
        
        print('API POST: $url');
        print('Auth Headers: ${headers['Cookie']}');

        final response = await AuthService.makeAuthenticatedPost(
          url,
          body,
          extraHeaders: headers,
          isFormData: isFormData,
        );

        return _handleResponse(response);
      } else {
        // Non-authenticated request
        final headers = {
          'Content-Type': isFormData 
              ? 'application/x-www-form-urlencoded' 
              : 'application/json',
          ...?extraHeaders,
        };
        
        final response = await http.post(
          Uri.parse(url),
          headers: headers,
          body: isFormData ? body : json.encode(body),
        );
        
        return _handleResponse(response);
      }
    } catch (e) {
      print('API POST Error: $e');
      rethrow;
    }
  }

  /// Handle API response and check for common errors
  static http.Response _handleResponse(http.Response response) {
    print('API Response Status: ${response.statusCode}');
    
    if (response.statusCode == 401) {
      // Session expired - clear stored data
      print('Session expired (401), clearing authentication data');
      AuthService.clearToken();
      throw ApiException(
        'Session expired. Please login again.',
        statusCode: 401,
        errorCode: 'SESSION_EXPIRED',
      );
    }
    
    return response;
  }

  /// Parse JSON response with error handling
  static Map<String, dynamic> parseJsonResponse(http.Response response) {
    try {
      return json.decode(response.body) as Map<String, dynamic>;
    } catch (e) {
      print('JSON Parse Error: $e');
      print('Response body: ${response.body}');
      throw ApiException(
        'Failed to parse server response',
        statusCode: response.statusCode,
        errorCode: 'PARSE_ERROR',
      );
    }
  }

  /// Check if user has valid authentication
  static Future<bool> hasValidAuth() async {
    try {
      final loginToken = await AuthService.getLoginToken();
      final userId = await AuthService.getUserId();
      final username = await AuthService.getUsername();
      
      return loginToken != null && 
             loginToken.isNotEmpty && 
             userId != null && 
             username != null;
    } catch (e) {
      return false;
    }
  }

  /// Refresh authentication if needed
  static Future<bool> refreshAuthIfNeeded() async {
    try {
      final isValid = await AuthService.isTokenValid();
      
      if (!isValid) {
        print('Token expired, refreshing...');
        final newToken = await AuthService.getValidToken();
        return newToken != null;
      }
      
      return true;
    } catch (e) {
      print('Error refreshing auth: $e');
      return false;
    }
  }
}

/// Custom exception for API errors
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? errorCode;

  ApiException(
    this.message, {
    this.statusCode,
    this.errorCode,
  });

  @override
  String toString() {
    return 'ApiException: $message (Status: $statusCode, Code: $errorCode)';
  }
}

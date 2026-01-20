import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;

// Conditional imports for web-specific functionality
import 'web_request_handler_stub.dart'
    if (dart.library.html) 'web_request_handler_web.dart' as web_impl;

/// A cross-platform HTTP request handler that uses HtmlHttpRequest for web
/// and the standard http package for mobile platforms to handle cookies properly
class WebRequestHandler {
  static http.Client? _client;
  
  static http.Client get client {
    _client ??= http.Client();
    return _client!;
  }

  /// Makes a GET request using appropriate method for the platform
  static Future<http.Response> get(String url, {Map<String, String>? headers}) async {
    if (kIsWeb) {
      return web_impl.WebRequestHandlerImpl.makeWebGetRequest(url, headers: headers);
    } else {
      return await client.get(Uri.parse(url), headers: headers);
    }
  }

  /// Makes a POST request using appropriate method for the platform
  static Future<http.Response> post(
    String url, {
    Map<String, String>? headers,
    dynamic body,
    bool isFormData = false,
  }) async {
    if (kIsWeb) {
      return web_impl.WebRequestHandlerImpl.makeWebPostRequest(
        url, 
        headers: headers,
        body: body, 
        isFormData: isFormData
      );
    } else {
      String requestBody;
      if (body is Map<String, dynamic>) {
        if (isFormData) {
          // Convert to form data string
          Map<String, String> stringBody = {};
          body.forEach((key, value) {
            stringBody[key] = value.toString();
          });
          requestBody = _convertMapToFormDataString(stringBody);
        } else {
          requestBody = jsonEncode(body);
        }
      } else if (body is String) {
        requestBody = body;
      } else {
        requestBody = body?.toString() ?? '';
      }

      return await client.post(
        Uri.parse(url),
        headers: headers,
        body: requestBody,
      );
    }
  }

  // Helper method to convert Map<String, String> to form data string
  static String _convertMapToFormDataString(Map<String, String> map) {
    return map.entries
        .map((entry) => '${Uri.encodeComponent(entry.key)}=${Uri.encodeComponent(entry.value)}')
        .join('&');
  }

  // Dispose method for cleanup
  static void dispose() {
    _client?.close();
  }
}
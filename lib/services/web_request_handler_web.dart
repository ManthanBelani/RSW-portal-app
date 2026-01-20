import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'package:http/http.dart' as http;

/// Web-specific implementation using dart:html
class WebRequestHandlerImpl {
  static Future<http.Response> makeWebGetRequest(
    String url, {
    Map<String, String>? headers,
  }) async {
    try {
      final request = html.HttpRequest();
      Completer<http.Response> completer = Completer();

      request.onLoad.listen((event) {
        http.Response response = http.Response(
          request.responseText ?? '',
          request.status ?? 500,
          headers: _convertHeaders(request.responseHeaders),
          request: http.Request('GET', Uri.parse(url)),
        );
        completer.complete(response);
      });

      request.onError.listen((event) {
        completer.completeError(Exception('Request failed: ${request.status}'));
      });

      request.open('GET', url);

      // Set headers
      if (headers != null) {
        headers.forEach((key, value) {
          request.setRequestHeader(key, value);
        });
      }

      // Enable automatic cookie handling for web
      request.withCredentials = true;

      request.send();

      return await completer.future;
    } catch (e) {
      throw Exception('Web GET request failed: $e');
    }
  }

  static Future<http.Response> makeWebPostRequest(
    String url, {
    Map<String, String>? headers,
    dynamic body,
    bool isFormData = false,
  }) async {
    try {
      final request = html.HttpRequest();
      Completer<http.Response> completer = Completer();

      request.onLoad.listen((event) {
        http.Response response = http.Response(
          request.responseText ?? '',
          request.status ?? 500,
          headers: _convertHeaders(request.responseHeaders),
          request: http.Request('POST', Uri.parse(url)),
        );
        completer.complete(response);
      });

      request.onError.listen((event) {
        completer.completeError(Exception('Request failed: ${request.status}'));
      });

      request.open('POST', url);

      // Set headers
      if (headers != null) {
        headers.forEach((key, value) {
          request.setRequestHeader(key, value);
        });
      }

      // Enable automatic cookie handling for web
      request.withCredentials = true;

      // Prepare body content
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

      request.send(requestBody);

      return await completer.future;
    } catch (e) {
      throw Exception('Web POST request failed: $e');
    }
  }

  // Helper method to convert Map<String, String> to form data string
  static String _convertMapToFormDataString(Map<String, String> map) {
    return map.entries
        .map((entry) => '${Uri.encodeComponent(entry.key)}=${Uri.encodeComponent(entry.value)}')
        .join('&');
  }

  // Helper to convert web response headers to standard format
  static Map<String, String> _convertHeaders(Map<String, String> webHeaders) {
    // For web requests, we'll return the headers as is
    // The browser automatically handles cookies and other authentication
    return Map<String, String>.from(webHeaders);
  }
}
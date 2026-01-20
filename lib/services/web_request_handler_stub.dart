import 'dart:async';
import 'package:http/http.dart' as http;
class WebRequestHandlerImpl {
  static Future<http.Response> makeWebGetRequest(
    String url, {
    Map<String, String>? headers,
  }) async {
    throw UnsupportedError(
      'Web-specific requests are not supported on this platform',
    );
  }

  static Future<http.Response> makeWebPostRequest(
    String url, {
    Map<String, String>? headers,
    dynamic body,
    bool isFormData = false,
  }) async {
    throw UnsupportedError(
      'Web-specific requests are not supported on this platform',
    );
  }
}

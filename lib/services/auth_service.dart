import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'web_request_handler.dart';

class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _tokenTimeKey = 'token_time';
  static const String _cookieKey = 'session_cookies';
  static const String _loginTokenKey = 'login_token';
  static const String _usernameKey = 'user_username';
  static const String _userIdKey = 'user_id';
  static const String _isLoggedInKey = 'is_logged_in';
  static const String _userDataKey = 'user_data';

  static String get _apiUrl {
    final baseUrl =
        dotenv.env['BASE_URL'] ??
        'https://rainflowweb.com/demo/account-upgrade/api';
    return '$baseUrl/authentication/token.php';
  }

  static String? _cachedToken;
  static int? _cachedTokenTime;
  static String? _sessionCookies;
  static String? _cachedLoginToken;

  static String? _splashToken;
  static int? _splashTokenTime;

  static http.Client? _client;

  static http.Client get client {
    if (_client == null) {
      _client = http.Client();
    }
    return _client!;
  }

  // Helper method to process a single cookie string
  static void _processCookie(
    String cookieString,
    Map<String, String> cookiesMap,
  ) {
    // Get just the name=value part (before first semicolon)
    final parts = cookieString.split(';');
    if (parts.isNotEmpty) {
      final nameValue = parts[0].trim();
      if (nameValue.contains('=')) {
        final keyValue = nameValue.split('=');
        if (keyValue.length >= 2) {
          final name = keyValue[0].trim();
          final value = keyValue.sublist(1).join('=').trim();

          if (name.isNotEmpty && value.isNotEmpty) {
            cookiesMap[name] = value;
            print('Extracted cookie: $name=$value');
          }
        }
      }
    }
  }

  // Extract and store cookies from response (mobile only)
  static void _extractAndStoreCookies(http.Response response) {
    if (!kIsWeb) {
      final setCookie = response.headers['set-cookie'];
      if (setCookie != null) {
        print('Raw Set-Cookie header: $setCookie');

        // Parse existing cookies into a map
        final existingCookiesMap = <String, String>{};
        if (_sessionCookies != null && _sessionCookies!.isNotEmpty) {
          final existingParts = _sessionCookies!.split(';');
          for (var part in existingParts) {
            final trimmed = part.trim();
            if (trimmed.contains('=')) {
              final keyValue = trimmed.split('=');
              if (keyValue.length >= 2) {
                existingCookiesMap[keyValue[0].trim()] = keyValue
                    .sublist(1)
                    .join('=')
                    .trim();
              }
            }
          }
        }

        print('Existing cookies map: $existingCookiesMap');

        // Parse new cookies from response
        // Set-Cookie format: "name1=value1; attr1; attr2,name2=value2; attr3"
        // Problem: Dates also contain commas (e.g., "Sun, 03 May 2026")
        // Solution: Look for patterns that indicate a new cookie (name=value at start after comma)

        // Split by comma, but we need to be smart about it
        final parts = setCookie.split(',');
        String? currentCookie;

        for (var i = 0; i < parts.length; i++) {
          final part = parts[i].trim();

          // Check if this part starts with a cookie (has name=value before first semicolon)
          final firstSemicolon = part.indexOf(';');
          final checkPart = firstSemicolon >= 0
              ? part.substring(0, firstSemicolon)
              : part;

          // If it contains '=' and doesn't start with a space or common attribute name, it's likely a cookie
          if (checkPart.contains('=') &&
              !checkPart.startsWith(' ') &&
              !checkPart.toLowerCase().startsWith('expires') &&
              !checkPart.toLowerCase().startsWith('max-age') &&
              !checkPart.toLowerCase().startsWith('path') &&
              !checkPart.toLowerCase().startsWith('domain')) {
            // This is a new cookie, process the previous one if exists
            if (currentCookie != null) {
              _processCookie(currentCookie, existingCookiesMap);
            }
            currentCookie = part;
          } else {
            // This is a continuation (probably part of a date), append to current cookie
            if (currentCookie != null) {
              currentCookie += ',$part';
            }
          }
        }

        // Process the last cookie
        if (currentCookie != null) {
          _processCookie(currentCookie, existingCookiesMap);
        }

        print('Merged cookies map: $existingCookiesMap');

        // Rebuild cookie string from merged map
        if (existingCookiesMap.isNotEmpty) {
          final mergedCookies = existingCookiesMap.entries
              .map((e) => '${e.key}=${e.value}')
              .join('; ');

          _sessionCookies = mergedCookies;
          _saveCookiesToPrefs(_sessionCookies!);
          print('✅ Mobile - Cookies merged and stored: $_sessionCookies');
        } else {
          print('⚠️  No valid cookies extracted from response');
        }
      }
    } else {
      print('Web - Cookies handled by browser automatically');
    }
  }

  // Save cookies to SharedPreferences
  static Future<void> _saveCookiesToPrefs(String cookies) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cookieKey, cookies);
  }

  // Load cookies from SharedPreferences
  static Future<void> _loadCookiesFromPrefs({bool forceReload = false}) async {
    // Skip if already loaded and not forcing reload
    if (_sessionCookies != null && !forceReload) return;

    final prefs = await SharedPreferences.getInstance();
    _sessionCookies = prefs.getString(_cookieKey);
    if (_sessionCookies != null) {
      print('Cookies loaded from storage: $_sessionCookies');
    } else {
      print('No cookies found in storage');
    }
  }

  // Public method to load cookies from storage (for use by other services)
  static Future<void> loadCookiesFromStorage({bool forceReload = false}) async {
    await _loadCookiesFromPrefs(forceReload: forceReload);
  }

  // Build headers with cookies
  static Future<Map<String, String>> _buildHeaders({
    Map<String, String>? extraHeaders,
    bool isFormData = false,
  }) async {
    // For web, we don't manually add cookies as the browser handles them
    if (!kIsWeb) {
      // ALWAYS load cookies from storage, even if _sessionCookies is not null
      // This ensures cookies are available after app restart
      final prefs = await SharedPreferences.getInstance();
      final storedCookies = prefs.getString(_cookieKey);
      if (storedCookies != null && storedCookies.isNotEmpty) {
        _sessionCookies = storedCookies;
        final preview = _sessionCookies!.length > 50
            ? '${_sessionCookies!.substring(0, 50)}...'
            : _sessionCookies!;
        print('Cookies loaded for request: $preview');
      }
    }

    // Default to JSON content type, but change if form data is specified
    String contentType = isFormData
        ? 'application/x-www-form-urlencoded'
        : 'application/json';
    final headers = <String, String>{
      'Content-Type': contentType,
      'Accept': 'application/json',
    };

    // Only add cookies manually for mobile
    if (!kIsWeb && _sessionCookies != null) {
      headers['Cookie'] = _sessionCookies!;
    }

    if (extraHeaders != null) {
      headers.addAll(extraHeaders);
    }

    return headers;
  }

  static Future<Map<String, dynamic>?> generateToken() async {
    try {
      final headers = await _buildHeaders();

      final response = await WebRequestHandler.get(_apiUrl, headers: headers);

      print('Generate Token - Status: ${response.statusCode}');
      print('Generate Token - Headers: ${response.headers}');

      // Extract cookies from response
      _extractAndStoreCookies(response);

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData['success'] == true && responseData['data'] != null) {
          final tokenData = responseData['data'];
          final String token = tokenData['token'];
          final int tokenTime = tokenData['token_time'];
          await _storeToken(token, tokenTime);

          _cachedToken = token;
          _cachedTokenTime = tokenTime;

          print('Token generated successfully: $token');
          return tokenData;
        } else {
          print(
            'API response indicates failure: ${responseData['message'] ?? 'Unknown error'}',
          );
          return null;
        }
      } else if (response.statusCode == 401) {
        print('Failed to generate token. Status code: ${response.statusCode}');
        print('Response body: ${response.body}');
        // Only clear session cookies, NOT login data
        // The user might still be logged in with login_token
        _sessionCookies = null;
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_cookieKey);
        print('Cleared expired session cookies (keeping login data)');
        return null;
      } else {
        print('Failed to generate token. Status code: ${response.statusCode}');
        print('Response body: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error generating token: $e');
      return null;
    }
  }

  static Future<void> _storeToken(String token, int tokenTime) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setInt(_tokenTimeKey, tokenTime);
  }

  static Future<String?> getToken() async {
    if (_cachedToken != null) {
      return _cachedToken;
    }

    final prefs = await SharedPreferences.getInstance();
    _cachedToken = prefs.getString(_tokenKey);
    return _cachedToken;
  }

  static Future<int?> getTokenTime() async {
    if (_cachedTokenTime != null) {
      return _cachedTokenTime;
    }

    final prefs = await SharedPreferences.getInstance();
    _cachedTokenTime = prefs.getInt(_tokenTimeKey);
    return _cachedTokenTime;
  }

  static Future<bool> isTokenValid() async {
    final tokenTime = await getTokenTime();
    if (tokenTime == null) return false;

    final currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return currentTime < tokenTime;
  }

  static Future<String?> getValidToken() async {
    final isValid = await isTokenValid();

    if (!isValid) {
      print('Token is expired or not available, generating new token...');

      // Check if user is logged in - if so, don't try to refresh token
      // The login_token is what matters for authenticated requests
      final loginToken = await getLoginToken();
      if (loginToken != null && loginToken.isNotEmpty) {
        print('User is logged in with login_token, skipping token refresh');
        // Return the cached token or null - login_token will be used for auth
        return _cachedToken;
      }

      final tokenData = await generateToken();
      return tokenData?['token'];
    }

    return await getToken();
  }

  // Store login token from login response
  static Future<void> storeUserLoginToken(String loginToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_loginTokenKey, loginToken);
    _cachedLoginToken = loginToken;
    print('Login token stored successfully: $loginToken');
  }

  // Get stored login token
  static Future<String?> getLoginToken() async {
    if (_cachedLoginToken != null) {
      return _cachedLoginToken;
    }

    final prefs = await SharedPreferences.getInstance();
    _cachedLoginToken = prefs.getString(_loginTokenKey);
    return _cachedLoginToken;
  }

  // Store username from login response
  static Future<void> storeUsername(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_usernameKey, username);
    print('Username stored successfully: $username');
  }

  // Get stored username
  static Future<String?> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_usernameKey);
  }

  // Store user_id from login response
  static Future<void> storeUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userIdKey, userId);
    print('User ID stored successfully: $userId');
  }

  // Get stored user_id
  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userIdKey);
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_tokenTimeKey);
    await prefs.remove(_cookieKey);
    await prefs.remove(_loginTokenKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_usernameKey);
    await prefs.remove(_isLoggedInKey);
    await prefs.remove(_userDataKey);
    // Clear additional user profile data fields
    await prefs.remove('user_email');
    await prefs.remove('user_first_name');
    await prefs.remove('user_last_name');
    await prefs.remove('user_phone');
    await prefs.remove('user_designation');
    _cachedToken = null;
    _cachedTokenTime = null;
    _sessionCookies = null;
    _cachedLoginToken = null;
  }

  static Future<void> logout() async {
    await clearToken();
    print('User logged out successfully');
  }

  static Future<void> initializeToken() async {
    print('Initializing authentication token...');
    final tokenData = await generateToken();

    if (tokenData != null) {
      print('Token initialized successfully');
    } else {
      print('Failed to initialize token');
    }
  }

  // Method to generate token during splash and store only in variable
  static Future<Map<String, dynamic>?> generateTokenForSplash() async {
    try {
      final headers = await _buildHeaders();

      final response = await WebRequestHandler.get(_apiUrl, headers: headers);

      print('Splash Token - Status: ${response.statusCode}');

      // Extract cookies from response
      _extractAndStoreCookies(response);

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData['success'] == true && responseData['data'] != null) {
          final tokenData = responseData['data'];
          final String token = tokenData['token'];
          final int tokenTime = tokenData['token_time'];

          // Store only in variables, NOT in shared preferences
          _splashToken = token;
          _splashTokenTime = tokenTime;

          print('Splash token generated and stored in variable: $token');
          return tokenData;
        } else {
          print(
            'API response indicates failure: ${responseData['message'] ?? 'Unknown error'}',
          );
          return null;
        }
      } else if (response.statusCode == 401) {
        print(
          'Failed to generate splash token. Status code: ${response.statusCode}',
        );
        print('Response body: ${response.body}');
        // Only clear session cookies, NOT login data
        _sessionCookies = null;
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_cookieKey);
        print('Cleared expired session cookies (keeping login data)');
        return null;
      } else {
        print(
          'Failed to generate splash token. Status code: ${response.statusCode}',
        );
        print('Response body: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error generating splash token: $e');
      return null;
    }
  }

  // Method to get the splash token (from variable)
  static String? getSplashToken() {
    return _splashToken;
  }

  // Method to store token to shared preferences after successful login
  static Future<void> storeTokenAfterLogin() async {
    if (_splashToken != null && _splashTokenTime != null) {
      await _storeToken(_splashToken!, _splashTokenTime!);
      _cachedToken = _splashToken;
      _cachedTokenTime = _splashTokenTime;
      print('Token stored to shared preferences after successful login');
    }
  }

  // Public method to store tokens received from login response
  static Future<void> storeLoginToken(String token, int tokenTime) async {
    await _storeToken(token, tokenTime);

    _cachedToken = token;
    _cachedTokenTime = tokenTime;

    print('Login token stored successfully: $token');
  }

  // Method to make authenticated POST requests with cookies
  static Future<http.Response> makeAuthenticatedPost(
    String url,
    Map<String, dynamic> body, {
    Map<String, String>? extraHeaders,
    bool isFormData = false,
  }) async {
    try {
      final headers = await _buildHeaders(
        extraHeaders: extraHeaders,
        isFormData: isFormData,
      );

      print('Making POST request to: $url');
      print('Headers: $headers');

      final response = await WebRequestHandler.post(
        url,
        headers: headers,
        body: body,
        isFormData: isFormData,
      );

      print('Response Status: ${response.statusCode}');
      print('Response Headers: ${response.headers}');
      print('Response Body: ${response.body}');

      // Update cookies - this handles the response cookies appropriately for each platform
      _extractAndStoreCookies(response);

      return response;
    } catch (e) {
      print('Error making authenticated POST request: $e');
      rethrow;
    }
  }

  // Method to make authenticated GET requests with cookies
  static Future<http.Response> makeAuthenticatedGet(
    String url, {
    Map<String, String>? extraHeaders,
  }) async {
    try {
      final headers = await _buildHeaders(extraHeaders: extraHeaders);

      print('Making GET request to: $url');
      print('Headers: $headers');

      final response = await WebRequestHandler.get(url, headers: headers);

      print('Response Status: ${response.statusCode}');

      _extractAndStoreCookies(response);

      return response;
    } catch (e) {
      print('Error making authenticated GET request: $e');
      rethrow;
    }
  }

  static String? getSessionCookies() {
    return _sessionCookies;
  }

  // Store login state and user data for persistent login
  static Future<void> setLoggedIn(
    bool isLoggedIn, [
    Map<String, dynamic>? userData,
  ]) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedInKey, isLoggedIn);

    if (userData != null) {
      await prefs.setString(_userDataKey, json.encode(userData));
      print('User data stored for persistent login');

      // Store additional user profile data for better persistent login
      if (userData['data'] != null && userData['data']['user'] != null) {
        final user = userData['data']['user'];
        await _storeUserProfileData(user);
      }
    }

    print('Login state set to: $isLoggedIn');
  }

  // Store user profile data separately for easier access
  static Future<void> _storeUserProfileData(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();

    if (user['id'] != null) {
      await prefs.setString(_userIdKey, user['id'].toString());
    }
    if (user['username'] != null) {
      await prefs.setString(_usernameKey, user['username']);
    }
    if (user['email'] != null) {
      await prefs.setString('user_email', user['email']);
    }
    if (user['first_name'] != null) {
      await prefs.setString('user_first_name', user['first_name']);
    }
    if (user['last_name'] != null) {
      await prefs.setString('user_last_name', user['last_name']);
    }
    if (user['phone'] != null) {
      await prefs.setString('user_phone', user['phone']);
    }
    if (user['designation'] != null) {
      await prefs.setString('user_designation', user['designation']);
    }

    print('User profile data stored for persistent login');
  }

  // Get user profile data for persistent login
  static Future<Map<String, dynamic>?> getUserProfileData() async {
    final prefs = await SharedPreferences.getInstance();

    try {
      // Try to get from stored user data first
      Map<String, dynamic>? userData = await getStoredUserData();
      if (userData != null) {
        // Return user object from the full data
        if (userData['data'] != null && userData['data']['user'] != null) {
          return Map<String, dynamic>.from(userData['data']['user']);
        }
      }

      // If not found in full data, try to reconstruct from individual fields
      String? userId = prefs.getString(_userIdKey);
      String? username = prefs.getString(_usernameKey);
      String? email = prefs.getString('user_email');
      String? firstName = prefs.getString('user_first_name');
      String? lastName = prefs.getString('user_last_name');
      String? phone = prefs.getString('user_phone');
      String? designation = prefs.getString('user_designation');

      if (userId != null || username != null || email != null) {
        // At least some user data is available
        Map<String, dynamic> reconstructedUser = {};

        if (userId != null) reconstructedUser['id'] = userId;
        if (username != null) reconstructedUser['username'] = username;
        if (email != null) reconstructedUser['email'] = email;
        if (firstName != null) reconstructedUser['first_name'] = firstName;
        if (lastName != null) reconstructedUser['last_name'] = lastName;
        if (phone != null) reconstructedUser['phone'] = phone;
        if (designation != null) reconstructedUser['designation'] = designation;

        return reconstructedUser;
      }

      return null;
    } catch (e) {
      print('Error getting user profile data: $e');
      return null;
    }
  }

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool(_isLoggedInKey) ?? false;

    print('>>> isLoggedIn() check:');
    print('    is_logged_in flag: $isLoggedIn');

    if (isLoggedIn) {
      // Load cookies from storage if not already loaded
      await _loadCookiesFromPrefs();

      // Also check if we have valid login token, cookies, and user data
      final loginToken = await getLoginToken();
      final username = await getUsername();
      final userId = await getUserId();
      final userData = await getStoredUserData();
      final cookies = _sessionCookies;

      print(
        '    loginToken: ${loginToken != null ? "Present (${loginToken.substring(0, 10)}...)" : "MISSING"}',
      );
      print('    username: ${username ?? "MISSING"}');
      print('    userId: ${userId ?? "MISSING"}');
      print('    userData: ${userData != null ? "Present" : "MISSING"}');
      print('    cookies: ${cookies != null ? "Present" : "MISSING"}');

      // If we have login state but missing essential data, consider not logged in
      if (loginToken == null ||
          username == null ||
          userId == null ||
          userData == null ||
          cookies == null) {
        print(
          '    ❌ Login state exists but missing essential data, clearing login state',
        );
        await setLoggedIn(false);
        return false;
      }

      print('    ✅ All data present (including cookies), user is logged in!');
    }

    return isLoggedIn;
  }

  // Get stored user data
  static Future<Map<String, dynamic>?> getStoredUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString(_userDataKey);

    if (userDataString != null) {
      try {
        return json.decode(userDataString) as Map<String, dynamic>;
      } catch (e) {
        print('Error parsing stored user data: $e');
        return null;
      }
    }

    return null;
  }

  // Check if stored login data is complete and valid
  static Future<bool> validateStoredLogin() async {
    try {
      // Load cookies from storage first
      await _loadCookiesFromPrefs();

      final loginToken = await getLoginToken();
      final username = await getUsername();
      final userId = await getUserId();
      final userData = await getStoredUserData();
      final cookies = _sessionCookies;

      print('Validating stored login:');
      print('  loginToken: ${loginToken != null ? "Present" : "Missing"}');
      print('  username: ${username ?? "Missing"}');
      print('  userId: ${userId ?? "Missing"}');
      print('  userData: ${userData != null ? "Present" : "Missing"}');
      print(
        '  cookies: ${cookies != null ? "Present (${cookies.substring(0, 30)}...)" : "Missing"}',
      );

      // Check if all required data is present including cookies
      if (loginToken == null ||
          username == null ||
          userId == null ||
          userData == null ||
          cookies == null) {
        print(
          'Incomplete login data found (missing cookies or other data), clearing login state',
        );
        await setLoggedIn(false);
        return false;
      }

      // For persistent login, we need both login_token AND PHPSESSID cookie
      // The cookie is essential for making authenticated API calls
      print(
        'All required login data present (including cookies) - login is valid!',
      );
      return true;
    } catch (e) {
      print('Error validating stored login: $e');
      await setLoggedIn(false);
      return false;
    }
  }

  // Debug method to print current login status
  static Future<void> printLoginStatus() async {
    // Load cookies first
    await _loadCookiesFromPrefs();

    final isLoggedIn = await AuthService.isLoggedIn();
    final loginToken = await getLoginToken();
    final username = await getUsername();
    final userId = await getUserId();
    final userData = await getStoredUserData();
    final cookies = _sessionCookies;

    print('=== LOGIN STATUS DEBUG ===');
    print('Is Logged In: $isLoggedIn');
    print('Login Token: ${loginToken != null ? 'Present' : 'Missing'}');
    print('Username: $username');
    print('User ID: $userId');
    print('User Data: ${userData != null ? 'Present' : 'Missing'}');
    final cookiePreview = cookies != null
        ? (cookies.length > 50
              ? 'Present (${cookies.substring(0, 50)}...)'
              : 'Present ($cookies)')
        : 'Missing';
    print('Session Cookies: $cookiePreview');
    print('========================');
  }

  static void dispose() {
    _client?.close();
  }
}

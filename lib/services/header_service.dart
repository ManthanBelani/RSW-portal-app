import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'auth_service.dart';

class HeadersService {
  static Future<Map<String, String>> getAuthHeaders() async {
    final loginToken = await AuthService.getLoginToken();
    if (loginToken == null || loginToken.isEmpty) {
      throw Exception('User not logged in');
    }

    // IMPORTANT: Force reload cookies from storage before building headers
    // This is critical for persistent login to work after app restart
    // Force reload ensures we always get fresh cookies from storage
    await AuthService.loadCookiesFromStorage(forceReload: true);

    // Get stored authentication data
    final sessionCookies = AuthService.getSessionCookies();
    final userId = await AuthService.getUserId();
    
    print('HeaderService - Building headers:');
    print('  Has sessionCookies: ${sessionCookies != null}');
    print('  Has login_token: true (checked above)');

    // Validate that we have session cookies - they're mandatory for API calls
    if (sessionCookies == null || sessionCookies.isEmpty) {
      print('❌ ERROR: Session cookies are missing!');
      print('   This will cause 401 errors on API calls.');
      print('   User needs to login again to get fresh cookies.');
      throw Exception('Session expired - cookies missing. Please login again.');
    }

    // Parse stored cookies to check for PHPSESSID
    String? phpSessionId;
    final cookieParts = sessionCookies.split(';');
    for (var part in cookieParts) {
      final trimmed = part.trim();
      if (trimmed.startsWith('PHPSESSID=')) {
        phpSessionId = trimmed.split('=')[1];
        break;
      }
    }

    // Validate that we have PHPSESSID - it's mandatory for API calls
    if (phpSessionId == null || phpSessionId.isEmpty) {
      print('❌ ERROR: PHPSESSID cookie is missing from stored cookies!');
      print('   Stored cookies: $sessionCookies');
      print('   User needs to login again to get fresh cookies.');
      throw Exception('Session expired - PHPSESSID cookie missing. Please login again.');
    }

    // Build cookie string: use ALL stored cookies + add login_token if not already present
    String cookieString = sessionCookies;
    
    // Add login_token if not already in the cookie string
    if (!cookieString.contains('login_token=')) {
      cookieString += '; login_token=$loginToken';
    }
    
    // Add LoginUserId if not already in the cookie string and we have userId
    if (userId != null && !cookieString.contains('LoginUserId=')) {
      cookieString += '; LoginUserId=$userId';
    }

    print('✅ Building auth headers with stored data:');
    print('  PHPSESSID: ${phpSessionId.substring(0, 10)}...');
    print('  Full cookie string: ${cookieString.length > 100 ? '${cookieString.substring(0, 100)}...' : cookieString}');
    print('  Login Token: Present');

    return {
      'Accept': 'application/json, text/plain, */*',
      'Accept-Encoding': 'gzip, deflate, br, zstd',
      'Accept-Language': 'en-GB,en-US;q=0.9,en;q=0.8',
      'Cookie': cookieString,
    };
  }

  static String get baseUrl {
    return dotenv.env['BASE_URL'] ??
        'https://rainflowweb.com/demo/account-upgrade/api';
  }
}

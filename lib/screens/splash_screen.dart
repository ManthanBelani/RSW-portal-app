// import 'package:flutter/material.dart';
// import '../services/auth_service.dart';
// import 'login_screen.dart';
//
// class SplashScreen extends StatefulWidget {
//   const SplashScreen({super.key});
//
//   @override
//   State<SplashScreen> createState() => _SplashScreenState();
// }
//
// class _SplashScreenState extends State<SplashScreen> {
//   @override
//   void initState() {
//     super.initState();
//     _initializeApp();
//   }
//
//   Future<void> _initializeApp() async {
//     try {
//       // Generate token using auth_service and store in variable (not shared preferences)
//       await AuthService.generateTokenForSplash();
//     } catch (e) {
//       print('Error during app initialization: $e');
//     }
//
//     // Wait for a minimum of 2 seconds total (or continue sooner if initialization was slow)
//     await Future.delayed(const Duration(seconds: 2));
//
//     // Navigate to login screen
//     if (mounted) {
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(builder: (context) => const LoginScreen()),
//       );
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             // Logo
//             Image.asset(
//               'assets/images/rsLogo167-1.png',
//               height: 120,
//               width: 120,
//             ),
//             const SizedBox(height: 20),
//             Image.asset(
//               'assets/images/namedlogo1.png',
//               height: 80,
//             ),
//             const SizedBox(height: 40),
//             // Loading indicator
//             const CircularProgressIndicator(
//               valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFC3342)),
//               strokeWidth: 3.0,
//             ),
//             const SizedBox(height: 20),
//             const Text(
//               'Loading...',
//               style: TextStyle(
//                 fontSize: 16,
//                 color: Colors.grey,
//                 fontWeight: FontWeight.w500,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }


import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      print('SPLASH SCREEN INITIALIZATION');
      final tokenData = await AuthService.generateTokenForSplash();
      if (tokenData != null) {
        print('Splash token generated successfully');
        print('Token: ${AuthService.getSplashToken()}');
        print('Session Cookies: ${AuthService.getSessionCookies()}');
        if (AuthService.getSessionCookies() == null) {
          print('WARNING: No cookies received from server!');
          print('   This might cause 401 errors during login.');
          print('   Check if the token API is setting cookies.');
        }
      } else {
        print('Failed to generate splash token');
        print('   Login might fail due to missing token/cookies');
        print('   This could be due to an expired session. Clearing old session data...');
      }
      print('=== INITIALIZATION COMPLETE ===\n');
    } catch (e) {
      print('❌ Error during app initialization: $e');
      print('   Stack trace: ${StackTrace.current}');
    }
    await Future.delayed(const Duration(seconds: 5));
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Image.asset(
              'assets/images/rsLogo167-1.png',
              height: 120,
              width: 120,
            ),
            const SizedBox(height: 20),
            Image.asset(
              'assets/images/namedlogo1.png',
              height: 80,
            ),
            const SizedBox(height: 40),
            // Loading indicator
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFC3342)),
              strokeWidth: 3.0,
            ),
            const SizedBox(height: 20),
            const Text(
              'Loading...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
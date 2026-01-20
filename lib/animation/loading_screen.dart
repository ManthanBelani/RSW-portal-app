import 'package:flutter/material.dart';

import '../screens/login_screen.dart';
import '../screens/dashboard_screen.dart';
import '../services/auth_service.dart';

// Logo widget with fallback to icon if image fails
class Logo extends StatelessWidget {
  final bool disabledLink;
  final double width;
  final double height;

  const Logo({
    super.key,
    this.disabledLink = false,
    this.width = 64.0,
    this.height = 64.0,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/rsLogo167-1.png',
      width: width,
      height: height,
      errorBuilder: (context, error, stackTrace) {
        // Fallback to icon if image fails to load
        return Icon(
          Icons.dashboard,
          size: width,
          color: Theme.of(context).primaryColor,
        );
      },
    );
  }
}

class LoadingScreen extends StatefulWidget {
  final bool isDashboard;

  const LoadingScreen({super.key, this.isDashboard = false});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen>
    with TickerProviderStateMixin {

  Future<void> _initializeApp() async {
    try {
      print('========================================');
      print('SPLASH SCREEN INITIALIZATION');
      print('========================================');
      
      // Debug: Print current login status (this will also load cookies)
      await AuthService.printLoginStatus();
      
      // Check if user is already logged in and validate stored data
      final isLoggedIn = await AuthService.isLoggedIn();
      print('>>> isLoggedIn result: $isLoggedIn');
      
      if (isLoggedIn) {
        print('✅ User appears to be logged in with valid cookies, validating stored data...');
        final isValidLogin = await AuthService.validateStoredLogin();
        
        if (isValidLogin) {
          // Try to get full user data first, fallback to user profile data
          Map<String, dynamic>? userData = await AuthService.getStoredUserData();
          
          // If full user data is not available, construct it from user profile data
          if (userData == null || (userData['data'] == null || userData['data']['user'] == null)) {
            final userProfileData = await AuthService.getUserProfileData();
            if (userProfileData != null) {
              // Reconstruct the user data structure for the dashboard
              userData = {
                'success': true,
                'data': {
                  'user': userProfileData,
                  'user_designation_permission': userData?['data']?['user_designation_permission'], // Keep existing permissions if available
                }
              };
              print('Reconstructed user data from stored profile');
            }
          }
          
          if (userData != null) {
            print('✅ Valid login found with cookies, navigating to dashboard');
            print('   Session will be maintained with stored PHPSESSID cookie');
            
            await Future.delayed(const Duration(seconds: 2));
            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => DashboardScreen(result: userData),
                ),
              );
            }
            return;
          } else {
            print('❌ User data could not be retrieved, proceeding to login screen');
          }
        } else {
          print('❌ Invalid or expired login data (missing cookies), proceeding to login screen');
        }
      } else {
        print('❌ User not logged in or missing cookies, proceeding to login screen');
      }
      
      // Only generate token for splash if user is not already logged in
      if (!isLoggedIn) {
        print('Generating fresh token and cookies for new session...');
        final tokenData = await AuthService.generateTokenForSplash();
        if (tokenData != null) {
          print('✅ Splash token generated successfully');
          print('   Token: ${AuthService.getSplashToken()}');
          print('   Session Cookies: ${AuthService.getSessionCookies()}');
          if (AuthService.getSessionCookies() == null) {
            print('⚠️  WARNING: No cookies received from server!');
            print('   This might cause 401 errors during login.');
            print('   Check if the token API is setting cookies.');
          }
        } else {
          print('❌ Failed to generate splash token');
          print('   Login might fail due to missing token/cookies');
        }
      }
      print('=== INITIALIZATION COMPLETE ===\n');
    } catch (e) {
      print('❌ Error during app initialization: $e');
      print('   Stack trace: ${StackTrace.current}');
    }
    
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }
  late AnimationController _box1Controller;
  late AnimationController _box2Controller;

  late Animation<double> _box1Scale;
  late Animation<double> _box1Rotation;
  late Animation<double> _box1Opacity;
  late Animation<double> _box1BorderRadius;
  late Animation<double> _box2Scale;
  late Animation<double> _box2Rotation;
  late Animation<double> _box2Opacity;
  late Animation<double> _box2BorderRadius;

  @override
  void initState() {
    super.initState();
    _initializeApp();
    // Box 1 animations (scale, rotation, opacity, border radius, 3.2 seconds, linear, infinite)
    _box1Controller = AnimationController(
      duration: const Duration(milliseconds: 3200),
      vsync: this,
    )..repeat();
    _box1Scale = TweenSequence([
      TweenSequenceItem(tween: Tween<double>(begin: 1.2, end: 1.0), weight: 20),
      TweenSequenceItem(tween: ConstantTween<double>(1.0), weight: 20),
      TweenSequenceItem(tween: ConstantTween<double>(1.0), weight: 20),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 1.2), weight: 20),
      TweenSequenceItem(tween: ConstantTween<double>(1.2), weight: 20),
    ]).animate(CurvedAnimation(parent: _box1Controller, curve: Curves.linear));
    _box1Rotation = TweenSequence([
      TweenSequenceItem(
        tween: Tween<double>(begin: 4.71239, end: 0.0),
        weight: 20,
      ), // 270 degrees to 0
      TweenSequenceItem(tween: ConstantTween<double>(0.0), weight: 20),
      TweenSequenceItem(tween: ConstantTween<double>(0.0), weight: 20),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 4.71239),
        weight: 20,
      ),
      TweenSequenceItem(tween: ConstantTween<double>(4.71239), weight: 20),
    ]).animate(CurvedAnimation(parent: _box1Controller, curve: Curves.linear));
    _box1Opacity = TweenSequence([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.25, end: 1.0),
        weight: 20,
      ),
      TweenSequenceItem(tween: ConstantTween<double>(1.0), weight: 20),
      TweenSequenceItem(tween: ConstantTween<double>(1.0), weight: 20),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.25),
        weight: 20,
      ),
      TweenSequenceItem(tween: ConstantTween<double>(0.25), weight: 20),
    ]).animate(CurvedAnimation(parent: _box1Controller, curve: Curves.linear));
    _box1BorderRadius = TweenSequence([
      TweenSequenceItem(tween: ConstantTween<double>(25.0), weight: 20),
      TweenSequenceItem(tween: ConstantTween<double>(25.0), weight: 20),
      TweenSequenceItem(
        tween: Tween<double>(begin: 25.0, end: 50.0),
        weight: 20,
      ),
      TweenSequenceItem(tween: ConstantTween<double>(50.0), weight: 20),
      TweenSequenceItem(
        tween: Tween<double>(begin: 50.0, end: 25.0),
        weight: 20,
      ),
    ]).animate(CurvedAnimation(parent: _box1Controller, curve: Curves.linear));

    // Box 2 animations (scale, rotation, opacity, border radius, 3.2 seconds, linear, infinite)
    _box2Controller = AnimationController(
      duration: const Duration(milliseconds: 3200),
      vsync: this,
    )..repeat();
    _box2Scale = TweenSequence([
      TweenSequenceItem(tween: ConstantTween<double>(1.0), weight: 20),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 1.2), weight: 20),
      TweenSequenceItem(tween: ConstantTween<double>(1.2), weight: 20),
      TweenSequenceItem(tween: Tween<double>(begin: 1.2, end: 1.0), weight: 20),
      TweenSequenceItem(tween: ConstantTween<double>(1.0), weight: 20),
    ]).animate(CurvedAnimation(parent: _box2Controller, curve: Curves.linear));
    _box2Rotation = TweenSequence([
      TweenSequenceItem(tween: ConstantTween<double>(0.0), weight: 20),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 4.71239),
        weight: 20,
      ), // 0 to 270 degrees
      TweenSequenceItem(tween: ConstantTween<double>(4.71239), weight: 20),
      TweenSequenceItem(
        tween: Tween<double>(begin: 4.71239, end: 0.0),
        weight: 20,
      ),
      TweenSequenceItem(tween: ConstantTween<double>(0.0), weight: 20),
    ]).animate(CurvedAnimation(parent: _box2Controller, curve: Curves.linear));
    _box2Opacity = TweenSequence([
      TweenSequenceItem(tween: ConstantTween<double>(1.0), weight: 20),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.25),
        weight: 20,
      ),
      TweenSequenceItem(tween: ConstantTween<double>(0.25), weight: 20),
      TweenSequenceItem(tween: ConstantTween<double>(0.25), weight: 20),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.25, end: 1.0),
        weight: 20,
      ),
    ]).animate(CurvedAnimation(parent: _box2Controller, curve: Curves.linear));
    _box2BorderRadius = TweenSequence([
      TweenSequenceItem(tween: ConstantTween<double>(25.0), weight: 20),
      TweenSequenceItem(tween: ConstantTween<double>(25.0), weight: 20),
      TweenSequenceItem(
        tween: Tween<double>(begin: 25.0, end: 50.0),
        weight: 20,
      ),
      TweenSequenceItem(tween: ConstantTween<double>(50.0), weight: 20),
      TweenSequenceItem(
        tween: Tween<double>(begin: 50.0, end: 25.0),
        weight: 20,
      ),
    ]).animate(CurvedAnimation(parent: _box2Controller, curve: Curves.linear));
  }

  @override
  void dispose() {
    _box1Controller.dispose();
    _box2Controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SizedBox(
          width: 200,
          height: 200,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Static logo in center
              const Logo(width: 64, height: 64),
              // Box 1 - Inner animated border
              AnimatedBuilder(
                animation: _box1Controller,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _box1Scale.value,
                    child: Transform.rotate(
                      angle: _box1Rotation.value,
                      child: Opacity(
                        opacity: _box1Opacity.value,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(
                              _box1BorderRadius.value,
                            ),
                            border: Border.all(
                              color: Theme.of(
                                context,
                              ).primaryColor.withValues(alpha: 0.6),
                              width: 3,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              // Box 2 - Outer animated border
              AnimatedBuilder(
                animation: _box2Controller,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _box2Scale.value,
                    child: Transform.rotate(
                      angle: _box2Rotation.value,
                      child: Opacity(
                        opacity: _box2Opacity.value,
                        child: Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(
                              _box2BorderRadius.value,
                            ),
                            border: Border.all(
                              color: Theme.of(
                                context,
                              ).primaryColor.withValues(alpha: 0.4),
                              width: 4,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

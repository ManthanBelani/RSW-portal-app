import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationHelper {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  
  static bool _isInitialized = false;

  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosInit = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      
      const initSettings = InitializationSettings(
        android: androidInit,
        iOS: iosInit,
      );
      
      await _notificationsPlugin.initialize(initSettings);
      
      // Request permissions for Android
      if (Platform.isAndroid) {
        await _notificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.requestNotificationsPermission();
      }
      
      _isInitialized = true;
      print('Notification helper initialized successfully');
    } catch (e) {
      print('Error initializing notification helper: $e');
    }
  }

  static Future<void> showWelcomeNotification({
    required String firstName,
    required String lastName,
  }) async {
    try {
      await initialize(); // Ensure initialized
      
      const androidDetails = AndroidNotificationDetails(
        'login_channel',
        'Login Notifications',
        channelDescription: 'Notifications for successful login',
        importance: Importance.high,
        playSound: true,
        priority: Priority.high,
        showWhen: false,
        icon: '@mipmap/ic_launcher',
      );
      
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      
      await _notificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000, // Unique ID
        'Welcome !',
        'Hello $firstName $lastName, you\'re successfully logged in to RSW Portal',
        NotificationDetails(
          android: androidDetails,
          iOS: iosDetails,
        ),
        payload: 'login_success',
      );
      
      print('Welcome notification sent for $firstName $lastName');
    } catch (e) {
      print('Error showing welcome notification: $e');
    }
  }

  static Future<void> showSimpleNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      await initialize();
      
      const androidDetails = AndroidNotificationDetails(
        'general_channel',
        'General Notifications',
        channelDescription: 'General app notifications',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: false,
      );
      
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      
      await _notificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        NotificationDetails(
          android: androidDetails,
          iOS: iosDetails,
        ),
        payload: payload,
      );
      
      print('Notification sent: $title');
    } catch (e) {
      print('Error showing notification: $e');
    }
  }

  // Test method to show sample welcome notification
  static Future<void> showTestWelcomeNotification() async {
    await showWelcomeNotification(
      firstName: 'Mehul',
      lastName: 'Javia',
    );
  }
}
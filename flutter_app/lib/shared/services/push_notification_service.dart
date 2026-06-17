import 'dart:developer' as dev;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:dio/dio.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:krishi_vikas_ai/core/constants/app_constants.dart';

class PushNotificationService {
  PushNotificationService._();

  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  static Future<void> init(Dio dio) async {
    try {
      // 1. Request FCM permission
      final settings = await _fcm.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      dev.log('User granted FCM permission: ${settings.authorizationStatus}');

      // 2. Fetch and register token
      final token = await _fcm.getToken();
      if (token != null) {
        await _registerTokenWithBackend(dio, token);
      }

      // Listen to token refresh
      _fcm.onTokenRefresh.listen((newToken) async {
        await _registerTokenWithBackend(dio, newToken);
      });

      // 3. Handle Foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        dev.log('Got a message whilst in the foreground!');
        dev.log('Message data: ${message.data}');

        if (message.notification != null) {
          dev.log('Message also contained a notification: ${message.notification}');
          // Save alert to Hive local notification cache
          _saveAlertToHive(message);
        }
      });

      // 4. Handle background message clicks
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        dev.log('A new onMessageOpenedApp event was published!');
        // Router will navigate to relevant screen based on message details
      });
    } catch (e, stack) {
      dev.log('FCM Initialization failed', error: e, stackTrace: stack);
    }
  }

  static Future<void> _registerTokenWithBackend(Dio dio, String token) async {
    final settingsBox = Hive.box(AppConstants.settingsBox);
    final savedToken = settingsBox.get('fcm_token');

    if (savedToken == token) {
      dev.log('FCM Token unchanged. Skipping API registration.');
      return;
    }

    try {
      final response = await dio.post(
        '/push/register',
        data: {'token': token},
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        dev.log('FCM Token successfully registered to backend.');
        await settingsBox.put('fcm_token', token);
      }
    } catch (e, stack) {
      dev.log('Failed to register FCM token to backend', error: e, stackTrace: stack);
    }
  }

  static void _saveAlertToHive(RemoteMessage message) async {
    try {
      final alertsBox = await Hive.openBox('push_alerts');
      final alertData = {
        'id': message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
        'title': message.notification?.title ?? 'Alert',
        'body': message.notification?.body ?? '',
        'type': message.data['type'] ?? 'general',
        'timestamp': DateTime.now().toIso8601String(),
        'route': message.data['route'] ?? '',
      };
      await alertsBox.add(alertData);
    } catch (e, stack) {
      dev.log('Error caching alert to Hive', error: e, stackTrace: stack);
    }
  }
}

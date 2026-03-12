import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationsServices {
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// ---------------- INITIALIZE NOTIFICATIONS ----------------
  Future<void> initialiseNotification() async {
    const AndroidInitializationSettings androidInitializationSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: androidInitializationSettings);

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload != null) {
          debugPrint('Notification payload: ${response.payload}');
        }
      },
    );

    /// Request permission for Android 13+
    if (defaultTargetPlatform == TargetPlatform.android) {
      await _requestAndroidNotificationPermission();
    }
  }

  /// ---------------- REQUEST ANDROID PERMISSION ----------------
  Future<void> _requestAndroidNotificationPermission() async {
    final status = await Permission.notification.status;

    if (!status.isGranted) {
      await Permission.notification.request();
    }
  }

  /// ---------------- PENDING SYNC NOTIFICATION ----------------
  Future<void> showPendingSyncNotification() async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'sync_channel',
      'Sync Notifications',
      channelDescription: 'Notification for pending sync transactions',
      importance: Importance.max,
      priority: Priority.high,
      ongoing: true, // cannot swipe away
      autoCancel: false,
    );

    const NotificationDetails notificationDetails =
        NotificationDetails(android: androidDetails);

    await _flutterLocalNotificationsPlugin.show(
      99, // fixed notification ID
      'Pending Sync',
      'Naay pending wala pa ma sync. Turn on your WiFi to sync.',
      notificationDetails,
    );
  }

  /// ---------------- REMOVE PENDING NOTIFICATION ----------------
  Future<void> cancelPendingNotification() async {
    await _flutterLocalNotificationsPlugin.cancel(99);
  }

  /// ---------------- TEST NOTIFICATION ----------------
  Future<void> sendNotification() async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'test_channel',
      'Test Notifications',
      channelDescription: 'Test notification channel',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      ticker: 'ticker',
    );

    const NotificationDetails notificationDetails =
        NotificationDetails(android: androidDetails);

    await _flutterLocalNotificationsPlugin.show(
      0,
      'From: Marlu',
      'To: Honey, I love you <3!',
      notificationDetails,
      payload: 'test_payload',
    );
  }
}
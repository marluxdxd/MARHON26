import 'dart:async';
import 'package:cashier/database/local_db.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationsServices {
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  final LocalDatabase localDb = LocalDatabase();

  Timer? _periodicTimer;

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

    // Request permission for Android 13+
    if (defaultTargetPlatform == TargetPlatform.android) {
      await _requestAndroidNotificationPermission();
    }

    // Start periodic notifications every 1 minute
    _startPeriodicNotifications();
  }

  Future<void> _requestAndroidNotificationPermission() async {
    final status = await Permission.notification.status;
    if (!status.isGranted) {
      await Permission.notification.request();
    }
  }

  /// ---------------- LOW STOCK ----------------
  Future<void> showLowStockNotification() async {
    final lowStockProducts = await localDb.getLowStockProducts();
    if (lowStockProducts.isEmpty) return; // nothing to notify

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'lowstock_channel',
      'Low Stock Notifications',
      channelDescription: 'Notification for products low in stock',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      ticker: 'Low stock alert',
    );

    const NotificationDetails notificationDetails =
        NotificationDetails(android: androidDetails);

    await _flutterLocalNotificationsPlugin.show(
      100,
      'Low Stock Alert',
      '${lowStockProducts.length} products are low on stock',
      notificationDetails,
      payload: 'low_stock',
    );
  }

  /// ---------------- MISSING BARCODE ----------------
  Future<void> showMissingBarcodeNotification() async {
    final noBarcodeProducts = await localDb.getProductsWithoutBarcode();
    if (noBarcodeProducts.isEmpty) return;

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'barcode_channel',
      'Missing Barcode Notifications',
      channelDescription: 'Notification for products without barcode',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      ticker: 'Missing barcode alert',
    );

    const NotificationDetails notificationDetails =
        NotificationDetails(android: androidDetails);

    await _flutterLocalNotificationsPlugin.show(
      101,
      'Missing Barcode',
      '${noBarcodeProducts.length} products do not have a barcode yet',
      notificationDetails,
      payload: 'missing_barcode',
    );
  }

  /// ---------------- SHOW ALL ----------------
  Future<void> showAllNotifications() async {
    await showLowStockNotification();
    await showMissingBarcodeNotification();
  }

  /// ---------------- PERIODIC NOTIFICATIONS ----------------
  void _startPeriodicNotifications() {
    _periodicTimer?.cancel();

    _periodicTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) async {
        try {
          await showAllNotifications();
        } catch (e) {
          debugPrint('Error sending periodic notifications: $e');
        }
      },
    );
  }

  /// ---------------- CANCEL ALL NOTIFICATIONS ----------------
  Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
    _periodicTimer?.cancel();
  }

  /// ---------------- INSTANCE METHOD FOR HOME BADGE ----------------
  Future<int> getNotificationCount() async {
    int count = 0;

    final pending = await localDb.getPendingTransactions();
    if (pending.isNotEmpty) count++;

    final lowStock = await localDb.getLowStockProducts();
    if (lowStock.isNotEmpty) count++;

    final noBarcode = await localDb.getProductsWithoutBarcode();
    if (noBarcode.isNotEmpty) count++;

    return count;
  }

  Future<void> showPendingSyncNotification() async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'sync_channel',
      'Sync Notifications',
      channelDescription: 'Notification for pending sync transactions',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      ongoing: true,
      autoCancel: false,
      ticker: 'Pending sync',
    );
  }
}
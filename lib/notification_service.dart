import 'dart:async';
import 'package:cashier/database/local_db.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationsServices {
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  final LocalDatabase localDb = LocalDatabase();

  Timer? _lowStockTimer;
  Timer? _barcodeTimer;
  Timer? _pendingSyncTimer;

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

    /// Android 13+ permission
    if (defaultTargetPlatform == TargetPlatform.android) {
      await _requestAndroidNotificationPermission();
    }

    /// Create chat notification channel
    await createChatChannel();

    /// Start periodic checks
    _startPeriodicNotifications();
  }

  /// ---------------- ANDROID 13 PERMISSION ----------------
  Future<void> _requestAndroidNotificationPermission() async {
    final status = await Permission.notification.status;
    if (!status.isGranted) {
      await Permission.notification.request();
    }
  }

  /// ---------------- CHAT NOTIFICATION CHANNEL ----------------
 Future<void> createChatChannel() async {
  const channel = AndroidNotificationChannel(
    'chat_channel', // id
    'Chat Messages', // name
    description: 'Notifications for new chat messages', // description
    importance: Importance.max,
    playSound: true,
  );

  await _flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);
}

  /// ---------------- CHAT MESSAGE NOTIFICATION ----------------
  Future<void> showChatNotification({
  required String messageId,
  required String content,
}) async {
  const androidDetails = AndroidNotificationDetails(
    'chat_channel',
    'Chat Messages',
    channelDescription: 'New chat messages',
    importance: Importance.max,
    priority: Priority.high,
    playSound: true,
  );

  const notificationDetails = NotificationDetails(android: androidDetails);

  await _flutterLocalNotificationsPlugin.show(
    int.parse(messageId.hashCode.toString().substring(0, 7)), // unique ID
    'New Message',
    content,
    notificationDetails,
    payload: 'chat_message',
  );
}

  /// ---------------- LOW STOCK ----------------
  Future<void> showLowStockNotification() async {
    final lowStockProducts = await localDb.getLowStockProducts();

    if (lowStockProducts.isEmpty) return;

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

  /// ---------------- PENDING SYNC ----------------
  Future<void> showPendingSyncNotification() async {
    final pending = await localDb.getPendingTransactions();

    if (pending.isEmpty) return;

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'sync_channel',
      'Sync Notifications',
      channelDescription: 'Notification for pending sync transactions',
      importance: Importance.max,
      priority: Priority.high,
      ongoing: true,
      autoCancel: false,
    );

    const NotificationDetails notificationDetails =
        NotificationDetails(android: androidDetails);

    await _flutterLocalNotificationsPlugin.show(
      99,
      'Pending Sync',
      'Naay pending wala pa ma sync. Turn on your WiFi to sync.',
      notificationDetails,
      payload: 'pending_sync',
    );
  }

  /// ---------------- PERIODIC TIMERS ----------------
  void _startPeriodicNotifications() {
    _lowStockTimer?.cancel();
    _barcodeTimer?.cancel();
    _pendingSyncTimer?.cancel();

    /// LOW STOCK → every 1 hour
    _lowStockTimer = Timer.periodic(const Duration(hours: 1), (_) async {
      try {
        await showLowStockNotification();
      } catch (e) {
        debugPrint('Low stock notification error: $e');
      }
    });

    /// MISSING BARCODE → every 2 hours
    _barcodeTimer = Timer.periodic(const Duration(hours: 1), (_) async {
      try {
        await showMissingBarcodeNotification();
      } catch (e) {
        debugPrint('Missing barcode notification error: $e');
      }
    });

    /// PENDING SYNC → every 30 minutes
    _pendingSyncTimer = Timer.periodic(const Duration(hours: 1), (_) async {
      try {
        await showPendingSyncNotification();
      } catch (e) {
        debugPrint('Pending sync notification error: $e');
      }
    });
  }

  /// ---------------- CANCEL ALL ----------------
  Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();

    _lowStockTimer?.cancel();
    _barcodeTimer?.cancel();
    _pendingSyncTimer?.cancel();
  }

  /// ---------------- SHOW ALL ----------------
  Future<void> showAllNotifications() async {
    await showLowStockNotification();
    await showMissingBarcodeNotification();
  }

  /// ---------------- BADGE COUNT FOR HOME ----------------
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
}
// lib/background_callback.dart
import 'package:cashier/notification_service.dart';

@pragma('vm:entry-point')
void periodicNotificationCallback() async {
  final notifications = NotificationsServices();
  await notifications.initialiseNotification();
  await notifications.showAllNotifications();
}
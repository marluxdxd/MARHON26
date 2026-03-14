import 'package:cashier/database/local_db.dart';
import 'package:cashier/view/low_stock_page.dart';
import 'package:flutter/material.dart';

class NotificationItem {
  final IconData icon;
  final Color color;
  final String title;
  final String message;

  NotificationItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
  });
}

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final LocalDatabase localDb = LocalDatabase();

  List<NotificationItem> notifications = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadNotifications();
  }

  Future<void> loadNotifications() async {
    try {
      List<NotificationItem> items = [];

      // Pending Sync Transactions
      final pendingTransactions = await localDb.getPendingTransactions();
      if (pendingTransactions.isNotEmpty) {
        items.add(
          NotificationItem(
            icon: Icons.sync_problem,
            color: Colors.orange,
            title: "Pending Sync",
            message:
                "${pendingTransactions.length} transactions waiting to sync. Turn on WiFi.",
          ),
        );
      }

      // Low Stock Products
      final lowStockProducts = await localDb.getLowStockProducts();
      if (lowStockProducts.isNotEmpty) {
        items.add(
          NotificationItem(
            icon: Icons.warning,
            color: Colors.red,
            title: "Low Stock Alert",
            message: "${lowStockProducts.length} products are low on stock.",
          ),
        );
      }

      // Products Without Barcode
      final noBarcodeProducts = await localDb.getProductsWithoutBarcode();
      if (noBarcodeProducts.isNotEmpty) {
        items.add(
          NotificationItem(
            icon: Icons.qr_code_2,
            color: Colors.blue,
            title: "Missing Barcode",
            message:
                "${noBarcodeProducts.length} products do not have a barcode yet.",
          ),
        );
      }

      if (!mounted) return;

      setState(() {
        notifications = items;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
      });

      debugPrint("Error loading notifications: $e");
    }
  }

  Future<void> refreshNotifications() async {
    setState(() {
      loading = true;
    });

    await loadNotifications();
  }

  void handleNotificationTap(NotificationItem notif) {
    if (notif.title == "Low Stock Alert") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const LowStockPage(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifications"),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : notifications.isEmpty
              ? const Center(child: Text("No notifications"))
              : RefreshIndicator(
                  onRefresh: refreshNotifications,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: notifications.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (context, index) {
                      final notif = notifications[index];

                      return ListTile(
                        onTap: () => handleNotificationTap(notif),
                        leading: CircleAvatar(
                          backgroundColor: notif.color.withAlpha(40),
                          child: Icon(
                            notif.icon,
                            color: notif.color,
                          ),
                        ),
                        title: Text(
                          notif.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(notif.message),
                      );
                    },
                  ),
                ),
    );
  }
}
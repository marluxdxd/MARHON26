import 'package:cashier/database/local_db.dart';
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

    List<NotificationItem> items = [];

    /// ---------------- PENDING SYNC ----------------
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

    /// ---------------- LOW STOCK ----------------
    final lowStockProducts = await localDb.getLowStockProducts();

    if (lowStockProducts.isNotEmpty) {
      items.add(
        NotificationItem(
          icon: Icons.warning,
          color: Colors.red,
          title: "Low Stock Alert",
          message:
              "${lowStockProducts.length} products are low on stock.",
        ),
      );
    }

    if (mounted) {
      setState(() {
        notifications = items;
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text("Message"),
      ),

      body: loading
          ? const Center(child: CircularProgressIndicator())
          : notifications.isEmpty
              ? const Center(
                  child: Text(
                    "No notifications",
                    style: TextStyle(fontSize: 16),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: notifications.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {

                    final notif = notifications[index];

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: notif.color.withOpacity(0.15),
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
    );
  }
}
import 'package:cashier/screens/debug_db_screen.dart';
import 'package:cashier/view/history_stock_screen.dart';
import 'package:cashier/view/reports_file/sales_reports_screen.dart';
import 'package:cashier/view/stock_screnn.dart';
import 'package:flutter/material.dart';





// Main ProfileView
class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            
            // Profile Header
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              color: Colors.blue.shade100,
              width: double.infinity,
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: const AssetImage('assets/images/marhon.png'),
                    backgroundColor: Colors.grey.shade300,
                  ),
                  const Text(
                    "Honey",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "honey@gmail.com",
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      // Edit profile action
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text("Edit Profile"),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                   IconButton(
                  icon: const Icon(Icons.storage),
                  tooltip: "Open DB Debug",
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const DebugDbScreen(),
                      ),
                    );
                  },
                ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Stats Cards
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatCard("Orders", "0", Colors.orange),
                  _buildStatCard("Points", "0", Colors.green),
                  _buildStatCard("Wishlist", "0", Colors.purple),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Settings List
            Column(
              children: [
                _buildSettingsTile(
                  icon: Icons.inventory,
                  title: "Inventory",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => InventoryStock()),
                    );
                  },
                ),
                _buildSettingsTile(
                  icon: Icons.point_of_sale,
                  title: "Sales",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>  SalesNavigationScreen(),
                      ),
                    );
                  },
                ),
                _buildSettingsTile(
                  icon: Icons.history,
                  title: "History",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) =>  HistoryScreen()),
                    );
                  },
                ),

                _buildSettingsTile(
                  icon: Icons.settings,
                  title: "Settings",
                  onTap: () {},
                ),
                _buildSettingsTile(
                  icon: Icons.logout,
                  title: "Logout",
                  iconColor: Colors.red,
                  onTap: () {
                    // Logout action
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(color: Colors.black54)),
        ],
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    Color? iconColor,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? Colors.blue),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
}

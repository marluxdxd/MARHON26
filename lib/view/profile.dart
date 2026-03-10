import 'package:cashier/screens/debug_db_screen.dart';
import 'package:cashier/view/history_stock_screen.dart';
import 'package:cashier/view/login.dart';
import 'package:cashier/view/reports_file/sales_reports_screen.dart';
import 'package:cashier/view/stock_screnn.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileView extends StatelessWidget {
  final String role; // guest or master
  const ProfileView({super.key, required this.role});

  // LOGOUT FUNCTION
  Future<void> logout(BuildContext context) async {
    await Supabase.instance.client.auth.signOut();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isGuest = role == "guest";

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text("Profile"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Center(
          child: isGuest
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 80),
                    const Icon(Icons.logout, size: 100, color: Colors.red),
                    const SizedBox(height: 20),
                    const Text(
                      "Guest User",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 40),
                    ElevatedButton.icon(
                      onPressed: () => logout(context),
                      icon: const Icon(Icons.logout),
                      label: const Text("Logout"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 15,
                        ),
                      ),
                    ),
                  ],
                )
              : Column(
                  children: [
                    // PROFILE HEADER
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      color: Colors.blue.shade100,
                      width: double.infinity,
                      child: Column(
                        children: [
                          GestureDetector(
                            onLongPress: () async {
                              await Future.delayed(const Duration(seconds: 2));

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("I love you ❤️"),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                            child: CircleAvatar(
                              radius: 50,
                              backgroundImage: const AssetImage(
                                'assets/images/marhon.png',
                              ),
                              backgroundColor: Colors.grey.shade300,
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            "Honey",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            "honey@gmail.com",
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.edit),
                            label: const Text("Edit Profile"),
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
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

                    // STATS
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildStatCard("Kusog Halin", "0", Colors.orange),
                          _buildStatCard("Suki Person", "0", Colors.green),
                          _buildStatCard("Wishlist", "0", Colors.purple),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    // SETTINGS LIST
                    Column(
                      children: [
                        _buildSettingsTile(
                          icon: Icons.inventory,
                          title: "Inventory",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => InventoryStock(),
                              ),
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
                                builder: (_) => SalesNavigationScreen(),
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
                              MaterialPageRoute(
                                builder: (_) => HistoryScreen(),
                              ),
                            );
                          },
                        ),
                        _buildSettingsTile(
                          icon: Icons.settings,
                          title: "Settings",
                          onTap: () {},
                        ),
                        // LOGOUT BUTTON FOR MASTER
                        _buildSettingsTile(
                          icon: Icons.logout,
                          title: "Logout",
                          iconColor: Colors.red,
                          onTap: () {
                            logout(context);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  // STAT CARD
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

  // SETTINGS TILE
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

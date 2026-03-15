import 'package:cashier/screens/debug_db_screen.dart';
import 'package:cashier/sendmail/sendemail.dart';
import 'package:cashier/view/history_stock_screen.dart';
import 'package:cashier/view/login.dart';
import 'package:cashier/view/reports_file/sales_reports_screen.dart';
import 'package:cashier/view/stock_screnn.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  String userName = "User";
  String userEmail = "";
  String userRole = "user";
  bool isLoading = true;
  bool isClerk = false;

  @override
  void initState() {
    super.initState();
    fetchUserInfo();
  }

  /// Fetch user profile
  Future<void> fetchUserInfo() async {
    final currentUser = Supabase.instance.client.auth.currentUser;

    if (currentUser == null) {
      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
      return;
    }

    try {
      final profile = await Supabase.instance.client
          .from('profiles')
          .select('id, full_name, email, role')
          .eq('id', currentUser.id)
          .maybeSingle();

      if (!mounted) return;

      setState(() {
        userName = profile?['full_name'] ?? 'User';
        userEmail = profile?['email'] ?? '';
        userRole = profile?['role'] ?? 'user';
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching user info: $e");

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });
    }
  }

  /// TOTAL LOGOUT
  Future<void> logout(BuildContext context) async {
    try {
      await Supabase.instance.client.auth.signOut(
        scope: SignOutScope.global,
      );
    } catch (e) {
      debugPrint("Logout error: $e");
    }

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [

          /// HIDE/SHOW APPBAR
          SliverAppBar(
            floating: true,
            snap: true,
            pinned: false,
            backgroundColor: Colors.white,
            elevation: 0,
            automaticallyImplyLeading: false,
            title: const Text(
              "Profile",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                letterSpacing: -1,
              ),
            ),
          ),

          /// BODY
          SliverToBoxAdapter(
            child: Center(
              child: Column(
                children: [

                  /// PROFILE HEADER
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    color: Colors.blue.shade100,
                    width: double.infinity,
                    child: Column(
                      children: [
                        GestureDetector(
                          onLongPress: () async {
                            await Future.delayed(const Duration(seconds: 2));

                            if (!mounted) return;

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

                        Text(
                          userName,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          userEmail,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),

                        const SizedBox(height: 12),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.person),
                            const SizedBox(width: 8),
                            const Text(
                              "Clerk",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 12),

                            Switch(
                              value: isClerk,
                              activeColor: Colors.white,
                              activeTrackColor: Colors.blue,
                              inactiveThumbColor: Colors.white,
                              inactiveTrackColor: Colors.grey,
                              onChanged: (value) {
                                setState(() {
                                  isClerk = value;
                                });
                              },
                            )
                          ],
                        ),

                        const SizedBox(height: 10),
ElevatedButton(
  onPressed: () {
    sendEmail(
      to: 'ikam7247@gmail.com',
      subject: 'Test Email from Flutter',
      text: 'Hello! This is a test message from my app.',
    );
  },
  child: Text('Send Test Email'),
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

                  /// STATS
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

                  /// SETTINGS
                  Column(
                    children: [
                      _buildSettingsTile(
                        icon: Icons.inventory,
                        title: "Inventory",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => InventoryStock()),
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
                                builder: (_) => HistoryScreen()),
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
                        onTap: () => logout(context),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// STAT CARD
  Widget _buildStatCard(String title, String value, Color color) {
    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: color.withAlpha(40),
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

  /// SETTINGS TILE
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
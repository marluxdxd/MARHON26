import 'package:shared_preferences/shared_preferences.dart';

class Preferences {
  static const String keyLoginRole = "login_role";

  // Save role
  static Future<void> saveLoginRole(String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyLoginRole, role);
  }

  // Get role
  static Future<String?> getLoginRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(keyLoginRole);
  }

  // Clear role (for logout)
  static Future<void> clearLoginRole() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(keyLoginRole);
  }
}
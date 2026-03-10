import 'package:flutter/material.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;
  final String role; // guest or master

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
    required this.role,
  });

  Widget _bottomIconWithLabel(IconData icon, String label, int index) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onTabSelected(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 22,
            color: currentIndex == index ? Colors.blue : Colors.black,
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 8.5,
              color: currentIndex == index ? Colors.blue : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Determine the icon & label for the last tab (Profile)
    final bool isGuest = role == "guest";
    final IconData profileIcon = isGuest ? Icons.logout : Icons.person_2_outlined;
    final String profileLabel = isGuest ? "Logout" : "Profile";

    return BottomAppBar(
      color: Color(Colors.white.value + 0xFF000000), // fully opaque white
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      elevation: 8,
      child: SafeArea(
        child: SizedBox(
          height: 55,
          child: Row(
            children: [
              Expanded(child: _bottomIconWithLabel(Icons.home_outlined, "Home", 0)),
              Expanded(child: _bottomIconWithLabel(Icons.pending_actions_rounded, "Products", 1)),
              const Expanded(child: SizedBox()), // Space for FAB
              Expanded(child: _bottomIconWithLabel(Icons.bar_chart, "Transactions", 2)),
              Expanded(child: _bottomIconWithLabel(profileIcon, profileLabel, 3)),
            ],
          ),
        ),
      ),
    );
  }
}
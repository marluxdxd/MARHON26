import 'package:cashier/view/home.dart';
import 'package:cashier/view/productview.dart';
import 'package:flutter/material.dart';

class BottomNavBar extends StatefulWidget {
  const BottomNavBar({super.key});

  @override
  State<BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {

  // ---------------- Icon + Label ----------------
  Widget _bottomIconWithLabel(
      IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 22,
            color: Colors.black,
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      elevation: 8,
      child: SafeArea(
        child: SizedBox(
          height: 55,
          child: Row(
            children: [

              // HOME
              Expanded(
                child: _bottomIconWithLabel(
                  Icons.home_outlined,
                  "Home",
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const Home(),
                      ),
                    );
                  },
                ),
              ),

              // PRODUCT
              Expanded(
                child: _bottomIconWithLabel(
                  Icons.pending_actions_rounded,
                  "Product",
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const Productview(),
                      ),
                    );
                  },
                ),
              ),

              // SPACE FOR QR / FAB
              const Expanded(child: SizedBox()),

              // INVENTORY
              Expanded(
                child: _bottomIconWithLabel(
                  Icons.inventory_2_outlined,
                  "Inventory",
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const Productview(),
                      ),
                    );
                  },
                ),
              ),

              // PROFILE
              Expanded(
                child: _bottomIconWithLabel(
                  Icons.person_outline,
                  "Profile",
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const Productview(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
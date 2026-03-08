import 'package:cashier/view/home.dart';
import 'package:flutter/material.dart';

class BottomNavBar extends StatefulWidget {
  const BottomNavBar({super.key});

  @override
  State<BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {

  bool isAutoNextRowOn = true;
  bool isAutoAnimating = false;
  bool showAutoToggle = true;

  Widget _bottomIcon(IconData icon, VoidCallback onTap) {
    return IconButton(
      icon: Icon(icon, size: 26),
      onPressed: onTap,
    );
  }

  void toggleAuto() {
    setState(() {
      isAutoNextRowOn = !isAutoNextRowOn;
      isAutoAnimating = true;
    });

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() => isAutoAnimating = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 6,
      elevation: 8,
      child: SafeArea(
        child: SizedBox(
          height: 70,
          child: Stack(
            clipBehavior: Clip.none,
            children: [

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _bottomIcon(Icons.home, () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => Home(),
    ),
  );
}),
                  _bottomIcon(Icons.receipt_long, () {}),
                  const SizedBox(width: 40),
                  _bottomIcon(Icons.history, () {}),
                  const SizedBox(width: 40),
                ],
              ),

              if (showAutoToggle)
                Positioned(
                  right: 10,
                  bottom: 10,
                  child: GestureDetector(
                    onTap: toggleAuto,
                    child: AnimatedScale(
                      duration: const Duration(milliseconds: 200),
                      scale: isAutoAnimating ? 1.2 : 1.0,
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              isAutoNextRowOn ? "ON" : "OFF",
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isAutoNextRowOn
                                    ? Colors.red
                                    : Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Icon(
                              Icons.autorenew_outlined,
                              size: 20,
                              color: isAutoNextRowOn
                                  ? Colors.red
                                  : Colors.grey,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
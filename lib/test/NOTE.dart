//  // ---------------- Auto Toggle Button ----------------
//               // if (showAutoToggle)
//               //   Positioned(
//               //     right: 1,
//               //     bottom: 40,
//               //     child: GestureDetector(
//               //       onTap: toggleAuto,
//               //       child: AnimatedScale(
//               //         duration: const Duration(milliseconds: 200),
//               //         scale: isAutoAnimating ? 1.2 : 1.0,
//               //         child: Container(
//               //           width: 33, // smaller size for compact layout
//               //           height: 44,
//               //           decoration: BoxDecoration(
//               //             color: Colors.white,
//               //             shape: BoxShape.circle,
//               //             boxShadow: [
//               //               BoxShadow(
//               //                 color: Colors.black.withOpacity(0.2),
//               //                 blurRadius: 2,
//               //                 offset: const Offset(0, 2),
//               //               ),
//               //             ],
//               //           ),
//               //           child: Column(
//               //             mainAxisAlignment: MainAxisAlignment.center,
//               //             children: [
//               //               Text(
//               //                 isAutoNextRowOn ? "ON" : "OFF",
//               //                 style: TextStyle(
//               //                   fontSize: 1,
//               //                   fontWeight: FontWeight.bold,
//               //                   color: isAutoNextRowOn ? Colors.red : Colors.grey,
//               //                 ),
//               //               ),
//               //               const SizedBox(height: 2), 
//               //               Icon(
//               //                 Icons.autorenew_outlined,
//               //                 size: 18,
//               //                 color: isAutoNextRowOn ? Colors.red : Colors.grey,
//               //               ),
//               //             ],
//               //           ),
//               //         ),
//               //       ),
//               //     ),
//               //   ),
// import 'package:flutter/material.dart';

// class BottomNavBar extends StatelessWidget {

//   final int selectedIndex;
//   final Function(int) onItemTapped;

//   const BottomNavBar({
//     super.key,
//     required this.selectedIndex,
//     required this.onItemTapped,
//   });

//   Widget _buildItem(
//       IconData icon,
//       String label,
//       int index,
//       int selectedIndex,
//       Function(int) onTap,
//       ) {
//     final bool isActive = selectedIndex == index;

//     return Expanded(
//       child: InkWell(
//         onTap: () => onTap(index),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [

//             Icon(
//               icon,
//               size: 22,
//               color: isActive ? Colors.blue : Colors.black,
//             ),

//             const SizedBox(height: 3),

//             Text(
//               label,
//               style: TextStyle(
//                 fontSize: 11,
//                 color: isActive ? Colors.blue : Colors.black,
//               ),
//             )
//           ],
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {

//     return BottomAppBar(
//       shape: const CircularNotchedRectangle(),
//       notchMargin: 8,
//       elevation: 8,

//       child: SizedBox(
//         height: 60,

//         child: Row(
//           children: [

//             _buildItem(
//               Icons.home_outlined,
//               "Home",
//               0,
//               selectedIndex,
//               onItemTapped,
//             ),

//             _buildItem(
//               Icons.shopping_bag_outlined,
//               "Product",
//               1,
//               selectedIndex,
//               onItemTapped,
//             ),

//             const Expanded(child: SizedBox()),

//             _buildItem(
//               Icons.inventory_2_outlined,
//               "Inventory",
//               2,
//               selectedIndex,
//               onItemTapped,
//             ),

//             _buildItem(
//               Icons.person_outline,
//               "Profile",
//               3,
//               selectedIndex,
//               onItemTapped,
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }


//               //ARI SA NAKO GI BUTANG TONG AUTO ON-OFF (POS NEXT ROW)

//               //to be continued sa main_navigation.dart kay daghan na siya code and para dili maglibog
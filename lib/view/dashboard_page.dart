// import 'package:cashier/services/product_service.dart';
// import 'package:flutter/material.dart';

// class DashboardPage extends StatefulWidget {
//   const DashboardPage({super.key});
//   @override
//   State<DashboardPage> createState() => _DashboardPageState();
// }

// class _DashboardPageState extends State<DashboardPage> {
//   int lowStockCount = 0;

//   @override
//   void initState() {
//     super.initState();
//     updateLowStockCount();
//   }

//   Future<void> updateLowStockCount() async {
//     final products = await ProductService().getProducts();
//     int count = products.where((p) => p.stock <= p.lowStock && p.stock > 0).length;

//     setState(() {
//       lowStockCount = count;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Dashboard'),
//         actions: [
//           Stack(
//             children: [
//               IconButton(
//                 icon: const Icon(Icons.mail_outline_outlined, size: 30, color: Colors.black),
//                 onPressed: () {
//                   Navigator.pushNamed(context, "/profile").then((_) => updateLowStockCount());
//                 },
//               ),
//               if (lowStockCount > 0)
//                 Positioned(
//                   right: 6,
//                   top: 6,
//                   child: Container(
//                     padding: const EdgeInsets.all(2),
//                     decoration: BoxDecoration(
//                       color: Colors.red,
//                       borderRadius: BorderRadius.circular(10),
//                     ),
//                     constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
//                     child: Text(
//                       '$lowStockCount',
//                       style: const TextStyle(
//                         color: Colors.white,
//                         fontSize: 10,
//                         fontWeight: FontWeight.bold,
//                       ),
//                       textAlign: TextAlign.center,
//                     ),
//                   ),
//                 ),
//             ],
//           ),
//         ],
//       ),
//       body: const Center(child: Text("Dashboard Content")),
//     );
//   }
// }
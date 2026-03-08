// import 'dart:async';

// import 'package:cashier/class/pos_row_manager.dart';
// import 'package:cashier/class/posrowclass.dart';
// import 'package:cashier/class/productclass.dart';
// import 'package:cashier/services/barcode_scan_service.dart';
// import 'package:cashier/services/product_service.dart';
// import 'package:cashier/services/scan_mode.dart';
// import 'package:cashier/services/transaction_service.dart';
// import 'package:cashier/view/reports_file/monthlysales.dart';
// import 'package:cashier/widget/addproduct.dart';
// import 'package:cashier/widget/barcode_fab.dart';
// import 'package:cashier/widget/bottom_nav_bar.dart';
// import 'package:connectivity_plus/connectivity_plus.dart';
// import 'package:flutter/material.dart';
// import 'package:cashier/view/home.dart';
// import 'package:cashier/view/productview.dart';
// import 'package:internet_connection_checker/internet_connection_checker.dart';

// class MainNavigation extends StatefulWidget {
//   const MainNavigation({super.key});

//   @override
//   State<MainNavigation> createState() => _MainNavigationState();
// }

// class _MainNavigationState extends State<MainNavigation> {

//   List<Productclass> products = [];

//   bool isAutoNextRowOn = true;
//   bool isAutoAnimating = false;
//   bool isSyncing = false;
//   bool syncSuccess = false;
//   bool showAutoToggle = true;

//   int currentIndex = 0;

//   late POSRowManager posManager;
//   late List<Widget> pages;

//   final TransactionService transactionService = TransactionService();
//   final ProductService productService = ProductService();

//   StreamSubscription<ConnectivityResult>? _connectivityListener;
//   StreamSubscription<InternetConnectionStatus>? _listener;

//   void _updateUI() => setState(() {});

//   @override
//   void initState() {
//     super.initState();

//     /// initialize POS manager
//     posManager = POSRowManager(context);

//     /// initialize pages (NO CONST)
//     pages = [
//       Home(posManager: posManager),
//       const Productview(),
//       const AddProductPage(),
//       const MonthlySales(),
//     ];

//     /// listen product refresh
//     productService.productRefreshStream.listen((_) async {
//       await syncProducts();
//     });

//     /// sync on startup
//     _syncOnStartup();

//     /// initial product sync
//     syncProducts();

//     /// internet listener
//     _listener =
//         InternetConnectionChecker().onStatusChange.listen((status) async {
//       if (status == InternetConnectionStatus.connected) {
//         await productService.syncOfflineProducts();
//         await productService.syncOnlineProducts();
//         await transactionService.syncOfflineTransactions();
//         await syncProducts();
//       }
//     });

//     /// connectivity listener
//     _connectivityListener =
//         Connectivity().onConnectivityChanged.listen((status) {
//       if (status != ConnectivityResult.none) {
//         syncProducts();
//       }
//     });
//   }

//   Future<void> _syncOnStartup() async {
//     final online = await ProductService().isOnline1();

//     if (online) {
//       await ProductService().syncOnlineProducts();
//     }
//   }

//   Future<void> syncProducts() async {
//     if (!mounted) return;

//     setState(() {
//       isSyncing = true;
//       syncSuccess = false;
//       posManager.rows.clear();
//     });

//     try {
//       await productService.syncOfflineProducts();

//       products = await productService.getAllProducts();

//       /// build barcode cache
//       BarcodeScanService.buildBarcodeCache(products);

//       if (!mounted) return;

//       setState(() {
//         posManager.rows = [POSRow()];
//         syncSuccess = true;
//       });
//     } catch (e) {
//       print("Error during product sync: $e");
//     } finally {
//       if (!mounted) return;
//       setState(() {
//         isSyncing = false;
//       });
//     }
//   }

//   void _toggleAutoNextRow() {
//     setState(() {
//       isAutoNextRowOn = !isAutoNextRowOn;
//     });
//   }

//   void changeTab(int index) {
//     setState(() {
//       currentIndex = index;
//     });
//   }

//   @override
//   void dispose() {
//     _listener?.cancel();
//     _connectivityListener?.cancel();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(

//       /// PAGES
//       body: IndexedStack(
//         index: currentIndex,
//         children: pages,
//       ),

//       /// BOTTOM NAV
//       bottomNavigationBar: BottomNavBar(
//         selectedIndex: currentIndex,
//         onItemTapped: changeTab,
//       ),

//       /// BARCODE SCANNER
//       floatingActionButton: BarcodeFAB(
//         heroTag: "barcodeFAB",
//         onPressed: () {
//           BarcodeScanService.scanBarcode(
//             context: context,
//             products: products,
//             rows: posManager.rows,
//             isAutoNextRowOn: isAutoNextRowOn,
//             refreshUI: _updateUI,
//             mode: ScanMode.posSale,
//           );
//         },
//       ),

//       floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
//     );
//   }
// }
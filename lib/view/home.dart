import 'package:cashier/class/posrowclass.dart';
import 'package:cashier/database/local_db.dart';
import 'package:cashier/services/product_service.dart';
import 'package:cashier/services/transaction_service.dart';
import 'package:cashier/services/barcode_scan_service.dart';
import 'package:cashier/services/scan_mode.dart';
import 'package:cashier/widget/appdrawer.dart';
import 'package:cashier/class/pos_row_manager.dart';
import 'package:cashier/class/productclass.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'dart:async';
import 'package:cashier/widget/bottom_nav_bar.dart';

// ------------------ Helper Functions ------------------
String generateUniqueId({String prefix = "S"}) {
  return "$prefix${DateTime.now().millisecondsSinceEpoch}";
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  List<Productclass> products = [];
  bool isAutoNextRowOn = true; // default ON
  bool isAutoAnimating = false;
  bool isSyncing = false;
  bool syncSuccess = false;
  bool showAutoToggle = true;

  Widget _bottomIcon(IconData icon, VoidCallback onTap) {
    return IconButton(icon: Icon(icon, size: 26), onPressed: onTap);
  }

  StreamSubscription<InternetConnectionStatus>? _listener;
  StreamSubscription<ConnectivityResult>? _connectivityListener;

  TextEditingController customerCashController = TextEditingController();

  final TransactionService transactionService = TransactionService();
  final ProductService productService = ProductService();

  late POSRowManager posManager;

  @override
  void initState() {
    super.initState();
    posManager = POSRowManager(context);
    productService.productRefreshStream.listen((_) async {
  await syncProducts();
});
    _syncOnStartup();
    syncProducts();

    // Listen for internet connection changes
    _listener = InternetConnectionChecker().onStatusChange.listen((
      status,
    ) async {
      if (status == InternetConnectionStatus.connected) {
        await productService.syncOfflineProducts();
        await productService.syncOnlineProducts();
        await transactionService.syncOfflineTransactions();
        await syncProducts();
      }
    });

    _connectivityListener = Connectivity().onConnectivityChanged.listen((
      status,
    ) {
      if (status != ConnectivityResult.none) syncProducts();
    });
  }

  Future<void> _syncOnStartup() async {
    final online = await ProductService().isOnline1();
    if (online) {
      await ProductService().syncOnlineProducts();
    }
  }

  Future<void> syncProducts() async {
    if (!mounted) return;
for (var p in products) {
  print("${p.name} -> ${p.retailPrice}");
}
    setState(() {
      isSyncing = true;
      syncSuccess = false;
      posManager.rows.clear();
    });

    try {
    await productService.syncOfflineProducts();

products = await productService.getAllProducts();

BarcodeScanService.buildBarcodeCache(products);

if (!mounted) return;

setState(() {
  posManager.rows = [POSRow()];
  syncSuccess = true;
});
    } catch (e) {
      print("Error during product sync: $e");
    } finally {
      if (!mounted) return;
      setState(() => isSyncing = false);
    }
  }

  void _updateUI() => setState(() {});
  void _toggleAutoNextRow() =>
      setState(() => isAutoNextRowOn = !isAutoNextRowOn);

  @override
  void dispose() {
    _listener?.cancel();
    _connectivityListener?.cancel();
    customerCashController.dispose();
    super.dispose();
  }

  Widget _buildMainContent(Orientation orientation) {
    if (orientation == Orientation.portrait) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: posManager.rows.length,
                itemBuilder: (_, index) => posManager.buildRow(
                  posManager.rows[index],
                  index,
                  onUpdate: _updateUI,
                  isAutoNextRowOn: isAutoNextRowOn,
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Total Bill
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 5,
                    color: Colors.grey.withOpacity(0.2),
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Bill:',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "₱${posManager.totalBill.toStringAsFixed(2)}",
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // Cash Field
            TextField(
              controller: customerCashController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Customer Cash",
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) async {
                // Handle transaction logic here
              },
            ),
          ],
        ),
      );
    }

    // LANDSCAPE
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              children: [
                GestureDetector(
                  onTap: _toggleAutoNextRow,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isAutoNextRowOn ? Colors.red : Colors.black,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isAutoNextRowOn
                          ? "Auto Next Row: ON"
                          : "Auto Next Row: OFF",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                Expanded(
                  child: ListView.builder(
                    itemCount: posManager.rows.length,
                    itemBuilder: (_, index) => posManager.buildRow(
                      posManager.rows[index],
                      index,
                      onUpdate: _updateUI,
                      isAutoNextRowOn: isAutoNextRowOn,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),

          // RIGHT SIDE PAYMENT PANEL
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 20,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 5,
                        color: Colors.grey.withOpacity(0.2),
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Bill:',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "₱${posManager.totalBill.toStringAsFixed(2)}",
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: customerCashController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "Customer Cash",
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) async {
                    // Handle transaction logic here
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1.0,
        title: const Text('Sari2x Store'),
        centerTitle: true,
        actions: [
          if (isSyncing)
            const Padding(
              padding: EdgeInsets.all(12),
              child: CircularProgressIndicator(color: Colors.red),
            )
          else if (syncSuccess)
            const Padding(
              padding: EdgeInsets.all(12),
              child: Icon(Icons.check_circle, color: Colors.green, size: 30),
            ),
        ],
      ),
      drawer: Appdrawer(),

     // ------------------- GCASH STYLE BARCODE CENTER BUTTON -------------------
    floatingActionButton: Transform.translate(
        offset: const Offset(0, 22), // move slightly down if needed
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FloatingActionButton(
              backgroundColor: Colors.white,
              onPressed: () {
                BarcodeScanService.scanBarcode(
                  context: context,
                  products: products,
                  rows: posManager.rows,
                  isAutoNextRowOn: isAutoNextRowOn,
                  refreshUI: _updateUI,
                  mode: ScanMode.posSale,
                );
              },
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16), // rounded corners
                side: const BorderSide(
                  color: Colors.blue, // border color
                  width: 2,          // border thickness
                ),
              ),
              child: const Icon(Icons.qr_code_scanner_sharp, size: 30, color: Colors.black),
            ),
            const SizedBox(height: 4), // spacing between icon and text
            const Text(
              "Barcode",
              style: TextStyle(
                fontSize: 9,
              
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),


      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      bottomNavigationBar:  const BottomNavBar(),

      body: OrientationBuilder(
        builder: (context, orientation) {
          return _buildMainContent(orientation);
        },
      ),
    );
  }
}

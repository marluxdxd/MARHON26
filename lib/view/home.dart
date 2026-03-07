import 'package:cashier/database/local_db.dart';
import 'package:cashier/database/local_db_transactionpromo.dart';
import 'package:cashier/screens/debug_db_screen.dart';
import 'package:cashier/services/product_service.dart';
import 'package:cashier/services/scan_mode.dart';
import 'package:cashier/services/transaction_promo_service.dart';
import 'package:cashier/services/transaction_service.dart';
import 'package:cashier/utils.dart';
import 'package:cashier/view/barcode.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:cashier/class/posrowclass.dart';
import 'package:cashier/widget/sukli.dart';
import 'package:cashier/widget/appdrawer.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'dart:async';
import '../class/pos_row_manager.dart';
import 'package:cashier/services/barcode_scan_service.dart';
import 'package:cashier/class/productclass.dart';

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
  bool isAutoNextRowOn = true; // default OFF
  bool isSyncingOnline = false;
  bool syncSuccess = false;
  StreamSubscription<InternetConnectionStatus>? _listener;
  StreamSubscription<ConnectivityResult>? _connectivityListener;

  // ----------------- Controllers & Services -----------------
  TextEditingController customerCashController = TextEditingController();
  final TransactionService transactionService = TransactionService();
  final ProductService productService = ProductService();

  bool isSyncing = false; // Loading indicator

  // ----------------- POS Manager -----------------
  late POSRowManager posManager;

  @override
  void initState() {
    super.initState();
    posManager = POSRowManager(context);
    testBarcode();

    // 🔹 Automatic sync on startup
    _syncOnStartup();

    // Sync offline products on init → this will also load all products
    syncProducts();

    // Listen for connection changes
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

  Future<void> testBarcode() async {
    final db = await LocalDatabase().database;

    final result = await db.query(
      'products',
      where: 'barcode = ?',
      whereArgs: ['740617261219'],
    );

    print("SQLITE RESULT: $result");
  }

  Future<void> _syncOnStartup() async {
    final online = await ProductService().isOnline1();
    if (online) {
      await ProductService().syncOnlineProducts();
    }
  }

  Future<void> scanBarcode() async {
    final barcode = await Navigator.push(
      context,
MaterialPageRoute(
  builder: (context) => BarcodeScannerPage(
    onBarcodeScanned: (barcode) {
      // handle scanned barcode here
    },
  ),
),
    );

    if (barcode != null) {
      print("Scanned: $barcode");

      // diri nimo pangitaon sa product list
    }
  }

  Future<void> syncProducts() async {
    if (!mounted) return;

    setState(() {
      isSyncing = true;
      syncSuccess = false;
      posManager.rows.clear();
    });

    try {
      await productService.syncOfflineProducts();

      products = await productService.getAllProducts();

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

  @override
  void dispose() {
    _listener?.cancel();
    _connectivityListener?.cancel();
    customerCashController.dispose();
    super.dispose();
  }

  void _updateUI() {
    setState(() {});
  }

  void _toggleAutoNextRow() {
    setState(() {
      isAutoNextRowOn = !isAutoNextRowOn;
    });
  }

  //------------------------------------------------------------
  @override
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
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.search, color: Colors.black, size: 30),
        ),
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.notifications, color: Colors.black, size: 30),
        ),
      ],
    ),
    drawer: Appdrawer(),

    /// AUTO DETECT ORIENTATION
    body: OrientationBuilder(
      builder: (context, orientation) {

        /// PORTRAIT LAYOUT (PHONE STYLE)
        if (orientation == Orientation.portrait) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [

                /// AUTO NEXT ROW BUTTON
                GestureDetector(
                  onTap: _toggleAutoNextRow,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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

                /// SCAN BUTTON
                ElevatedButton(
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
                  child: const Text("Scan Product"),
                ),

                const SizedBox(height: 10),

                /// POS ROWS
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

                /// TOTAL BILL
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

                const SizedBox(height: 10),

                /// CASH FIELD
                TextField(
                  controller: customerCashController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "Customer Cash",
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) async {

                    /// KEEP YOUR EXISTING TRANSACTION CODE HERE

                  },
                ),
              ],
            ),
          );
        }

        /// LANDSCAPE / TABLET LAYOUT
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [

              /// LEFT SIDE (ITEMS)
              Expanded(
                flex: 2,
                child: Column(
                  children: [

                    GestureDetector(
                      onTap: _toggleAutoNextRow,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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

                    ElevatedButton(
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
                      child: const Text("Scan Product"),
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

              /// RIGHT SIDE (PAYMENT PANEL)
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [

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

                        /// KEEP YOUR EXISTING TRANSACTION CODE HERE

                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}
}

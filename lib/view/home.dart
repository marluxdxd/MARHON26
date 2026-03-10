import 'package:cashier/view/lowstock.dart';
import 'package:flutter/material.dart';
import 'package:cashier/class/posrowclass.dart';
import 'package:cashier/class/pos_row_manager.dart';
import 'package:cashier/class/productclass.dart';
import 'package:cashier/widget/qtybottomsheet.dart';
import 'package:cashier/services/product_service.dart';
import 'package:cashier/services/transaction_service.dart';
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';


String generateUniqueId({String prefix = "S"}) {
  return "$prefix${DateTime.now().millisecondsSinceEpoch}";
}

class Home extends StatefulWidget {
  final POSRowManager posManager;
  final List<Productclass> products;
  final bool isAutoNextRowOn;
  final VoidCallback refreshUI;

  const Home({
    super.key,
    required this.posManager,
    required this.products,
    required this.isAutoNextRowOn,
    required this.refreshUI,
  });

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with SingleTickerProviderStateMixin {
  late POSRowManager posManager;
  late TabController _tabController;

  StreamSubscription<InternetConnectionStatus>? _listener;
  StreamSubscription<ConnectivityResult>? _connectivityListener;

  TextEditingController customerCashController = TextEditingController();
  final TransactionService transactionService = TransactionService();
  final ProductService productService = ProductService();

  @override
  void initState() {
    super.initState();
    posManager = widget.posManager;

    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));

    _listener = InternetConnectionChecker().onStatusChange.listen((status) async {
      if (status == InternetConnectionStatus.connected) {
        await productService.syncOfflineProducts();
        await productService.syncOnlineProducts();
        await transactionService.syncOfflineTransactions();
      }
    });

    _connectivityListener = Connectivity().onConnectivityChanged.listen((status) {});
  }

  @override
  void dispose() {
    _listener?.cancel();
    _connectivityListener?.cancel();
    customerCashController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _updateUI() => setState(() {});

  // ============================
  // POS TAB
  // ============================
  Widget _buildPOSTab() {
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        children: [
          // POS Rows container nga flexible + scrollable
          Flexible(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: posManager.rows.length,
              itemBuilder: (_, index) {
                final row = posManager.rows[index];
                return Container(
                  color: Colors.blue, // blue background sa row + gap
                  child: posManager.buildRow(
                    row,
                    index,
                    onUpdate: _updateUI,
                    isAutoNextRowOn: widget.isAutoNextRowOn,
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 10),

          // Total Bill + Customer Cash Section
          isLandscape
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _totalBillWidget()),
                    const SizedBox(width: 10),
                    Expanded(child: _customerCashWidget()),
                  ],
                )
              : Column(
                  children: [
                    _totalBillWidget(),
                    const SizedBox(height: 10),
                    _customerCashWidget(),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _totalBillWidget() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.blue),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Total Bill:',
            style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 18, color: Colors.blue),
          ),
          Text(
            "₱${posManager.totalBill.toStringAsFixed(2)}",
            style: const TextStyle(
                color: Colors.blue,
                fontWeight: FontWeight.bold,
                fontSize: 18),
          ),
        ],
      ),
    );
  }

  Widget _customerCashWidget() {
    return TextField(
      controller: customerCashController,
      keyboardType: TextInputType.number,
      style: const TextStyle(
        color: Colors.blue,
        fontWeight: FontWeight.bold,
      ),
      decoration: InputDecoration(
        labelText: "Customer Cash",
        labelStyle: const TextStyle(color: Colors.blue),
        border: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.blue),
          borderRadius: BorderRadius.circular(8),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.blue),
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.blue, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  // ============================
  // CUSTOM TAB WIDGET
  // ============================
  Widget _buildCustomTab(String text, int index) {
    bool selected = _tabController.index == index;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: selected ? Colors.blue : Colors.transparent,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(5),
          topRight: Radius.circular(5),
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: TextStyle(
          color: selected ? Colors.white : Colors.blue,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // ============================
  // BUILD HOME
  // ============================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.storefront_sharp, size: 40, color: Colors.blue),
            SizedBox(width: 4),
            Text(
              'Palit na Barato Ra',
              style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                  fontSize: 13),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.mail_outline_outlined,
                size: 30, color: Colors.black),
            onPressed: () {
              Navigator.pushNamed(context, "/profile")
                  .then((_) => widget.refreshUI());
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(40),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _tabController.animateTo(0),
                    child: _buildCustomTab("Palit na!", 0),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _tabController.animateTo(1),
                    child: _buildCustomTab("Low Stock", 1),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        physics: const NeverScrollableScrollPhysics(), // disable swipe
        children: [
          _buildPOSTab(),
          LowStock(products: widget.products), // LowStock as tab
        ],
      ),
    );
  }
}
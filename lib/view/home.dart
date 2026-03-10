import 'package:cashier/class/posrowclass.dart';
import 'package:cashier/database/local_db.dart';
import 'package:cashier/database/local_db_transactionpromo.dart';
import 'package:cashier/services/product_service.dart';
import 'package:cashier/services/transaction_promo_service.dart';
import 'package:cashier/services/transaction_service.dart';
import 'package:cashier/utils.dart';
import 'package:cashier/class/pos_row_manager.dart';
import 'package:cashier/class/productclass.dart';
import 'package:cashier/widget/qtybottomsheet.dart';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'dart:async';

// ------------------ Helper ------------------
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

  bool isSyncingOnline = false;
  bool isSyncing = false;
  bool syncSuccess = false;

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
    _tabController.addListener(() {
      setState(() {}); // rebuild to update tab colors
    });

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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: posManager.rows.length,
              itemBuilder: (_, index) => posManager.buildRow(
                posManager.rows[index],
                index,
                onUpdate: _updateUI,
                isAutoNextRowOn: widget.isAutoNextRowOn,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.grey),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Bill:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                Text(
                  "₱${posManager.totalBill.toStringAsFixed(2)}",
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: customerCashController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: "Customer Cash",
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }

  // ============================
  // LOW STOCK TAB
  // ============================
  Widget _buildLowStockTab() {
    final lowStockProducts = widget.products.where((p) => p.stock <= 3).toList();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemCount: lowStockProducts.length,
      itemBuilder: (context, index) {
        final product = lowStockProducts[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: ListTile(
            title: Text(product.name),
            subtitle: Text("Stock: ${product.stock}"),
            trailing: Text("₱${product.retailPrice.toStringAsFixed(2)}"),
            onTap: () async {
              final qty = await showModalBottomSheet<int>(
                context: context,
                builder: (_) => Qtybottomsheet(stock: product.stock),
              );

              if (qty != null) {
                final row = posManager.rows.firstWhere(
                  (r) => r.product == null,
                  orElse: () {
                    posManager.addEmptyRow();
                    return posManager.rows.last;
                  },
                );
                row.product = product;
                row.qty = qty;
                row.otherQty = product.otherQty;
                _updateUI();
              }
            },
          ),
        );
      },
    );
  }

  // ============================
  // CUSTOM TAB WIDGET
  // ============================
  Widget _buildCustomTab(String text, int index) {
    bool selected = _tabController.index == index;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
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
          color: selected ? Colors.white : Colors.black,
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
            Icon(Icons.storefront_sharp, size: 40, color: Colors.black),
            SizedBox(width: 4),
            Text(
              'Barato',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.mail_outline_outlined, size: 30, color: Colors.black),
            onPressed: () {
              Navigator.pushNamed(context, "/profile").then((_) => widget.refreshUI());
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _tabController.animateTo(0),
                    child: _buildCustomTab("POS", 0),
                  ),
                ),
                const SizedBox(width: 8),
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
        children: [
          _buildPOSTab(),
          _buildLowStockTab(),
        ],
      ),
    );
  }
}
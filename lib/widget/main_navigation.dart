import 'package:cashier/class/pos_row_manager.dart';
import 'package:cashier/class/posrowclass.dart';
import 'package:cashier/class/productclass.dart';
import 'package:cashier/services/barcode_scan_service.dart';
import 'package:cashier/services/product_service.dart';
import 'package:cashier/services/scan_mode.dart';
import 'package:cashier/view/home.dart';
import 'package:cashier/view/productview.dart';
import 'package:cashier/view/profile.dart';
import 'package:cashier/view/transaction_history.dart';
import 'package:cashier/widget/barcode_fab.dart';
import 'package:flutter/material.dart';

import 'bottom_nav_bar.dart';

class MainNav extends StatefulWidget {
  const MainNav({super.key});

  @override
  State<MainNav> createState() => _MainNavState();
}

class _MainNavState extends State<MainNav> {
  int _currentIndex = 0;

  List<Productclass> products = [];

  late POSRowManager posManager;

  bool isAutoNextRowOn = true;

  void _updateUI() => setState(() {});

  @override
  void initState() {
    super.initState();
    posManager = POSRowManager(context);
    syncProducts();
  }

  Future<void> syncProducts() async {
    setState(() {
      posManager.rows.clear();
    });

    try {
      products = await ProductService().getAllProducts();

      BarcodeScanService.buildBarcodeCache(products);

      setState(() {
        posManager.rows = [POSRow()];
      });
    } catch (e) {
      print("Error syncing products: $e");
    }
  }

  void _handleTabChange(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      resizeToAvoidBottomInset: true,

      body: IndexedStack(
        index: _currentIndex,
        children: [
          /// HOME
          Home(
            posManager: posManager,
            products: products,
            isAutoNextRowOn: isAutoNextRowOn,
            refreshUI: _updateUI,
          ),

          /// PRODUCT VIEW
          Productview(),

          /// TRANSACTION HISTORY
          TransactionHistoryScreen(),

          /// PROFILE
          ProfileView(),
        ],
      ),

      floatingActionButton: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: isKeyboardOpen ? 0 : 1,
        child: MediaQuery.removeViewInsets(
          removeBottom: true,
          context: context,
          child: BarcodeFAB(
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
          ),
        ),
      ),

      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTabSelected: _handleTabChange,
        role: "user",
      ),
    );
  }
}

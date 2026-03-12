import 'package:cashier/services/connectivity_service.dart';
import 'package:cashier/services/product_service.dart';
import 'package:cashier/services/stock_history_sync.dart';
import 'package:cashier/services/transaction_promo_service.dart';
import 'package:cashier/services/transaction_service.dart';
import 'package:cashier/services/transactionitem_service.dart';
import 'package:cashier/utils/preferences.dart';
import 'package:cashier/view/login.dart';
import 'package:cashier/widget/main_navigation.dart';
import 'package:cashier/view/home.dart';
import 'package:flutter/material.dart';
import 'package:cashier/database/supabase.dart';
import 'package:cashier/database/local_db.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase and local DB
  await SupabaseConfig.initialize();
  await LocalDatabase().database;
  final localDb = LocalDatabase();

  // Print all local transactions (optional)
  await localDb.printAllTransactions();
  await localDb.printAllTransactionItems();

  // Initialize services
  final productService = ProductService();
  final transactionService = TransactionService();
  final transactionItemService = TransactionItemService();
  final stockHistoryService = StockHistorySyncService();
  final transactionPromoService = TransactionPromoService();

  // Initialize connectivity listener
  ConnectivityService(
    productService: productService,
    transactionService: transactionService,
    transactionItemService: transactionItemService,
    stockHistorySyncService: stockHistoryService,
    transactionPromoService: transactionPromoService,
  );

  // **CHECK SAVED LOGIN ROLE**
  String? savedRole = await Preferences.getLoginRole();

  // Run app with initial role
  runApp(MyApp(initialRole: savedRole));
}

class MyApp extends StatelessWidget {
  final String? initialRole; // Accept saved role
  const MyApp({super.key, this.initialRole});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      // If there's a saved role, go directly to MainNav. Otherwise, show LoginScreen
      home: initialRole != null
          ? MainNav(role: initialRole!)
          : const LoginScreen(),
    );
  }
}
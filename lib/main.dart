import 'package:flutter/material.dart';

import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:cashier/view/login.dart';
import 'package:cashier/widget/main_navigation.dart';
import 'package:cashier/utils/preferences.dart';
import 'package:cashier/database/local_db.dart';
import 'package:cashier/database/supabase.dart';
import 'package:cashier/services/connectivity_service.dart';
import 'package:cashier/services/product_service.dart';
import 'package:cashier/services/transaction_service.dart';
import 'package:cashier/services/transactionitem_service.dart';
import 'package:cashier/services/stock_history_sync.dart';
import 'package:cashier/services/transaction_promo_service.dart';
import 'package:cashier/background_callback.dart';


@pragma('vm:entry-point')
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase and local DB
  await SupabaseConfig.initialize();
  await LocalDatabase().database;

  // Initialize Android Alarm Manager
  await AndroidAlarmManager.initialize();

  final productService = ProductService();
  final transactionService = TransactionService();
  final transactionItemService = TransactionItemService();
  final stockHistorySyncService = StockHistorySyncService();
  final transactionPromoService = TransactionPromoService();

  ConnectivityService(
    productService: productService,
    transactionService: transactionService,
    transactionItemService: transactionItemService,
    stockHistorySyncService: stockHistorySyncService,
    transactionPromoService: transactionPromoService,
  );

  // Schedule background ni kung minimize ang app or gi close ang app
  await AndroidAlarmManager.periodic(
    const Duration(minutes: 30),
    5, // unique alarm ID
    periodicNotificationCallback,
    wakeup: true,
    exact: true,
    rescheduleOnReboot: true,
  );

  // Check saved login role
  String? savedRole = await Preferences.getLoginRole();

  runApp(MyApp(initialRole: savedRole));
}

class MyApp extends StatelessWidget {
  final String? initialRole;
  const MyApp({super.key, this.initialRole});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: LoginScreen(),
    );
  }
}
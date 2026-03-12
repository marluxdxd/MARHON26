import 'package:cashier/class/posrowclass.dart';
import 'package:cashier/database/local_db.dart';
import 'package:cashier/database/local_db_transactionpromo.dart';
import 'package:cashier/notification_service.dart';
import 'package:cashier/services/product_service.dart';
import 'package:cashier/services/transaction_promo_service.dart';
import 'package:cashier/services/transaction_service.dart';
import 'package:cashier/utils.dart';
import 'package:cashier/class/pos_row_manager.dart';
import 'package:cashier/class/productclass.dart';
import 'package:cashier/widget/sukli.dart';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'dart:async';
import 'package:uuid/uuid.dart';

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

class _HomeState extends State<Home> {
  final NotificationsServices notificationsServices = NotificationsServices();

  late POSRowManager posManager;

  StreamSubscription<InternetConnectionStatus>? _listener;
  StreamSubscription<ConnectivityResult>? _connectivityListener;

  TextEditingController customerCashController = TextEditingController();

  final TransactionService transactionService = TransactionService();
  final ProductService productService = ProductService();
  
  bool isSyncingOnline = false;

  @override
  void initState() {
    super.initState();

    posManager = widget.posManager;

    notificationsServices.initialiseNotification();

    _listener =
        InternetConnectionChecker().onStatusChange.listen((status) async {
      if (status == InternetConnectionStatus.connected) {
        await productService.syncOfflineProducts();
        await productService.syncOnlineProducts();
        await transactionService.syncOfflineTransactions();
      }
    });

    _connectivityListener =
        Connectivity().onConnectivityChanged.listen((status) {});
  }

  void _updateUI() => setState(() {});

  @override
  void dispose() {
    _listener?.cancel();
    _connectivityListener?.cancel();
    customerCashController.dispose();
    super.dispose();
  }

  Widget _buildMainContent() {
    double padding = 16;
    double fontSizeTitle = 20;
    double fontSizeValue = 20;

    return Padding(
      padding: EdgeInsets.all(padding),
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: widget.posManager.rows.length,
              itemBuilder: (_, index) => widget.posManager.buildRow(
                widget.posManager.rows[index],
                index,
                onUpdate: _updateUI,
                isAutoNextRowOn: widget.isAutoNextRowOn,
              ),
            ),
          ),

          const SizedBox(height: 10),

          Container(
            padding: EdgeInsets.symmetric(
              vertical: padding,
              horizontal: padding,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Total Bill:',
                  style: TextStyle(
                    fontSize: fontSizeTitle,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  " ₱${widget.posManager.totalBill.toStringAsFixed(2)}",
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: fontSizeValue,
                    fontWeight: FontWeight.bold,
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
              onSubmitted: (_) async {
                if (isSyncingOnline) return;

                final localDbPromo = LocalDbTransactionpromo();
                final double finalTotal = widget.posManager.totalBill;
                double cash = double.tryParse(customerCashController.text) ?? 0;

                if (!transactionService.isCashSufficient(finalTotal, cash)) {
                  print("Cash is not enough yet.");
                  return;
                }

                setState(() => isSyncingOnline = true);

                final bool online =
                    await InternetConnectionChecker().hasConnection;

                final localDb = LocalDatabase();
                double change = transactionService.calculateChange(
                  finalTotal,
                  cash,
                );
                String timestamp = getPhilippineTimestampFormatted();

                // ---------------- COMBINE SAME PRODUCTS ----------------
                final Map<int, POSRow> combinedItems = {};

                for (final row in widget.posManager.rows) {
                  if (row.product == null) continue;

                  final product = row.product!;
                  final qty = row.isPromo ? row.otherQty : row.qty;

                  if (combinedItems.containsKey(product.id)) {
                    combinedItems[product.id]!.qty += qty;
                  } else {
                    combinedItems[product.id] = POSRow(
                      product: product,
                      qty: qty,
                      isPromo: row.isPromo,
                      otherQty: row.otherQty,
                    );
                  }
                }

                // ---------------- SAVE PROMO COUNTS PER PRODUCT ----------------
                final Map<int, int> savedPromoCounts = Map.from(
                  widget.posManager.promoCountByProduct,
                );

                // ---------------- SHOW UI IMMEDIATELY ----------------
                if (mounted) {
                  showDialog(
                    context: context,
                    builder: (_) => Sukli(change: change, timestamp: timestamp),
                  );
                  customerCashController.clear();
                  widget.posManager.reset2();
                  widget.posManager.reset();
                  _updateUI();
                }

                // ---------------- PROCESS TRANSACTION IN BACKGROUND ----------------
                unawaited(
                  Future(() async {
                    try {
                      final String clientUuid = const Uuid().v4();

                      final int localTransactionId = await localDb
                          .insertTransaction(
                            total: finalTotal,
                            cash: cash,
                            change: change,
                            createdAt: timestamp,
                            isSynced: online ? 1 : 0,
                            clientUuid: clientUuid,
                          );

                      int? onlineTransactionId;

                      if (online) {
                        onlineTransactionId = await transactionService
                            .saveTransaction(
                              total: finalTotal,
                              cash: cash,
                              change: change,
                              clientUuid: clientUuid,
                            );

                        await localDb.updateTransactionSupabaseId(
                          localId: localTransactionId,
                          supabaseId: onlineTransactionId,
                        );
                      }

                      // ✅ TRACK PROMO INSERT PER PRODUCT.ID
                      final Set<int> insertedPromoProducts = {};
                      final promoService = TransactionPromoService();
                      final futures = combinedItems.values.map((row) async {
                        final product = row.product!;
                        final qtySold = row.qty;

                        final promoCount = savedPromoCounts[product.id] ?? 0;

                        int? oldStock = await localDb.getProductStock(
                          product.id,
                        );

                        int newStock = oldStock != null
                            ? oldStock - qtySold
                            : 0;

                        await Future.wait([
                          // ---------------- INSERT PROMO (ONCE PER PRODUCT) ----------------
                          if (row.isPromo &&
                              promoCount > 0 &&
                              !insertedPromoProducts.contains(product.id))
                            () async {
                              insertedPromoProducts.add(product.id);

                              print(
                                '🔥 INSERT PROMO | tx:$localTransactionId '
                                'product:${product.id} count:$promoCount',
                              );
                              // Offline insert
                              await localDbPromo.insertTransactionPromo(
                                transactionId: localTransactionId,
                                productId: product.id,
                                productName: product.name,
                                promoCount: promoCount,
                                retailPrice: product.retailPrice,
                                isSynced: online ? 1 : 0,
                              );
                              // Online insert if connected
                              if (online && onlineTransactionId != null) {
                                await promoService.insertTransactionPromo(
                                  transactionId: onlineTransactionId,
                                  productId: product.id,
                                  productName: product.name,
                                  promoCount: promoCount,
                                  retailPrice: product.retailPrice,
                                );
                              }
                            }(),

                          // ---------------- INSERT TRANSACTION ITEM ----------------
                          localDb.insertTransactionItem(
                            transactionId: localTransactionId,
                            productId: product.id,
                            productName: product.name,
                            qty: qtySold,
                            retailPrice: product.retailPrice,
                            costPrice: product.costPrice,
                            isPromo: product.isPromo,
                            otherQty: product.otherQty,
                            productClientUuid: product.productClientUuid,
                          ),

                          if (oldStock != null)
                            localDb.updateProductStock(product.id, newStock),

                          if (oldStock != null)
                            localDb.insertStockHistory(
                              transactionId: localTransactionId,
                              id: generateUniqueId(prefix: "H").hashCode.abs(),
                              productId: product.id,
                              productName: product.name,
                              oldStock: oldStock,
                              qtyChanged: qtySold,
                              newStock: newStock,
                              type: 'SALE',
                              createdAt: timestamp,
                              synced: online ? 1 : 0,
                              productClientUuid: product.productClientUuid,
                            ),

                          localDb.insertStockUpdateQueue1(
                            productId: product.id,
                            qty: qtySold,
                            type: 'SALE',
                          ),

                          if (online && onlineTransactionId != null)
                            Future.wait([
                              productService.syncSingleProductOnline(
                                product.id,
                              ),
                              transactionService.saveTransactionItem(
                                transactionId: onlineTransactionId,
                                product: product,
                                qty: qtySold,
                                isPromo: product.isPromo,
                                otherQty: product.otherQty,
                              ),
                            ]),
                        ]);
                      }).toList();

                      await Future.wait(futures);

                      if (online) {
                        await productService.syncOnlineProducts();
                        await productService.syncOfflineStockHistory();
                        await productService.syncOfflineProducts();
                      }

                      print("✅ TRANSACTION SUCCESS");
                    } catch (e) {
                      print("❌ Error saving transaction: $e");
                    } finally {
                      if (mounted) {
                        setState(() => isSyncingOnline = false);
                      }
                    }
                  }),
                );
              },
            ),
        ],
      ),
    );
  }

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
            SizedBox(width: 5),
            Text(
              'Palit na! Barato pa',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),

        actions: [
          IconButton(
            icon: const Icon(
              Icons.mail_outline_outlined,
              size: 30,
              color: Colors.black,
            ),
            onPressed: () {
              Navigator.pushNamed(context, "/profile")
                  .then((_) => widget.refreshUI());
            },
          ),
        ],
      ),

      body: _buildMainContent(),
    );
  }
}
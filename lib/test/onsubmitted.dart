// onSubmitted: (_) async {
//                 if (isSyncingOnline) return;

//                 final localDbPromo = LocalDbTransactionpromo();
//                 final double finalTotal = posManager.totalBill;
//                 double cash = double.tryParse(customerCashController.text) ?? 0;

//                 if (!transactionService.isCashSufficient(finalTotal, cash)) {
//                   print("Cash is not enough yet.");
//                   return;
//                 }

//                 setState(() => isSyncingOnline = true);

//                 final bool online =
//                     await InternetConnectionChecker().hasConnection;

//                 final localDb = LocalDatabase();
//                 double change = transactionService.calculateChange(
//                   finalTotal,
//                   cash,
//                 );
//                 String timestamp = getPhilippineTimestampFormatted();

//                 // ---------------- COMBINE SAME PRODUCTS ----------------
//                 final Map<int, POSRow> combinedItems = {};

//                 for (final row in posManager.rows) {
//                   if (row.product == null) continue;

//                   final product = row.product!;
//                   final qty = row.isPromo ? row.otherQty : row.qty;

//                   if (combinedItems.containsKey(product.id)) {
//                     combinedItems[product.id]!.qty += qty;
//                   } else {
//                     combinedItems[product.id] = POSRow(
//                       product: product,
//                       qty: qty,
//                       isPromo: row.isPromo,
//                       otherQty: row.otherQty,
//                     );
//                   }
//                 }

//                 // ---------------- SAVE PROMO COUNTS PER PRODUCT ----------------
//                 final Map<int, int> savedPromoCounts = Map.from(
//                   posManager.promoCountByProduct,
//                 );

//                 // ---------------- SHOW UI IMMEDIATELY ----------------
//                 if (mounted) {
//                   showDialog(
//                     context: context,
//                     builder: (_) => Sukli(change: change, timestamp: timestamp),
//                   );
//                   customerCashController.clear();
//                   posManager.reset2();
//                   posManager.reset();
//                   _updateUI();
//                 }

//                 // ---------------- PROCESS TRANSACTION IN BACKGROUND ----------------
//                 unawaited(
//                   Future(() async {
//                     try {
//                       final String clientUuid = const Uuid().v4();

//                       final int localTransactionId = await localDb
//                           .insertTransaction(
//                             total: finalTotal,
//                             cash: cash,
//                             change: change,
//                             createdAt: timestamp,
//                             isSynced: online ? 1 : 0,
//                             clientUuid: clientUuid,
//                           );

//                       int? onlineTransactionId;

//                       if (online) {
//                         onlineTransactionId = await transactionService
//                             .saveTransaction(
//                               total: finalTotal,
//                               cash: cash,
//                               change: change,
//                               clientUuid: clientUuid,
//                             );

//                         await localDb.updateTransactionSupabaseId(
//                           localId: localTransactionId,
//                           supabaseId: onlineTransactionId,
//                         );
//                       }

//                       // ✅ TRACK PROMO INSERT PER PRODUCT.ID
//                       final Set<int> insertedPromoProducts = {};
//                       final promoService = TransactionPromoService();
//                       final futures = combinedItems.values.map((row) async {
//                         final product = row.product!;
//                         final qtySold = row.qty;

//                         final promoCount = savedPromoCounts[product.id] ?? 0;

//                         int? oldStock = await localDb.getProductStock(
//                           product.id,
//                         );

//                         int newStock = oldStock != null
//                             ? oldStock - qtySold
//                             : 0;

//                         await Future.wait([
//                           // ---------------- INSERT PROMO (ONCE PER PRODUCT) ----------------
//                           if (row.isPromo &&
//                               promoCount > 0 &&
//                               !insertedPromoProducts.contains(product.id))
//                             () async {
//                               insertedPromoProducts.add(product.id);

//                               print(
//                                 '🔥 INSERT PROMO | tx:$localTransactionId '
//                                 'product:${product.id} count:$promoCount',
//                               );
//                               // Offline insert
//                               await localDbPromo.insertTransactionPromo(
//                                 transactionId: localTransactionId,
//                                 productId: product.id,
//                                 productName: product.name,
//                                 promoCount: promoCount,
//                                 retailPrice: product.retailPrice,
//                                 isSynced: online ? 1 : 0,
//                               );
//                               // Online insert if connected
//                               if (online && onlineTransactionId != null) {
//                                 await promoService.insertTransactionPromo(
//                                   transactionId: onlineTransactionId,
//                                   productId: product.id,
//                                   productName: product.name,
//                                   promoCount: promoCount,
//                                   retailPrice: product.retailPrice,
//                                 );
//                               }
//                             }(),

//                           // ---------------- INSERT TRANSACTION ITEM ----------------
//                           localDb.insertTransactionItem(
//                             transactionId: localTransactionId,
//                             productId: product.id,
//                             productName: product.name,
//                             qty: qtySold,
//                             retailPrice: product.retailPrice,
//                             costPrice: product.costPrice,
//                             isPromo: product.isPromo,
//                             otherQty: product.otherQty,
//                             productClientUuid: product.productClientUuid,
//                           ),

//                           if (oldStock != null)
//                             localDb.updateProductStock(product.id, newStock),

//                           if (oldStock != null)
//                             localDb.insertStockHistory(
//                               transactionId: localTransactionId,
//                               id: generateUniqueId(prefix: "H").hashCode.abs(),
//                               productId: product.id,
//                               productName: product.name,
//                               oldStock: oldStock,
//                               qtyChanged: qtySold,
//                               newStock: newStock,
//                               type: 'SALE',
//                               createdAt: timestamp,
//                               synced: online ? 1 : 0,
//                               productClientUuid: product.productClientUuid,
//                             ),

//                           localDb.insertStockUpdateQueue1(
//                             productId: product.id,
//                             qty: qtySold,
//                             type: 'SALE',
//                           ),

//                           if (online && onlineTransactionId != null)
//                             Future.wait([
//                               productService.syncSingleProductOnline(
//                                 product.id,
//                               ),
//                               transactionService.saveTransactionItem(
//                                 transactionId: onlineTransactionId,
//                                 product: product,
//                                 qty: qtySold,
//                                 isPromo: product.isPromo,
//                                 otherQty: product.otherQty,
//                               ),
//                             ]),
//                         ]);
//                       }).toList();

//                       await Future.wait(futures);

//                       if (online) {
//                         await productService.syncOnlineProducts();
//                         await productService.syncOfflineStockHistory();
//                         await productService.syncOfflineProducts();
//                       }

//                       print("✅ TRANSACTION SUCCESS");
//                     } catch (e) {
//                       print("❌ Error saving transaction: $e");
//                     } finally {
//                       if (mounted) {
//                         setState(() => isSyncingOnline = false);
//                       }
//                     }
//                   }),
//                 );
//               },
//             ),
import 'package:flutter/material.dart';
import 'package:cashier/database/local_db.dart';
import 'package:cashier/database/supabase.dart';
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final supabase = SupabaseConfig.supabase;

  List<Map<String, dynamic>> localTransactions = [];
  List<Map<String, dynamic>> serverTransactions = [];
  Map<int, List<Map<String, dynamic>>> serverTransactionItems = {};

  StreamSubscription<ConnectivityResult>? _connectivitySub;
  StreamSubscription<InternetConnectionStatus>? _internetSub;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    fetchLocalTransactions();
    fetchServerTransactions();

    _internetSub = InternetConnectionChecker().onStatusChange.listen((status) async {
      if (status == InternetConnectionStatus.connected) {
        await fetchLocalTransactions();
        await fetchServerTransactions();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _connectivitySub?.cancel();
    _internetSub?.cancel();
    super.dispose();
  }

  Future<void> fetchLocalTransactions() async {
    final db = await LocalDatabase().database;

    final history = await db.rawQuery('''
      SELECT 
        t.id as tx_id,
        t.total,
        t.cash,
        t.change,
        t.created_at,
        ti.id as item_id,
        ti.product_name,
        ti.qty,
        ti.retail_price,
        ti.is_promo,
        tp.promo_count
      FROM transactions t
      LEFT JOIN transaction_items ti
        ON t.id = ti.transaction_id
      LEFT JOIN transaction_promos tp
        ON t.id = tp.transaction_id AND ti.id = tp.product_id
      WHERE t.is_synced = 0
      ORDER BY t.created_at DESC, ti.id ASC
    ''');

    Map<int, Map<String, dynamic>> grouped = {};
    for (var row in history) {
      final txId = row['tx_id'] as int;

      if (!grouped.containsKey(txId)) {
        grouped[txId] = {
          'tx_id': txId,
          'total': (row['total'] as num).toDouble(),
          'cash': (row['cash'] as num).toDouble(),
          'change': (row['change'] as num).toDouble(),
          'created_at': row['created_at'],
          'items': <Map<String, dynamic>>[],
        };
      }

      if (row['item_id'] != null) {
        grouped[txId]!['items'].add({
          'product_name': row['product_name'],
          'qty': row['qty'] ?? 0,
          'retail_price': (row['retail_price'] as num).toDouble(),
          'is_promo': row['is_promo'] == 1 || row['is_promo'] == true,
          'promo_count': row['promo_count'] ?? 0,
        });
      }
    }

    if (!mounted) return;
    setState(() {
      localTransactions = grouped.values.toList();
    });
  }

  Future<void> fetchServerTransactions() async {
    try {
      final txList = await supabase
          .from('transactions')
          .select('*')
          .order('created_at', ascending: false);
      final txListData = List<Map<String, dynamic>>.from(txList as List);

      Map<int, List<Map<String, dynamic>>> itemsMap = {};

      for (var tx in txListData) {
        final txId = tx['id'] as int;

        final itemResponse = await supabase
            .from('transaction_items')
            .select('*')
            .eq('transaction_id', txId);

        final promoResponse = await supabase
            .from('transaction_promos')
            .select('*')
            .eq('transaction_id', txId);

        final items = (itemResponse as List).map<Map<String, dynamic>>((item) {
          final promo = (promoResponse as List).firstWhere(
            (p) => p['product_id'] == item['product_id'],
            orElse: () => {'promo_count': 0},
          );

          return {
            'product_name': item['product_name'] ?? '',
            'qty': item['qty'] ?? 0,
            'retail_price':
                double.tryParse(item['retail_price'].toString()) ?? 0.0,
            'is_promo': item['is_promo'] == true || item['is_promo'] == 1,
            'promo_count': promo['promo_count'] ?? 0,
          };
        }).toList();

        itemsMap[txId] = items;
      }

      if (!mounted) return;
      setState(() {
        serverTransactions = txListData;
        serverTransactionItems = itemsMap;
      });
    } catch (e) {
      debugPrint('❌ Supabase fetch error: $e');
    }
  }

  Widget buildTransactionCard({
    required int txId,
    required double total,
    required double cash,
    required double change,
    required List<Map<String, dynamic>> items,
  }) {
    return Card(
      margin: const EdgeInsets.all(2),
      child: ExpansionTile(
        title: Text("Transaction #$txId - Total: ₱${total.toStringAsFixed(2)}"),
        subtitle: Text(
          "Cash: ₱${cash.toStringAsFixed(2)} | Change: ₱${change.toStringAsFixed(2)}",
        ),
        children: items.isEmpty
            ? const [
                Padding(padding: EdgeInsets.all(8), child: Text("No items")),
              ]
            : items.map((item) {
                final bool isPromo = item['is_promo'] == true;
                final int qty = item['qty'] ?? 0;
                final int promoCount = item['promo_count'] ?? 0;
                final double retailPrice = (item['retail_price'] as num).toDouble();
                final double rowTotal = isPromo ? retailPrice * promoCount : retailPrice * qty;

                return Container(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.black12, width: 1),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 5,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item['product_name'] ?? ''),
                            if (isPromo)
                              Text(
                                "PROMO $promoCount x ₱${retailPrice.toStringAsFixed(2)}",
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Expanded(flex: 2, child: Text('$qty', textAlign: TextAlign.center)),
                      Expanded(flex: 3, child: Text('₱${rowTotal.toStringAsFixed(2)}', textAlign: TextAlign.right)),
                    ],
                  ),
                );
              }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            floating: true,
            snap: true,
            pinned: false,
            automaticallyImplyLeading: false,
            backgroundColor: Colors.white,
            elevation: 0,
            title: const Text(
              "Transactions",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                letterSpacing: -1,
              ),
            ),
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Phone'),
                Tab(text: 'Server'),
              ],
              labelColor: Colors.blue,
              unselectedLabelColor: Colors.black54,
              indicatorColor: Colors.blue,
            ),
          )
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            RefreshIndicator(
              onRefresh: fetchLocalTransactions,
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: localTransactions.length,
                itemBuilder: (_, index) {
                  final tx = localTransactions[index];
                  return buildTransactionCard(
                    txId: tx['tx_id'],
                    total: tx['total'],
                    cash: tx['cash'],
                    change: tx['change'],
                    items: tx['items'],
                  );
                },
              ),
            ),
            RefreshIndicator(
              onRefresh: fetchServerTransactions,
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: serverTransactions.length,
                itemBuilder: (_, index) {
                  final tx = serverTransactions[index];
                  final items = serverTransactionItems[tx['id']] ?? [];
                  return buildTransactionCard(
                    txId: tx['id'],
                    total: (tx['total'] as num).toDouble(),
                    cash: (tx['cash'] as num).toDouble(),
                    change: (tx['change'] as num).toDouble(),
                    items: items,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
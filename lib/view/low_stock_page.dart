import 'package:flutter/material.dart';
import 'package:cashier/database/local_db.dart';

class LowStockPage extends StatefulWidget {
  const LowStockPage({super.key});

  @override
  State<LowStockPage> createState() => _LowStockPageState();
}

class _LowStockPageState extends State<LowStockPage> {

  final LocalDatabase localDb = LocalDatabase();

  List<Map<String, dynamic>> products = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadLowStock();
  }

  Future<void> loadLowStock() async {

    final result = await localDb.getLowStockProducts();

    setState(() {
      products = result;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text("Low Stock Products"),
      ),

      body: loading
          ? const Center(child: CircularProgressIndicator())
          : products.isEmpty
              ? const Center(child: Text("No low stock products"))
              : ListView.builder(
                  itemCount: products.length,
                  itemBuilder: (context, index) {

                    final product = products[index];

                    return ListTile(
                      leading: const Icon(
                        Icons.warning,
                        color: Colors.red,
                      ),

                      title: Text(
                        product['name'] ?? "No name",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      subtitle: Text(
                        "Stock: ${product['stock']} / Threshold: ${product['low_stock_threshold']}",
                      ),
                    );
                  },
                ),
    );
  }
}
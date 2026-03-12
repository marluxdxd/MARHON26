import 'package:flutter/material.dart';
import 'package:cashier/class/productclass.dart';

class LowStock extends StatelessWidget {
  final List<Productclass> products;

  const LowStock({
    super.key,
    required this.products,
  });

  @override
  Widget build(BuildContext context) {
    final lowStockProducts = products.where((p) => p.stock <= 3).toList();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: lowStockProducts.length,
      itemBuilder: (context, index) {
        final product = lowStockProducts[index];
        return null;

        // return Card(
        //   child: ListTile(
        //     title: Text(product.name),
        //     subtitle: Text("Stock: ${product.stock}"),
        //     trailing: Text("₱${product.retailPrice.toStringAsFixed(2)}"),
        //   ),
        // );
      },
    );
  }
}
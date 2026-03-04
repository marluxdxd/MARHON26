import 'package:flutter/material.dart';
import 'package:cashier/widget/addproduct.dart';
import 'package:cashier/class/productclass.dart';
import 'package:cashier/services/product_service.dart';

class Productview extends StatefulWidget {
  const Productview({super.key});

  @override
  State<Productview> createState() => _ProductviewState();
}

class _ProductviewState extends State<Productview> {
  final ProductService _productService = ProductService();

  List<Productclass> _products = [];
  List<Productclass> _filteredProducts = [];

  bool _isLoading = true;

  final searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadProducts();
  }

  /// ---------------- LOAD PRODUCTS ----------------

  Future<void> loadProducts() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      final products = await _productService.getAllProducts2();

      if (!mounted) return;

      setState(() {
        _products = products;
        _filteredProducts = products;
      });
    } catch (e) {
      print("Load error: $e");
    }

    setState(() => _isLoading = false);
  }

  /// ---------------- SEARCH FILTER ----------------

  void filterSearch(String query) {
    final filtered = _products.where((p) {
      return p.name.toLowerCase().contains(query.toLowerCase());
    }).toList();

    setState(() => _filteredProducts = filtered);
  }

  /// ---------------- DELETE PRODUCT (POS SAFE) ----------------

  Future<void> deleteProduct(Productclass product) async {
    try {
      final db = await _productService.localDb.database;

      /// ⭐ Delete locally first
      await db.delete(
        "products",
        where: "client_uuid = ?",
        whereArgs: [product.productClientUuid],
      );

      /// ⭐ Delete from Supabase
      if (product.productClientUuid.isNotEmpty) {
        await _productService.supabase
            .from("products")
            .delete()
            .eq("client_uuid", product.productClientUuid);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Product deleted")),
      );

      loadProducts();
    } catch (e) {
      print("Delete error: $e");
    }
  }

  /// ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Products")),

      body: _isLoading
          ? const Center(child: CircularProgressIndicator())

          : Column(
              children: [

                /// ⭐ Search Box
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: TextField(
                    controller: searchController,
                    onChanged: filterSearch,
                    decoration: InputDecoration(
                      hintText: "Search product...",
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

                /// ⭐ Product List
                Expanded(
                  child: _filteredProducts.isEmpty
                      ? const Center(
                          child: Text("No products found"),
                        )
                      : RefreshIndicator(
                          onRefresh: loadProducts,
                          child: ListView.builder(
                            itemCount: _filteredProducts.length,
                            itemBuilder: (context, index) {
                              final product = _filteredProducts[index];

                              return Dismissible(
                                key: Key(product.productClientUuid),

                                direction:
                                    DismissDirection.endToStart,

                                confirmDismiss: (_) async {
                                  return await showDialog(
                                    context: context,
                                    builder: (_) => AlertDialog(
                                      title:
                                          const Text("Delete Product"),
                                      content: const Text(
                                          "Delete this product permanently?"),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, false),
                                          child: const Text("Cancel"),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, true),
                                          child: const Text(
                                            "Delete",
                                            style:
                                                TextStyle(color: Colors.red),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },

                                onDismissed: (_) {
                                  deleteProduct(product);
                                },

                                background: Container(
                                  alignment: Alignment.centerRight,
                                  padding:
                                      const EdgeInsets.only(right: 20),
                                  color: Colors.red,
                                  child: const Icon(
                                    Icons.delete,
                                    color: Colors.white,
                                  ),
                                ),

                                child: Card(
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),

                                  child: ListTile(
                                    title: Text(product.name),

                                    subtitle: Text(
                                      "Cost: ₱${product.costPrice.toStringAsFixed(2)}\n"
                                      "Retail: ₱${product.retailPrice.toStringAsFixed(2)}",
                                    ),

                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [

                                        Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [

                                            Text(
                                              "Stock: ${product.stock}",
                                              style: const TextStyle(
                                                  fontWeight:
                                                      FontWeight.bold),
                                            ),

                                            if (product.isPromo)
                                              const Text(
                                                "PROMO",
                                                style: TextStyle(
                                                    color: Colors.red,
                                                    fontSize: 12),
                                              ),
                                          ],
                                        ),

                                        const SizedBox(width: 8),

                                        /// ⭐ EDIT BUTTON
                                        IconButton(
                                          icon: const Icon(
                                            Icons.edit,
                                            color: Colors.blue,
                                          ),

                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    AddProductPage(
                                                  product: product,
                                                ),
                                              ),
                                            ).then((_) => loadProducts());
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),

      /// ⭐ Add Product Button
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AddProductPage(),
            ),
          ).then((_) => loadProducts());
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
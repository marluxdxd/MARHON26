import 'package:flutter/material.dart';
import 'package:cashier/widget/addproduct.dart';
import 'package:cashier/class/productclass.dart';
import 'package:cashier/services/product_service.dart';

class Productview extends StatefulWidget {
  final String role; // "guest" or "master"
  const Productview({super.key, required this.role});

  @override
  State<Productview> createState() => _ProductviewState();
}

class _ProductviewState extends State<Productview> with WidgetsBindingObserver {
  String _stockFilter = "All"; // All, Low, High
  final ProductService _productService = ProductService();
  final ScrollController _scrollController = ScrollController();
  List<Productclass> _products = [];
  List<Productclass> _filteredProducts = [];
  bool _isLoading = true;
  final searchController = TextEditingController();
  late bool isGuest;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // observe app lifecycle
    isGuest = widget.role == "guest";
    loadProducts();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    searchController.dispose();
    super.dispose();
  }

  /// Called when app lifecycle changes (like resuming from background)
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      loadProducts(); // auto refresh when page comes back into view
    }
    super.didChangeAppLifecycleState(state);
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
        _filteredProducts = List.from(products);
      });

      filterByStock(); // apply current stock filter
    } catch (e) {
      print("Load error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to load products: $e")),
        );
      }
    }

    if (mounted) setState(() => _isLoading = false);
  }

  /// ---------------- SEARCH FILTER ----------------
  void filterSearch(String query) {
    List<Productclass> filtered = _products.where((p) {
      return p.name.toLowerCase().contains(query.toLowerCase());
    }).toList();

    setState(() {
      _filteredProducts = filtered;
    });

    filterByStock(); // apply stock filter on top
  }

  /// ---------------- STOCK FILTER ----------------
  void filterByStock() {
    List<Productclass> filtered = List.from(_filteredProducts);

    if (_stockFilter == "Low") {
      filtered = filtered.where((p) => p.stock <= 5).toList(); // low stock
    } else if (_stockFilter == "High") {
      filtered = filtered.where((p) => p.stock >= 50).toList(); // high stock
    }

    setState(() {
      _filteredProducts = filtered;
    });

    sortProductsAlphabetically();
  }

  /// ---------------- SORT ALPHABETICALLY ----------------
  void sortProductsAlphabetically() {
    _filteredProducts.sort((a, b) {
      String firstWordA = a.name.split(' ').first.toLowerCase();
      String firstWordB = b.name.split(' ').first.toLowerCase();
      return firstWordA.compareTo(firstWordB);
    });
    setState(() {});
  }

  /// ---------------- DELETE PRODUCT ----------------
  Future<void> deleteProduct(Productclass product) async {
    if (isGuest) return; // guest cannot delete

    try {
      final db = await _productService.localDb.database;

      // Delete locally first
      await db.delete(
        "products",
        where: "client_uuid = ?",
        whereArgs: [product.productClientUuid],
      );

      // Delete from Supabase
      if (product.productClientUuid.isNotEmpty) {
        await _productService.supabase
            .from("products")
            .delete()
            .eq("client_uuid", product.productClientUuid);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Product deleted")));

      loadProducts();
    } catch (e) {
      print("Delete error: $e");
    }
  }

  /// ---------------- UPDATE LOCAL PRODUCT ----------------
  void updateLocalProduct(Productclass updatedProduct) {
    final index = _products.indexWhere((p) => p.id == updatedProduct.id);

    if (index != -1) {
      setState(() {
        _products[index] = updatedProduct;
        _filteredProducts = List.from(_products);
      });
      filterByStock(); // apply current stock filter
    }
  }

  /// ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text("Products"),
        actions: [
          Text('sort'),
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_alt),
            onSelected: (value) {
              _stockFilter = value;
              filterByStock();
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: "All", child: Text("All Stocks")),
              PopupMenuItem(value: "Low", child: Text("Low Stock")),
              PopupMenuItem(value: "High", child: Text("High Stock")),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Search Box
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

                // Product List
                Expanded(
                  child: _filteredProducts.isEmpty
                      ? const Center(child: Text("No products found"))
                      : RefreshIndicator(
                          onRefresh: loadProducts,
                          child: ListView.builder(
                            controller: _scrollController,
                            itemCount: _filteredProducts.length,
                            itemBuilder: (context, index) {
                              final product = _filteredProducts[index];

                              return Dismissible(
                                key: Key(product.productClientUuid),
                                direction: DismissDirection.endToStart,
                                confirmDismiss: (_) async {
                                  if (isGuest) return false;
                                  return await showDialog(
                                    context: context,
                                    builder: (_) => AlertDialog(
                                      title: const Text("Delete Product"),
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
                                            style: TextStyle(color: Colors.red),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                onDismissed: (_) async {
                                  setState(() {
                                    _filteredProducts.removeAt(index);
                                  });
                                  await deleteProduct(product);
                                },
                                background: Container(
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 20),
                                  color: Colors.red,
                                  child: const Icon(
                                    Icons.delete,
                                    color: Colors.white,
                                  ),
                                ),
                                child: Card(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  child: ListTile(
                                    title: Text(product.name.toUpperCase()),
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
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            if (product.isPromo)
                                              const Text(
                                                "PROMO",
                                                style: TextStyle(
                                                  color: Colors.red,
                                                  fontSize: 12,
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(width: 8),
                                        if (!isGuest)
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
                                              ).then((result) {
                                                if (result != null &&
                                                    result is Productclass) {
                                                  updateLocalProduct(result);
                                                }
                                              });
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
      floatingActionButton: isGuest
          ? null
          : FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddProductPage()),
                ).then((_) => loadProducts());
              },
              child: const Icon(Icons.add),
            ),
    );
  }
}
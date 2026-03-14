import 'package:flutter/material.dart';
import 'package:cashier/widget/addproduct.dart';
import 'package:cashier/class/productclass.dart';
import 'package:cashier/services/product_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Productview extends StatefulWidget {
  const Productview({super.key});

  @override
  State<Productview> createState() => _ProductviewState();
}

class _ProductviewState extends State<Productview> with WidgetsBindingObserver {
  final ProductService _productService = ProductService();

  final ScrollController _scrollController = ScrollController();
  final searchController = TextEditingController();

  List<Productclass> _products = [];
  List<Productclass> _filteredProducts = [];

  bool _isLoading = true;

  String _stockFilter = "All";

  bool? isGuest;
  String userName = "User";
  String userEmail = "";

  late String currentUserId;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    final user = Supabase.instance.client.auth.currentUser;

    if (user != null) {
      currentUserId = user.id;
    }

    fetchUserRole();
    loadProducts();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    searchController.dispose();
    super.dispose();
  }

  /// APP RESUME REFRESH
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      loadProducts();
    }
  }

  /// USER PROFILE
  Future<void> fetchUserRole() async {
    final currentUser = Supabase.instance.client.auth.currentUser;

    if (currentUser == null) {
      setState(() => isGuest = true);
      return;
    }

    try {
      final userRecord = await Supabase.instance.client
          .from('profiles')
          .select('full_name,email')
          .eq('id', currentUser.id)
          .maybeSingle();

      setState(() {
        userName = userRecord?['full_name'] ?? "User";
        userEmail = userRecord?['email'] ?? "";
      });
    } catch (e) {
      print("User fetch error: $e");
    }
  }

  /// LOAD PRODUCTS (FILTERED BY USER)
  Future<void> loadProducts() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      final db = await _productService.localDb.database;

      final result = await db.query(
        "products",
        where: "user_id = ?",
        whereArgs: [currentUserId],
      );

      final products = result.map((e) => Productclass.fromMap(e)).toList();

      if (!mounted) return;

      setState(() {
        _products = products;
        _filteredProducts = List.from(products);
      });

      filterByStock();
    } catch (e) {
      print("Load error: $e");
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  /// SEARCH
  void filterSearch(String query) {
    List<Productclass> filtered = _products.where((p) {
      return p.name.toLowerCase().contains(query.toLowerCase());
    }).toList();

    setState(() {
      _filteredProducts = filtered;
    });

    filterByStock();
  }

  /// STOCK FILTER
  void filterByStock() {
    List<Productclass> filtered = List.from(_filteredProducts);

    if (_stockFilter == "Low") {
      filtered = filtered.where((p) => p.stock <= 5).toList();
    } else if (_stockFilter == "High") {
      filtered = filtered.where((p) => p.stock >= 50).toList();
    }

    filtered.sort((a, b) => a.name.compareTo(b.name));

    setState(() {
      _filteredProducts = filtered;
    });
  }

  /// DELETE
  Future<void> deleteProduct(Productclass product) async {
    try {
      final db = await _productService.localDb.database;

      await db.delete(
        "products",
        where: "client_uuid = ? AND user_id = ?",
        whereArgs: [product.productClientUuid, currentUserId],
      );

      await _productService.supabase
          .from("products")
          .delete()
          .eq("client_uuid", product.productClientUuid)
          .eq("user_id", currentUserId);

      loadProducts();
    } catch (e) {
      print("Delete error: $e");
    }
  }

  /// UPDATE LOCAL
  void updateLocalProduct(Productclass updatedProduct) {
    final index = _products.indexWhere((p) => p.id == updatedProduct.id);

    if (index != -1) {
      setState(() {
        _products[index] = updatedProduct;
        _filteredProducts = List.from(_products);
      });

      filterByStock();
    }
  }

  /// UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Products"),
        actions: [
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

                              return Card(
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                child: ListTile(
                                  title: Text(product.name),
                                  subtitle: Text(
                                      "Cost ₱${product.costPrice} | Retail ₱${product.retailPrice}"),
                                  trailing: Text("Stock ${product.stock}"),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => AddProductPage(
                                          product: product,
                                          userId: currentUserId,
                                        ),
                                      ),
                                    ).then((_) => loadProducts());
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                )
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddProductPage(
                userId: currentUserId,
              ),
            ),
          ).then((_) => loadProducts());
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
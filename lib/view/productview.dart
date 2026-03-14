import 'dart:ui';
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
  final TextEditingController searchController = TextEditingController();

  List<Productclass> _products = [];
  List<Productclass> _filteredProducts = [];

  bool _isLoading = true;
  String _stockFilter = "All";
  String _searchQuery = "";

  late String currentUserId;

  RealtimeChannel? _productChannel;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      currentUserId = user.id;
    }

    _setupRealtimeProducts();
    loadProducts();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _productChannel?.unsubscribe();
    _scrollController.dispose();
    searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      loadProducts();
    }
  }

  /// REALTIME LISTENER
  void _setupRealtimeProducts() {
    final supabase = Supabase.instance.client;

    _productChannel = supabase.channel('products_changes');

    _productChannel!
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'products',
          callback: (payload) {
            loadProducts();
          },
        )
        .subscribe();
  }

  /// LOAD PRODUCTS
  Future<void> loadProducts() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      await _productService.syncOnlineProducts();

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
      });

      _applyFilters(); // always apply filters after loading
    } catch (e) {
      debugPrint("Load error: $e");
    }

    if (mounted) setState(() => _isLoading = false);
  }

  /// APPLY SEARCH + STOCK FILTER
  void _applyFilters() {
    List<Productclass> filtered = List.from(_products);

    // Apply search
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where(
            (p) => p.name.toLowerCase().contains(_searchQuery.toLowerCase()),
          )
          .toList();
    }

    // Apply stock filter
    if (_stockFilter == "Low") {
      filtered = filtered.where((p) => p.stock <= 5).toList();
    } else if (_stockFilter == "High") {
      filtered = filtered.where((p) => p.stock >= 50).toList();
    }

    // Sort alphabetically
    filtered.sort((a, b) => a.name.compareTo(b.name));

    setState(() {
      _filteredProducts = filtered;
    });
  }

  /// SEARCH
  void filterSearch(String query) {
    _searchQuery = query;
    _applyFilters();
  }

  /// STOCK FILTER
  void filterByStock(String stock) {
    _stockFilter = stock;
    _applyFilters();
  }

  Color stockColor(int stock) {
    if (stock <= 5) return Colors.red;
    if (stock <= 20) return Colors.orange;
    return Colors.green;
  }

  /// PRODUCT CARD
  Widget buildProductCard(Productclass product) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Material(
        borderRadius: BorderRadius.circular(14),
        elevation: 3,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    AddProductPage(product: product, userId: currentUserId),
              ),
            ).then((_) => loadProducts());
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.inventory_2, color: Colors.blue),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Cost ₱${product.costPrice} • Retail ₱${product.retailPrice}",
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    const Text("Stock"),
                    Text(
                      "${product.stock}",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: stockColor(product.stock),
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// EMPTY STATE
  Widget emptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: const [
        SizedBox(height: 150),
        Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey),
        SizedBox(height: 10),
        Center(
          child: Text(
            "No products found",
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ),
        Center(
          child: Text(
            "Pull down to refresh",
            style: TextStyle(color: Colors.grey),
          ),
        ),
      ],
    );
  }

  Widget buildProductList() {
    if (_filteredProducts.isEmpty) {
      return emptyState();
    }

    return ListView.builder(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: _filteredProducts.length,
      itemBuilder: (context, index) {
        return buildProductCard(_filteredProducts[index]);
      },
    );
  }

  /// UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text("Products"),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // SEARCH BAR
                Container(
                  padding: const EdgeInsets.all(10),
                  child: TextField(
                    controller: searchController,
                    onChanged: filterSearch,
                    decoration: InputDecoration(
                      hintText: "Search products...",
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.black45, width: 2),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.black45, width: 2),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.black45, width: 2),
                      ),
                    ),
                  ),
                ),

                // STOCK FILTER BUTTONS
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: () => filterByStock("All"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _stockFilter == "All"
                              ? Colors.blue
                              : Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              12,
                            ), // border radius
                            side: const BorderSide(
                              color: Colors.black26, // border color
                              width: 1, // border width
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ), // size ng button
                        ),
                        child: Text(
                          "All Stocks",
                          style: TextStyle(
                            fontSize: 14, // font size
                            fontWeight: FontWeight.bold, // font weight
                            color: _stockFilter == "All"
                                ? Colors.white
                                : Colors.black,
                          ),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => filterByStock("Low"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _stockFilter == "Low"
                              ? Colors.blue
                              : Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(
                              color: Colors.black26,
                              width: 1,
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                        ),
                        child: Text(
                          "Low Stock",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: _stockFilter == "Low"
                                ? Colors.white
                                : Colors.black,
                          ),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => filterByStock("High"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _stockFilter == "High"
                              ? Colors.blue
                              : Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(
                              color: Colors.black26,
                              width: 1,
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                        ),
                        child: Text(
                          "High Stock",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: _stockFilter == "High"
                                ? Colors.white
                                : Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // PRODUCT LIST
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: loadProducts,
                    child: buildProductList(),
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddProductPage(userId: currentUserId),
            ),
          ).then((_) => loadProducts());
        },
      ),
    );
  }
}

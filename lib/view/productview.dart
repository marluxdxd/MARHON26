import 'package:flutter/material.dart';
import 'package:cashier/widget/addproduct.dart';
import 'package:cashier/class/productclass.dart';
import 'package:cashier/services/product_service.dart';
import 'package:flutter/rendering.dart';
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

  // Scroll state
  bool _isScrollingDown = false;
  bool _showUI = true; // Controls visibility of AppBar, FAB, Filter

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) currentUserId = user.id;

    _setupRealtimeProducts();
    loadProducts();

    _scrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    if (_scrollController.position.userScrollDirection == ScrollDirection.reverse) {
      if (!_isScrollingDown) {
        _isScrollingDown = true;
        _showUI = false;
        setState(() {});
      }
    }
    if (_scrollController.position.userScrollDirection == ScrollDirection.forward) {
      if (_isScrollingDown) {
        _isScrollingDown = false;
        _showUI = true;
        setState(() {});
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _productChannel?.unsubscribe();
    _scrollController.dispose();
    searchController.dispose();
    super.dispose();
  }

  void _setupRealtimeProducts() {
    final supabase = Supabase.instance.client;
    _productChannel = supabase.channel('products_changes');

    _productChannel!
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'products',
          callback: (payload) => loadProducts(),
        )
        .subscribe();
  }

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

      _applyFilters();
    } catch (e) {
      debugPrint("Load error: $e");
    }

    if (mounted) setState(() => _isLoading = false);
  }

  void _applyFilters() {
    List<Productclass> filtered = List.from(_products);

    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where(
              (p) => p.name.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    if (_stockFilter == "Low") {
      filtered = filtered.where((p) => p.stock <= 5).toList();
    } else if (_stockFilter == "High") {
      filtered = filtered.where((p) => p.stock >= 50).toList();
    }

    filtered.sort((a, b) => a.name.compareTo(b.name));

    setState(() => _filteredProducts = filtered);
  }

  void filterSearch(String query) {
    _searchQuery = query;
    _applyFilters();
  }

  void filterByStock(String stock) {
    _stockFilter = stock;
    _applyFilters();
  }

  Color stockColor(int stock) {
    if (stock <= 5) return Colors.red;
    if (stock <= 20) return Colors.orange;
    return Colors.green;
  }

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
                            fontWeight: FontWeight.bold, fontSize: 16),
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

  Widget filterButton(String title, String value) {
    bool isSelected = _stockFilter == value;

    return ElevatedButton(
      onPressed: () {
        setState(() {
          _stockFilter = value;
          _applyFilters();
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.blue : Colors.white,
        foregroundColor: isSelected ? Colors.white : Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: Colors.black26),
        ),
      ),
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
      ),
    );
  }

  Widget searchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
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
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        onRefresh: loadProducts,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : CustomScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // Collapsing AppBar with animation
                  SliverAppBar(
                    floating: true,
                    pinned: false,
                    snap: false,
                    automaticallyImplyLeading: false,
                    backgroundColor: Colors.white,
          
                    title: AnimatedSlide(
                      offset: _showUI ? Offset.zero : const Offset(0, -1),
                      duration: const Duration(milliseconds: 200),
                      child: const Text(
                        "Products",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                          letterSpacing: -1,
                        ),
                      ),
                    ),
                    bottom: PreferredSize(
                      preferredSize: const Size.fromHeight(70),
                      child: AnimatedSlide(
                        offset: _showUI ? Offset.zero : const Offset(0, -1),
                        duration: const Duration(milliseconds: 200),
                        child: searchBar(),
                      ),
                    ),
                  ),

                  SliverPersistentHeader(
                    pinned: true,
                    floating: false,
                    delegate: _FilterButtonsDelegate(
                      buttons: AnimatedSlide(
                        offset: _showUI ? Offset.zero : const Offset(0, -1),
                        duration: const Duration(milliseconds: 200),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              filterButton("All Stocks", "All"),
                              filterButton("Low Stock", "Low"),
                              filterButton("High Stock", "High"),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  _filteredProducts.isEmpty
                      ? SliverFillRemaining(
                          child: Center(
                            child: Text(
                              "No products found",
                              style: TextStyle(
                                  fontSize: 18, color: Colors.grey[500]),
                            ),
                          ),
                        )
                      : SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              return buildProductCard(
                                  _filteredProducts[index]);
                            },
                            childCount: _filteredProducts.length,
                          ),
                        ),
                ],
              ),
      ),
      floatingActionButton: AnimatedSlide(
        offset: _showUI ? Offset.zero : const Offset(0, 2),
        duration: const Duration(milliseconds: 200),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: _showUI ? 1 : 0,
          child: FloatingActionButton(
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
        ),
      ),
    );
  }
}

class _FilterButtonsDelegate extends SliverPersistentHeaderDelegate {
  final Widget buttons;
  _FilterButtonsDelegate({required this.buttons});

  @override
  double get minExtent => 60;
  @override
  double get maxExtent => 60;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(color: Colors.transparent, child: buttons);
  }

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) =>
      true;
}
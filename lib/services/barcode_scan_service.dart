import 'package:cashier/services/scan_mode.dart';
import 'package:cashier/widget/addproduct.dart';
import 'package:flutter/material.dart';
import '../view/barcode.dart';
import '../class/posrowclass.dart';
import '../class/productclass.dart';
import '../services/product_service.dart';

class BarcodeScanService {
  /// ⭐ SUPER FAST LOOKUP CACHE
  static Map<String, Productclass> _barcodeMap = {};

  /// ===============================
  /// BUILD CACHE
  /// ===============================
  static void buildBarcodeCache(List<Productclass> products) {
    _barcodeMap = {
      for (var p in products)
        if (p.barcode != null && p.barcode!.trim().isNotEmpty)
          p.barcode!.trim(): p,
    };

    debugPrint("PRODUCTS LENGTH: ${products.length}");
    debugPrint("CACHE SIZE: ${_barcodeMap.length}");
  }

  static Productclass? getProduct(String barcode) {
    return _barcodeMap[barcode];
  }

  /// ===============================
  /// SCAN BARCODE
  /// ===============================
  static Future<void> scanBarcode({
    required BuildContext context,
    required List<Productclass> products,
    required List<POSRow> rows,
    required bool isAutoNextRowOn,
    required VoidCallback refreshUI,
    required ScanMode mode,
    Function(String barcode)? onAddProductScan,
  }) async {
    if (_barcodeMap.isEmpty) {
      buildBarcodeCache(products);
    }

    final productService = ProductService();

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BarcodeScannerPage(
          onBarcodeScanned: (barcode) async {
            final cleanBarcode = barcode.trim();
            debugPrint("SCANNED: $cleanBarcode");

            Productclass? product = _barcodeMap[cleanBarcode];

            /// ⭐ AUTO REFRESH CACHE IF NOT FOUND
            if (product == null) {
              final productService = ProductService();
              final products = await productService.getProducts();

              buildBarcodeCache(products);

              product = _barcodeMap[cleanBarcode];
            }

            /// ===============================
            /// ADD PRODUCT MODE
            /// ===============================
            if (mode == ScanMode.addProduct) {
              Navigator.pop(context, barcode);
              if (onAddProductScan != null) {
                onAddProductScan(cleanBarcode);
              }
              return;
            }

            /// ===============================
            /// PRODUCT NOT FOUND
            /// ===============================
            if (product == null) {
              final existingList = await productService
                  .findProductWithoutBarcode();

              Productclass? existing = existingList.isNotEmpty
                  ? existingList.first
                  : null;

              if (!context.mounted) return;

              showDialog(
                context: context,
                builder: (_) {
                  return AlertDialog(
                    title: const Text("Product Not Found"),
                    content: const Text(
                      "Do you want to add new product or update existing product?",
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Cancel"),
                      ),

                      /// ⭐ ADD NEW PRODUCT
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context); // close dialog
                          Navigator.pop(context); // close scanner

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  AddProductPage(barcode: cleanBarcode),
                            ),
                          );
                        },
                        child: const Text("Add New Product"),
                      ),

                      /// ⭐ UPDATE EXISTING PRODUCT (SEARCH PRODUCT FIRST)
                      ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(context); // close dialog
                          Navigator.pop(context); // close scanner

                          final selectedProduct =
                              await Navigator.push<Productclass>(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ProductSearchSelectionPage(),
                                ),
                              );

                          if (selectedProduct != null) {
                            await productService.updateProductBarcode(
                              selectedProduct.id,
                              cleanBarcode,
                            );

                            // ⭐ Reload products
                            final newProducts = await productService.getAllProducts();

BarcodeScanService.buildBarcodeCache(newProducts);

// Force refresh POS rows product references
for (var row in rows) {
  if (row.product != null) {
    final updatedProduct = newProducts.firstWhere(
      (p) => p.id == row.product!.id,
      orElse: () => row.product!,
    );

    row.product = updatedProduct;
  }
}

refreshUI();

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("Barcode updated successfully"),
                              ),
                            );
                            // Refresh cache
                            BarcodeScanService.buildBarcodeCache(
                              await productService.getProducts(),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  "Barcode added to ${selectedProduct.name}",
                                ),
                              ),
                            );
                          }
                        },
                        child: const Text("Update Existing Product"),
                      ),
                    ],
                  );
                },
              );

              return;
            }

            /// ===============================
            /// PRODUCT FOUND → ADD TO POS ROWS
            /// ===============================
            POSRow? existingRow;

            for (var r in rows) {
              if (r.product?.id == product.id) {
                existingRow = r;
                break;
              }
            }

            if (existingRow != null) {
              existingRow.qty++;
            } else {
              int insertIndex = rows.length;

              if (rows.isNotEmpty && rows.last.product == null) {
                insertIndex = rows.length - 1;
              }

              rows.insert(
                insertIndex,
                POSRow(
                  product: product,
                  qty: 1,
                  isPromo: product.isPromo,
                  otherQty: product.otherQty,
                ),
              );
            }

            if (isAutoNextRowOn && rows.last.product != null) {
              rows.add(POSRow());
            }

            refreshUI();
          },
        ),
      ),
    );
  }
}

/// ======================================================
/// PRODUCT SEARCH SELECTION PAGE
/// ======================================================
class ProductSearchSelectionPage extends StatefulWidget {
  const ProductSearchSelectionPage({super.key});

  @override
  State<ProductSearchSelectionPage> createState() =>
      _ProductSearchSelectionPageState();
}

class _ProductSearchSelectionPageState
    extends State<ProductSearchSelectionPage> {
  final ProductService productService = ProductService();

  List<Productclass> products = [];
  List<Productclass> filtered = [];

  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadProducts();
  }

  Future<void> loadProducts() async {
    products = await productService.getProducts();
    filtered = products;
    setState(() {});
  }

  void search(String query) {
    filtered = products
        .where(
          (p) =>
              p.name.toLowerCase().contains(query.toLowerCase()) ||
              (p.barcode ?? "").contains(query),
        )
        .toList();

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Select Product")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: TextField(
              controller: searchController,
              onChanged: search,
              decoration: const InputDecoration(
                hintText: "Search product...",
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (_, i) {
                final product = filtered[i];

                return ListTile(
                  title: Text(product.name),
                  subtitle: Text("Barcode: ${product.barcode ?? 'No barcode'}"),
                  onTap: () {
                    Navigator.pop(context, product);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

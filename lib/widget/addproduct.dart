import 'package:cashier/class/productclass.dart';
import 'package:cashier/services/barcode_scan_service.dart';
import 'package:cashier/services/product_service.dart';
import 'package:flutter/material.dart';

class AddProductPage extends StatefulWidget {
  final Productclass? product;
  final String? barcode;

  const AddProductPage({
    super.key,
    this.product,
    this.barcode,
  });

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  double pricePerPiece = 0;
  double priceInterest = 0;

  final barcodeController = TextEditingController();
  final nameController = TextEditingController();
  final stockController = TextEditingController();
  final costPriceController = TextEditingController();
  final byPiecesController = TextEditingController();
  final retailPriceController = TextEditingController();
  final promoQtyController = TextEditingController();

  final productService = ProductService();

  bool isLoading = false;
  bool isPromo = false;
  int otherQty = 0;

  @override
  void initState() {
    super.initState();

    if (widget.product == null) {
  byPiecesController.text = "1";

  /// If barcode came from scanner
  if (widget.barcode != null) {
    barcodeController.text = widget.barcode!;
  }
}

    /// ⭐ ADD MODE DEFAULT VALUES
    if (widget.product == null) {
      byPiecesController.text = "1";

      /// ⭐ If barcode came from scanner
      if (widget.barcode != null) {
        barcodeController.text = widget.barcode!;
      }
    }

    /// ⭐ EDIT MODE
    if (widget.product != null) {
      final p = widget.product!;

      nameController.text = p.name;
      barcodeController.text = p.barcode ?? "";
      stockController.text = p.stock.toString();
      costPriceController.text = p.costPrice.toString();
      retailPriceController.text = p.retailPrice.toString();
      byPiecesController.text = p.byPieces.toString();
      promoQtyController.text = p.otherQty.toString();

      isPromo = p.isPromo;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        computePricePerPiece();
        computeInterest();
      });
    }
  }

  /// ===============================
  /// SAVE PRODUCT
  /// ===============================
  void saveProduct() async {
    final name = nameController.text.trim();
    final barcode = barcodeController.text.trim();
    final stock = int.tryParse(stockController.text) ?? 0;
    final costPrice = double.tryParse(costPriceController.text) ?? 0;
    final retailPrice = double.tryParse(retailPriceController.text) ?? 0;
    final byPieces = int.tryParse(byPiecesController.text) ?? 1;
    otherQty = int.tryParse(promoQtyController.text) ?? 0;

    if (name.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Enter product name")));
      return;
    }

    setState(() => isLoading = true);

    try {
      final online = await productService.isOnline1();

      /// ⭐ CREATE MODE
      if (widget.product == null) {
        await productService.insertProductOffline(
          name: name,
          barcode: barcode,
          stock: stock,
          costPrice: costPrice,
          retailPrice: retailPrice,
          byPieces: byPieces,
          isPromo: isPromo,
          otherQty: otherQty,
        );
      }

      /// ⭐ UPDATE MODE
      else {
        final clientUuid = widget.product!.productClientUuid;

        final db = await productService.localDb.database;

        await db.update(
          "products",
          {
            "name": name,
            "barcode": barcode,
            "cost_price": costPrice,
            "retail_price": retailPrice,
            "by_pieces": byPieces,
            "is_promo": isPromo ? 1 : 0,
            "other_qty": otherQty,
            "is_synced": 0,
          },
          where: "client_uuid = ?",
          whereArgs: [clientUuid],
        );

        if (await productService.isOnline2()) {
          await productService.syncSingleProductOnline(widget.product!.id);
        }
      }

      /// ⭐ Sync if online
    if (online) {
  productService.notifyProductChanged();

  /// Force full sync + reload cache
  await productService.syncOnlineProducts();
  final products = await productService.getAllProducts();
  BarcodeScanService.buildBarcodeCache(products);
}

/// ⭐ REFRESH BARCODE CACHE
final products = await productService.getProducts();
BarcodeScanService.buildBarcodeCache(products);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.product == null
                ? "Product added successfully"
                : "Product updated successfully",
          ),
        ),
      );

      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint(e.toString());
    }

    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  /// ===============================
  /// CALCULATIONS
  /// ===============================
  void computePricePerPiece() {
    final costPrice = double.tryParse(costPriceController.text) ?? 0;
    final pieces = int.tryParse(byPiecesController.text) ?? 1;

    setState(() {
      pricePerPiece = pieces > 0 ? costPrice / pieces : 0;
    });

    computeInterest();
  }

  void computeInterest() {
    final retailPrice = double.tryParse(retailPriceController.text) ?? 0;

    setState(() {
      priceInterest = retailPrice - pricePerPiece;
    });
  }

  /// ===============================
  /// UI
  /// ===============================
  @override
  Widget build(BuildContext context) {
    final isEdit = widget.product != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? "Edit Product" : "Add Product"),
        iconTheme: const IconThemeData(color: Colors.black),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            CheckboxListTile(
              title: const Text("Promo"),
              value: isPromo,
              onChanged: (v) {
                setState(() => isPromo = v ?? false);
              },
            ),

          TextField(
  controller: barcodeController,
  readOnly: widget.barcode != null,
  decoration: const InputDecoration(labelText: "Barcode"),
),

            if (isPromo)
              TextField(
                controller: promoQtyController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Promo Qty"),
              ),

            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Product Name"),
            ),

            TextField(
              controller: stockController,
              keyboardType: TextInputType.number,
              enabled: widget.product == null,
              decoration: const InputDecoration(labelText: "Stock"),
            ),

            TextField(
              controller: costPriceController,
              keyboardType: TextInputType.number,
              onChanged: (_) => computePricePerPiece(),
              decoration: const InputDecoration(labelText: "Cost Price"),
            ),

            TextField(
              controller: byPiecesController,
              keyboardType: TextInputType.number,
              onChanged: (_) => computePricePerPiece(),
              decoration: const InputDecoration(labelText: "By Pieces"),
            ),

            TextField(
              controller: retailPriceController,
              keyboardType: TextInputType.number,
              onChanged: (_) => computeInterest(),
              decoration: const InputDecoration(labelText: "Retail Price"),
            ),

            const SizedBox(height: 15),

            Text("Price per piece: ₱${pricePerPiece.toStringAsFixed(2)}"),
            Text("Interest: ₱${priceInterest.toStringAsFixed(2)}"),

            const SizedBox(height: 25),

            ElevatedButton(
              onPressed: isLoading ? null : saveProduct,
              child: isLoading
                  ? const CircularProgressIndicator()
                  : Text(isEdit ? "Update Product" : "Save Product"),
            ),
          ],
        ),
      ),
    );
  }
}
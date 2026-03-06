import 'package:cashier/class/productclass.dart';
import 'package:cashier/services/product_service.dart';
import 'package:cashier/view/barcode.dart';
import 'package:flutter/material.dart';


class AddProductPage extends StatefulWidget {
  final Productclass? product;

  const AddProductPage({super.key, this.product});

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

  /// ⭐ INIT EDIT MODE
  @override
  void initState() {
    super.initState();

    /// ⭐ kung ADD PRODUCT
  if (widget.product == null) {
    byPiecesController.text = "1";
  }

  /// ⭐ kung EDIT PRODUCT
  if (widget.product != null) {
    final p = widget.product!;

      nameController.text = p.name;
      barcodeController.text = p.barcode;
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

  /// ⭐ SAVE PRODUCT (CREATE + UPDATE)
  void saveProduct() async {
    final name = nameController.text.trim();
    final barcode = barcodeController.text.trim();
    final stock = int.tryParse(stockController.text.trim()) ?? 0;
    final costPrice =
        double.tryParse(costPriceController.text.trim()) ?? 0;
    final retailPrice =
        double.tryParse(retailPriceController.text.trim()) ?? 0;
    final byPieces =
        int.tryParse(byPiecesController.text.trim()) ?? 0;

    otherQty =
        int.tryParse(promoQtyController.text.trim()) ?? 0;

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter product name")),
      );
      return;
    }

    if (byPieces <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("By pieces must be > 0")),
      );
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

        /// Sync update online
        if (await productService.isOnline2()) {
          await productService.syncSingleProductOnline(
            widget.product!.id,
          );
        }
      }

      if (online) {
        await productService.syncOnlineProducts();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.product == null
              ? "Product added"
              : "Product updated"),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      print(e);
    }

    setState(() => isLoading = false);
  }

  /// ⭐ CALCULATIONS
  void computePricePerPiece() {
    final costPrice =
        double.tryParse(costPriceController.text) ?? 0;
    final pieces =
        int.tryParse(byPiecesController.text) ?? 0;

    setState(() {
      pricePerPiece =
          pieces > 0 ? costPrice / pieces : 0;
    });

    computeInterest();
  }

  void computeInterest() {
    final retailPrice =
        double.tryParse(retailPriceController.text) ?? 0;

    setState(() {
      priceInterest = retailPrice - pricePerPiece;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.product != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? "Edit Product" : "Add Product"),
        actions: [  IconButton(
      icon: const Icon(Icons.qr_code_scanner),
      onPressed: () async {

        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const BarcodeScannerPage(),
          ),
        );

        if (result != null) {
          setState(() {
            barcodeController.text = result;
          });
        }

      },
    )],
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

             /// ⭐ BARCODE FIELD
    TextField(
      controller: barcodeController,
      decoration: const InputDecoration(
        labelText: "Barcode",
      ),
    ),

            if (isPromo)
              TextField(
                controller: promoQtyController,
                keyboardType: TextInputType.number,
                decoration:
                    const InputDecoration(labelText: "Promo Qty"),
              ),

            TextField(
              controller: nameController,
              decoration:
                  const InputDecoration(labelText: "Product Name"),
            ),
    TextField(
  controller: stockController,
  keyboardType: TextInputType.number,
  enabled: widget.product == null, // ⭐ disable if edit
  decoration: const InputDecoration(
    labelText: "Stock",
  ),
),

            TextField(
              controller: costPriceController,
              keyboardType: TextInputType.number,
              onChanged: (_) => computePricePerPiece(),
              decoration:
                  const InputDecoration(labelText: "Cost Price"),
            ),

            TextField(
              controller: byPiecesController,
              keyboardType: TextInputType.number,
              onChanged: (_) => computePricePerPiece(),
              decoration:
                  const InputDecoration(labelText: "By Pieces"),
            ),

            TextField(
              controller: retailPriceController,
              keyboardType: TextInputType.number,
              onChanged: (_) => computeInterest(),
              decoration:
                  const InputDecoration(labelText: "Retail Price"),
            ),

            const SizedBox(height: 15),

            Text(
                "Price per piece: ₱${pricePerPiece.toStringAsFixed(2)}"),

            Text(
                "Interest: ₱${priceInterest.toStringAsFixed(2)}"),

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
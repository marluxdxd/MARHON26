import 'package:cashier/class/productclass.dart';
import 'package:cashier/services/barcode_scan_service.dart';
import 'package:cashier/services/product_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class AddProductPage extends StatefulWidget {
  final Productclass? product; // existing product for edit
  final String? barcode; // scanned barcode

  const AddProductPage({super.key, this.product, this.barcode});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage>
    with SingleTickerProviderStateMixin {
  double pricePerPiece = 0;
  double priceInterest = 0;
  final lowStockController = TextEditingController();
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

  late AnimationController _animController;
  late Animation<double> _priceAnim;

  @override
  void initState() {
    super.initState();

    _animController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _priceAnim = Tween<double>(begin: 0, end: 0).animate(_animController);

    // Add mode defaults
    if (widget.product == null) {
      byPiecesController.text = "1";
      if (widget.barcode != null) barcodeController.text = widget.barcode!;
    }

    // Edit mode: pre-fill fields with selected product
    if (widget.product != null) {
      final p = widget.product!;
      nameController.text = p.name;
      barcodeController.text = widget.barcode ?? p.barcode ?? "";
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

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
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

      if (widget.product == null) {
        // CREATE MODE
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
      } else {
        // UPDATE MODE
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

        BarcodeScanService.updateProductCache(
          Productclass(
            id: widget.product!.id,
            productClientUuid: widget.product!.productClientUuid,
            name: name,
            barcode: barcode,
            stock: stock,
            costPrice: costPrice,
            retailPrice: retailPrice,
            byPieces: byPieces,
            isPromo: isPromo,
            otherQty: otherQty,
          ),
        );

        if (await productService.isOnline2()) {
          await productService.syncSingleProductOnline(widget.product!.id);
        }
      }

      if (online) {
        productService.notifyProductChanged();
        await productService.syncOnlineProducts();
        final products = await productService.getAllProducts();
        BarcodeScanService.buildBarcodeCache(products);
      }

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
      debugPrint("SAVE PRODUCT ERROR: $e");
    }

    if (mounted) setState(() => isLoading = false);
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

  void _animatePrice(double oldValue, double newValue) {
    _priceAnim = Tween<double>(begin: oldValue, end: newValue).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _animController.forward(from: 0);
  }

  /// ===============================
  /// UI
  /// ===============================
  InputDecoration buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.black54),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.black26),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: const TextStyle(color: Colors.black45),
      labelStyle: const TextStyle(color: Colors.black87),
      filled: true,
      fillColor: Colors.white,
    );
  }

  Widget buildGradientCard({required Widget child}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: child,
    );
  }

  Widget buildTwoColumnRow({required Widget left, required Widget right}) {
    return Row(
      children: [
        Expanded(child: left),
        const SizedBox(width: 10),
        Expanded(child: right),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.product != null;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          isEdit ? "Edit Product" : "Add Product",
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          children: [
            CheckboxListTile(
              title: const Text(
                "Promo",
                style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
              ),
              value: isPromo,
              activeColor: Colors.blueAccent,
              onChanged: (v) => setState(() => isPromo = v ?? false),
            ),

            buildGradientCard(
  child: TextField(
    controller: barcodeController,
    readOnly: widget.barcode != null,
    style: const TextStyle(color: Colors.black),
    decoration: InputDecoration(
      labelText: "Barcode",
      prefixIcon: Padding(
        padding: const EdgeInsets.all(1),
        child: SvgPicture.asset(
          "assets/icons/Barcode.svg",
          width: 20,
          height: 30,
        ),
      ),
      border: OutlineInputBorder(),
    ),
  ),
),

            if (isPromo)
              buildGradientCard(
                child: TextField(
                  controller: promoQtyController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.black),
                  decoration: buildInputDecoration("Promo Qty", Icons.confirmation_number),
                ),
              ),

            buildGradientCard(
              child: TextField(
                controller: nameController,
                style: const TextStyle(color: Colors.black),
                decoration: buildInputDecoration("Product Name", Icons.label),
              ),
            ),

            buildTwoColumnRow(
              left: buildGradientCard(
                child: TextField(
                  controller: stockController,
                  keyboardType: TextInputType.number,
                  enabled: widget.product == null,
                  style: const TextStyle(color: Colors.black),
                  decoration: buildInputDecoration("Stock", Icons.inventory),
                ),
              ),
              right: buildGradientCard(
                child: TextField(
                  controller: lowStockController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.black54),
                  decoration: buildInputDecoration("Low Stock", Icons.warning)
                      .copyWith(hintText: "Optional"),
                ),
              ),
            ),

            buildTwoColumnRow(
              left: buildGradientCard(
                child: TextField(
                  controller: costPriceController,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => computePricePerPiece(),
                  style: const TextStyle(color: Colors.black),
                  decoration: buildInputDecoration("Cost Price", Icons.attach_money),
                ),
              ),
              right: buildGradientCard(
                child: TextField(
                  controller: byPiecesController,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => computePricePerPiece(),
                  style: const TextStyle(color: Colors.black),
                  decoration: buildInputDecoration("By Pieces", Icons.layers),
                ),
              ),
            ),

            buildGradientCard(
              child: TextField(
                controller: retailPriceController,
                keyboardType: TextInputType.number,
                onChanged: (_) => computeInterest(),
                style: const TextStyle(color: Colors.black),
                decoration: buildInputDecoration("Retail Price", Icons.price_check),
              ),
            ),

            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AnimatedBuilder(
                  animation: _priceAnim,
                  builder: (_, __) => Text(
                    "Price/pcs: ₱${pricePerPiece.toStringAsFixed(2)}",
                    style: const TextStyle(
                        color: Colors.blueAccent, fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  "Interest: ₱${priceInterest.toStringAsFixed(2)}",
                  style: const TextStyle(
                      color: Colors.green, fontWeight: FontWeight.bold),
                ),
              ],
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : saveProduct,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: Colors.blueAccent,
                ),
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        isEdit ? "Update Product" : "Save Product",
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
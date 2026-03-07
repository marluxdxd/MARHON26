import 'package:cashier/services/scan_mode.dart';
import 'package:cashier/widget/addproduct.dart';
import 'package:flutter/material.dart';
import '../view/barcode.dart';
import '../class/posrowclass.dart';
import '../class/productclass.dart';

class BarcodeScanService {
  /// ⭐ SUPER FAST LOOKUP CACHE
  static Map<String, Productclass> _barcodeMap = {};

  /// ===============================
  /// BUILD CACHE (RUN WHEN PRODUCTS LOAD)
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

  /// ===============================
  /// GET PRODUCT FROM CACHE
  /// ===============================
  static Productclass? getProduct(String barcode) {
    return _barcodeMap[barcode];
  }

  /// ===============================
  /// OPEN SCANNER (CONTINUOUS MODE)
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
    /// Build cache if empty
    if (_barcodeMap.isEmpty) {
      buildBarcodeCache(products);
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BarcodeScannerPage(
          /// ⭐ CALLBACK WHEN BARCODE SCANNED
          onBarcodeScanned: (barcode) {
            final cleanBarcode = barcode.trim();

            debugPrint("SCANNED: $cleanBarcode");

            final product = _barcodeMap[cleanBarcode];

            if (mode == ScanMode.addProduct) {
              Navigator.pop(context, barcode);

              if (onAddProductScan != null) {
                onAddProductScan(cleanBarcode);
              }

              return;
            }

           if (product == null) {
  showDialog(
    context: context,
    builder: (_) {
      return AlertDialog(
        title: const Text("Product Not Found"),
        content: const Text("Do you want to add this product?"),
        actions: [

          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),

          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // close dialog
              Navigator.pop(context); // close scanner

              /// ⭐ Pass barcode to Add Product Page
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddProductPage(
                    product: Productclass(
                      id: 0,
                      name: "",
                      barcode: cleanBarcode,
                      stock: 0,
                      costPrice: 0,
                      retailPrice: 0,
                      byPieces: 1,
                      isPromo: false,
                      otherQty: 0,
                      productClientUuid: "",
                    ),
                  ),
                ),
              );
            },
            child: const Text("YES, Add Product"),
          ),
        ],
      );
    },
  );

  return;
}

            /// ===============================
            /// CHECK EXISTING ROW
            /// ===============================
            POSRow? existingRow;

            for (var r in rows) {
              if (r.product?.id == product.id) {
                existingRow = r;
                break;
              }
            }

            /// ===============================
            /// UPDATE OR INSERT ROW
            /// ===============================
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

            /// ===============================
            /// AUTO NEXT ROW
            /// ===============================
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

import 'package:cashier/services/scan_mode.dart';
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
          p.barcode!.trim(): p
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

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Product not found"),
                  duration: Duration(milliseconds: 600),
                ),
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
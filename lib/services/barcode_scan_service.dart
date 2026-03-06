import 'package:flutter/material.dart';
import '../view/barcode.dart';
import '../class/posrowclass.dart';
import '../class/productclass.dart';

class BarcodeScanService {

  /// ⭐ SUPER FAST LOOKUP CACHE (POS PERFORMANCE BOOST)
  static Map<String, Productclass> _barcodeMap = {};

  /// Call this when products reload / sync
static void buildBarcodeCache(List<Productclass> products) {
  _barcodeMap = {
    for (var p in products)
      if (p.barcode != null && p.barcode!.trim().isNotEmpty)
        p.barcode!.trim(): p
  };

  print("PRODUCTS LENGTH: ${products.length}");
  print("CACHE KEYS: ${_barcodeMap.keys}");
}

  static Future<void> scanBarcode({
    required BuildContext context,
    required List<Productclass> products,
    required List<POSRow> rows,
    required bool isAutoNextRowOn,
    required VoidCallback refreshUI,
  }) async {

    /// ✅ Build cache if empty
    if (_barcodeMap.isEmpty) {
      buildBarcodeCache(products);
    }

    /// Open scanner
    final scannedResult = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const BarcodeScannerPage(),
      ),
    );

    if (scannedResult == null) return;

 String barcode = scannedResult.toString().trim();

print("✅ Scanned Barcode: $barcode");

/// DEBUG
print("SCANNED: '$barcode'");
print("CACHE HAS: ${_barcodeMap.containsKey(barcode)}");
print("CACHE KEYS: ${_barcodeMap.keys}");

/// ⭐ FAST PRODUCT SEARCH
final product = _barcodeMap[barcode];

    if (product == null) {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Product not found"),
        ),
      );

      return;
    }

    /// ⭐ CHECK EXISTING ROW
    POSRow? existingRow;

    for (var r in rows) {
      if (r.product?.id == product.id) {
        existingRow = r;
        break;
      }
    }

    /// ⭐ UPDATE QTY OR ADD NEW ROW
    if (existingRow != null) {

      existingRow.qty++;

    } else {

      /// Insert before last empty row
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

    /// ⭐ AUTO NEXT ROW
    if (isAutoNextRowOn && rows.last.product != null) {
      rows.add(POSRow());
    }

    refreshUI();
  }
}
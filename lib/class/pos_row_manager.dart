import 'package:cashier/database/local_db.dart';
import 'package:flutter/material.dart';
import '../class/productclass.dart';
import '../class/posrowclass.dart';
import '../widget/productbottomsheet.dart';
import '../widget/qtybottomsheet.dart';

class POSRowManager {
  final BuildContext context;

  POSRowManager(this.context) {
    rows = [POSRow()];
  }

  late List<POSRow> rows;
  Map<int, int> promoCountByProduct = {};

  // ADD EMPTY ROW
  void addEmptyRow() {
    rows.add(POSRow());
  }

  // RESET
  void reset() {
    rows = [POSRow()];
  }

  void reset2() {
    rows = [POSRow()];
    promoCountByProduct.clear();
  }

  // AUTO FILL
  Future<void> autoFillRows(VoidCallback onUpdate) async {
    for (int i = 0; i < rows.length; i++) {
      final row = rows[i];
      if (row.product != null) continue;

      Productclass? selectedProduct;

      while (true) {
        selectedProduct = await showModalBottomSheet<Productclass>(
          context: context,
          barrierColor: Colors.black.withOpacity(0.0),
          isScrollControlled: true,
          builder: (_) => Productbottomsheet(),
        );

        if (selectedProduct == null) break;

        final alreadySelected = rows.any(
          (r) => r.product?.id == selectedProduct!.id,
        );

        if (alreadySelected) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Product already selected in another row!"),
              duration: Duration(seconds: 1),
            ),
          );
          continue;
        }

        break;
      }

      if (selectedProduct == null) break;

      row.product = selectedProduct;
      row.isPromo = selectedProduct.isPromo;

      if (row.isPromo) {
        row.promo_count = 1;
        row.otherQty = selectedProduct.otherQty;
        promoCountByProduct[row.product!.id] = row.promo_count;
      } else {
        row.qty = 1;
        row.otherQty = 0;
      }

      onUpdate();

      if (row == rows.last) addEmptyRow();

      if (!row.isPromo) {
        final qty = await showModalBottomSheet<int>(
          context: context,
          barrierColor: Colors.black.withOpacity(0.0),
          builder: (_) => Qtybottomsheet(stock: row.product!.stock),
        );

        if (qty == null) break;
        row.qty = qty;
        onUpdate();
        if (row == rows.last) addEmptyRow();
      }
    }
  }








Future<void> autoFillFromScannedCodes(
  List<String> codes,
  VoidCallback onUpdate,
) async {

  for (var code in codes) {

    final product = await _findProductByBarcode(code);

    if (product == null) continue;

    final alreadySelected = rows.any(
      (r) => r.product?.id == product.id,
    );

    if (alreadySelected) continue;

    final row = rows.firstWhere(
      (r) => r.product == null,
      orElse: () {
        addEmptyRow();
        return rows.last;
      },
    );

    row.product = product;
    row.isPromo = product.isPromo;
    row.qty = 1;
    row.otherQty = product.otherQty;

    onUpdate();
  }
}

Future<Productclass?> _findProductByBarcode(String barcode) async {

  final db = await LocalDatabase().database;

  final result = await db.query(
    'products',
    where: 'barcode = ?',
    whereArgs: [barcode],
  );

  print("SCAN BARCODE: $barcode");
  print("DB RESULT: $result");

  if (result.isEmpty) return null;

  final product = Productclass.fromMap(result.first);

  print("PRODUCT NAME: ${product.name}");
  print("PRODUCT PRICE: ${product.retailPrice}");

  return product;
}


Future<void> handleScannedBarcode(
  Productclass product,
  VoidCallback onUpdate,
) async {

  final existingRow = rows.firstWhere(
    (r) => r.product?.id == product.id,
    orElse: () => POSRow(),
  );

  if (existingRow.product != null) {

    if (existingRow.isPromo) {
      existingRow.promo_count++;
      existingRow.otherQty =
          existingRow.promo_count *
              (existingRow.product?.otherQty ?? 1);
    } else {
      existingRow.qty++;
    }

  } else {

    final row = rows.firstWhere(
      (r) => r.product == null,
      orElse: () {
        addEmptyRow();
        return rows.last;
      },
    );

    row.product = product;
    row.isPromo = product.isPromo;
    row.qty = 1;
    row.otherQty = product.otherQty;
  }

  onUpdate();
}




















  // MINI QTY CONTROLS
  Widget _buildQuantityControls(POSRow row, VoidCallback onUpdate) {
    int baseQty = row.isPromo ? row.product?.otherQty ?? 1 : 1;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.remove_circle_outline,color: Colors.white,),
          onPressed: () {
            if (row.isPromo) {
              if (row.promo_count > 1) {
                row.promo_count--;
                row.otherQty = row.promo_count * baseQty;
                promoCountByProduct[row.product!.id] = row.promo_count;
              }
            } else {
              if (row.qty > 1) row.qty--;
            }
            onUpdate();
          },
        ),
        Text(
          row.isPromo ? row.promo_count.toString() : row.qty.toString(),
          style: const TextStyle(fontSize: 16, color: Colors.white),
        ),
        IconButton(
          icon: const Icon(Icons.add_circle_outline, color: Colors.white),
          onPressed: () {
            if (row.isPromo) {
              row.promo_count++;
              row.otherQty = row.promo_count * baseQty;
              promoCountByProduct[row.product!.id] = row.promo_count;
            } else {
              row.qty++;
            }
            onUpdate();
          },
        ),
      ],
    );
  }

  // BUILD ROW
  Widget buildRow(
    POSRow row,
    int index, {
    required VoidCallback onUpdate,
    required bool isAutoNextRowOn,
  }) {
    double displayPrice = 0;

print("BUILD ROW PRODUCT: ${row.product?.name}");
print("BUILD ROW PRICE: ${row.product?.retailPrice}");
print("QTY: ${row.qty}");
print("PROMO COUNT: ${row.promo_count}");

    if (row.product != null) {
      displayPrice = row.isPromo
          ? row.product!.retailPrice * row.promo_count
          : (row.product?.retailPrice ?? 0) *
    (row.isPromo ? row.promo_count : row.qty);
    }

    final size = MediaQuery.of(context).size;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    // Portrait stays untouched → Dismissible logic preserved
    final relaxLayout = isLandscape;

    // MAIN ROW WIDGET
    Widget mainRow = Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // PRODUCT NAME — WITH PORTRAIT TRUNCATION + LONG PRESS
        Expanded(
          flex: 3,
          child: GestureDetector(
            onLongPress: () {
              if (!isLandscape && row.product != null) {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text("Product Name"),
                    content: SingleChildScrollView(
                      child: Text(
                        row.product!.name,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Close"),
                      ),
                    ],
                  ),
                );
              }
            },
            child: InkWell(
              onTap: () async {
                if (row.product != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Product already selected, cannot change."),
                      duration: Duration(seconds: 1),
                    ),
                  );
                  return;
                }

                final selectedProduct =
                    await showModalBottomSheet<Productclass>(
                      context: context,
                      barrierColor: Colors.white,
                      isScrollControlled: true,
                      builder: (_) => Productbottomsheet(),
                    );

                if (selectedProduct == null) return;

                final alreadySelected = rows.any(
                  (r) => r != row && r.product?.id == selectedProduct.id,
                );

                if (alreadySelected) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Product already selected in another row!"),
                      duration: Duration(seconds: 1),
                    ),
                  );
                  return;
                }

                row.product = selectedProduct;
                row.isPromo = selectedProduct.isPromo;

                if (row.isPromo) {
                  row.promo_count = 1;
                  row.otherQty = selectedProduct.otherQty;
                  promoCountByProduct[row.product!.id] = row.promo_count;
                } else {
                  row.qty = 1;
                  row.otherQty = 0;
                }

                onUpdate();

                if (!row.isPromo) {
                  final qty = await showModalBottomSheet<int>(
                    context: context,
                    barrierColor: Colors.black.withOpacity(0.0),
                    builder: (_) => Qtybottomsheet(stock: row.product!.stock),
                  );

                  if (qty != null) {
                    row.qty = qty;
                    onUpdate();
                  }
                }

                if (isAutoNextRowOn && row == rows.last) {
                  addEmptyRow();
                  onUpdate();
                }

                if (isAutoNextRowOn) {
                  await autoFillRows(onUpdate);
                }
              },
              child: Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    row.product?.name ?? "Select Product",
                    overflow: isLandscape
                        ? TextOverflow.visible
                        : TextOverflow.ellipsis,
                    maxLines: 1,
                    softWrap: false,
                    style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold,
                  ),
                  ),
                ),
              ),
            ),
          ),
        ),

        const SizedBox(width: 8),

        // QTY BOX
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white),
            borderRadius: BorderRadius.circular(4),
            color: Colors.blue,
          ),
          child: Text(
            row.isPromo ? row.otherQty.toString() : row.qty.toString(),
            textAlign: TextAlign.center,
             style: const TextStyle(
    color: Colors.white,),
          ),
        ),

        const SizedBox(width: 8),

        _buildQuantityControls(row, onUpdate),

        const SizedBox(width: 8),

        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: Text(
              "₱${displayPrice.toStringAsFixed(2)}",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
        ),

        if (relaxLayout)
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () {
              if (row.isPromo && row.product != null) {
                promoCountByProduct.remove(row.product!.id);
              }
              rows.removeAt(index);
              if (rows.isEmpty) reset();
              onUpdate();
            },
          ),
      ],
    );

    // ============================
    // PORTRAIT MODE (Untouched!)
    // ============================
    if (!relaxLayout) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Dismissible( 
          key: ValueKey(row.hashCode),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          onDismissed: (_) {
            if (row.isPromo && row.product != null) {
              promoCountByProduct.remove(row.product!.id);
            }
            rows.removeAt(index);
            if (rows.isEmpty) reset();
            onUpdate();
          },
          child: mainRow,
        ),
      );
    }

    // ============================
    // LANDSCAPE MODE (Fixed width)
    // ============================
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Container(
        width: size.width,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white),
          borderRadius: BorderRadius.circular(6),
        ),
        child: mainRow,
      ),
    );
  }

  // TOTAL BILL
  double get totalBill {
    double total = 0;
    for (var row in rows) {
      if (row.product != null) {
        total += row.isPromo
            ? row.product!.retailPrice * row.promo_count
            : row.product!.retailPrice * row.qty;
      }
    }
    return total;
  }
}

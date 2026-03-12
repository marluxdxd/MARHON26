import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../class/productclass.dart';

class LocalDbService {
  static Database? _db;

  /// =========================
  /// GET DATABASE INSTANCE
  /// =========================
  static Future<Database> getDb() async {
    if (_db != null) return _db!;

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'pos_app.db');

    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE products(
            id INTEGER PRIMARY KEY,
            name TEXT NOT NULL,
            barcode TEXT,
            cost_price REAL DEFAULT 0,
            retail_price REAL DEFAULT 0,
            by_pieces INTEGER DEFAULT 0,
            stock INTEGER NOT NULL,
            low_stock_threshold INTEGER DEFAULT 0,
            is_promo INTEGER DEFAULT 0,
            other_qty INTEGER DEFAULT 0,
            is_synced INTEGER DEFAULT 0,
            client_uuid TEXT UNIQUE,
            updated_at TEXT DEFAULT CURRENT_TIMESTAMP
          )
        ''');
      },
    );

    return _db!;
  }

  /// =========================
  /// GET ALL PRODUCTS
  /// =========================
  static Future<List<Productclass>> getAllProducts() async {
    final db = await getDb();
    final result = await db.query('products');

    return result.map((p) {
      return Productclass(
        id: p['id'] as int,
        name: p['name'].toString(),
        barcode: p['barcode']?.toString() ?? '',
        costPrice: (p['cost_price'] as num).toDouble(),
        retailPrice: (p['retail_price'] as num).toDouble(),
        byPieces: p['by_pieces'] as int? ?? 1,
        stock: p['stock'] as int? ?? 0,
        lowStock: p['low_stock_threshold'] as int? ?? 0,
        isPromo: (p['is_promo'] as int? ?? 0) == 1,
        otherQty: p['other_qty'] as int? ?? 0,
        productClientUuid: p['client_uuid']?.toString() ?? '',
      );
    }).toList();
  }

  /// =========================
  /// GET SINGLE PRODUCT BY BARCODE
  /// =========================
  static Future<Productclass?> getProductByBarcode(String barcode) async {
    final db = await getDb();
    final result = await db.query(
      'products',
      where: 'barcode = ?',
      whereArgs: [barcode],
    );

    if (result.isEmpty) return null;

    final p = result.first;
    return Productclass(
      id: p['id'] as int,
      name: p['name'].toString(),
      barcode: p['barcode']?.toString() ?? '',
      costPrice: (p['cost_price'] as num).toDouble(),
      retailPrice: (p['retail_price'] as num).toDouble(),
      byPieces: p['by_pieces'] as int? ?? 1,
      stock: p['stock'] as int? ?? 0,
      lowStock: p['low_stock_threshold'] as int? ?? 0,
      isPromo: (p['is_promo'] as int? ?? 0) == 1,
      otherQty: p['other_qty'] as int? ?? 0,
      productClientUuid: p['client_uuid']?.toString() ?? '',
    );
  }

  // /// =========================
  // /// INSERT OR UPDATE PRODUCT
  // /// =========================
  // static Future<void> upsertProduct(Productclass product) async {
  //   final db = await getDb();
  //   await db.insert(
  //     'products',
  //     {
  //       'id': product.id,
  //       'name': product.name,
  //       'barcode': product.barcode,
  //       'cost_price': product.costPrice,
  //       'retail_price': product.retailPrice,
  //       'by_pieces': product.byPieces,
  //       'stock': product.stock,
  //       'low_stock_threshold': product.lowStock,
  //       'is_promo': product.isPromo ? 1 : 0,
  //       'other_qty': product.otherQty,
  //       'is_synced': 0,
  //       'client_uuid': product.productClientUuid,
  //     },
  //     conflictAlgorithm: ConflictAlgorithm.replace,
  //   );
  // }

  // /// =========================
  // /// DELETE PRODUCT BY ID
  // /// =========================
  // static Future<void> deleteProduct(int id) async {
  //   final db = await getDb();
  //   await db.delete(
  //     'products',
  //     where: 'id = ?',
  //     whereArgs: [id],
  //   );
  // }

  // /// =========================
  // /// OPTIONAL: CLEAR ALL PRODUCTS
  // /// =========================
  // static Future<void> clearProducts() async {
  //   final db = await getDb();
  //   await db.delete('products');
  // }
}
import 'package:supabase_flutter/supabase_flutter.dart';

class Productclass {
  final int id;
  final String name;
  final String barcode;
  final double retailPrice;
  final double costPrice;
  int stock;
  int byPieces;
  final bool isPromo;
  final int otherQty;
  final String type; // 'add', 'update', 'delete' for sync
  final String productClientUuid;
  final int lowStock;
  String? userid;

  Productclass({
    required this.id,
    required this.name,
    required this.barcode,
    required this.retailPrice,
    required this.costPrice,
    required this.stock,
    required this.byPieces,
    required this.productClientUuid, // ✅ REQUIRED
    this.isPromo = false, // default false
    this.otherQty = 0, // default 0
    this.type = 'add',
    this.lowStock = 0, // default 0
    this.userid,
  });

  // Convert to Map for Supabase insert/update
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'barcode': barcode,
      'retail_price': retailPrice,
      'cost_price': costPrice,
      'stock': stock,
      'by_pieces': byPieces,
      'is_promo': isPromo,
      'other_qty': otherQty,
      'client_uuid': productClientUuid,
      'type': type,
      'low_stock_threshold': lowStock, // ✅ Add low stock threshold
      'user_id': userid,
    };
  }

  // Convert Supabase row → Productclass
  factory Productclass.fromMap(Map<String, dynamic> map) {
    return Productclass(
      id: map['id'],
      name: map['name'],
      barcode: map['barcode'] ?? '',
      retailPrice: double.tryParse(map['retail_price'].toString()) ?? 0,
      costPrice: double.tryParse(map['cost_price'].toString()) ?? 0,
      stock: map['stock'],
      isPromo: map['is_promo'] == true || map['is_promo'] == 1,
      otherQty: map['other_qty'] ?? 0,
      productClientUuid: map['client_uuid'] as String,
      type: map['type'] ?? 'add',
      byPieces: int.tryParse(map['by_pieces'].toString()) ?? 0,
      lowStock: map['low_stock_threshold'] ?? 0, // ✅ Add low stock threshold
      userid: map['user_id'],
    );
  }

  // Fetch all products from Supabase
  static Future<List<Productclass>> fetchProducts() async {
    final data = await Supabase.instance.client.from('products').select();

    return (data as List<dynamic>)
        .map((e) => Productclass.fromMap(e as Map<String, dynamic>))
        .toList();
  }
}

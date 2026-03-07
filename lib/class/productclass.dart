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
    };
  }

  // Convert Supabase row → Productclass
  factory Productclass.fromMap(Map<String, dynamic> map) {
    return Productclass(
      id: map['id'],
      name: map['name'],
      barcode: map['barcode'] ?? '',
      retailPrice: map['retail_price'] is int
          ? (map['retail_price'] as int).toDouble()
          : map['retail_price'],
      costPrice: map['cost_price'] is int
          ? (map['cost_price'] as int).toDouble()
          : map['cost_price'],
      stock: map['stock'],
      isPromo: map['is_promo'] == true || map['is_promo'] == 1,
      otherQty: map['other_qty'] ?? 0,
      productClientUuid: map['client_uuid'] as String,
      type: map['type'] ?? 'add',
      byPieces: (map['by_pieces'] ?? map['byPieces'] ?? 0) is int
        ? (map['by_pieces'] ?? map['byPieces'] ?? 0)
        : (map['by_pieces'] ?? map['byPieces'] ?? 0).toInt(),
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

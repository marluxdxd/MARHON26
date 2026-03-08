import 'package:cashier/class/productclass.dart';

class ProductCache {
  static final ProductCache _instance = ProductCache._internal();

  factory ProductCache() => _instance;

  ProductCache._internal();

  final Map<int, Productclass> _products = {};

  void load(List<Productclass> list) {
    _products.clear();

    for (var p in list) {
      _products[p.id] = p;
    }
  }

  Productclass? get(int id) {
    return _products[id];
  }
}
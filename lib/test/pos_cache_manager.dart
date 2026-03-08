// import '../class/productclass.dart';

// class POSCacheManager {

//   static final Map<int, Productclass> productCache = {};
//   static final Map<String, Productclass> barcodeCache = {};

//   /// BUILD CACHE
//   static void build(List<Productclass> products) {

//     productCache.clear();
//     barcodeCache.clear();

//     for (var p in products) {

//       productCache[p.id] = p;

//       if (p.barcode != null && p.barcode!.isNotEmpty) {
//         barcodeCache[p.barcode!.trim()] = p;
//       }
//     }
//   }

//   static Productclass? getById(int id) => productCache[id];

//   static Productclass? getByBarcode(String barcode) =>
//       barcodeCache[barcode.trim()];
// }
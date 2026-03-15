import 'package:cashier/services/product_service.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vibration/vibration.dart';

import '../class/productclass.dart';
import '../database/local_db.dart';

class BarcodeScannerPage extends StatefulWidget {
  final Function(String barcode) onBarcodeScanned;

  const BarcodeScannerPage({
    super.key,
    required this.onBarcodeScanned,
  });

  @override
  State<BarcodeScannerPage> createState() => _BarcodeScannerPageState();
}

class _BarcodeScannerPageState extends State<BarcodeScannerPage> {
  Productclass? scannedProduct;
  Set<String> scannedCodes = {}; // ✅ Keep all scanned barcodes to avoid duplicates
  List<Productclass> scannedList = [];

  final MobileScannerController controller =
      MobileScannerController(facing: CameraFacing.back, torchEnabled: false);
  final AudioPlayer player = AudioPlayer();

  bool isProcessing = false;
  double scanLinePosition = 0;
  bool isTorchOn = false;

  @override
  void initState() {
    super.initState();
    _refreshLocalProducts();

    // Scan line animation
    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 16));
      if (!mounted) return false;
      setState(() {
        scanLinePosition += 3;
        if (scanLinePosition > 220) scanLinePosition = 0;
      });
      return true;
    });
  }

  @override
  void dispose() {
    controller.dispose();
    player.dispose();
    super.dispose();
  }

  Future<Productclass?> _findProduct(String barcode) async {
    final db = await LocalDatabase().database;
    final result =
        await db.query('products', where: 'barcode = ? AND user_id = ?', whereArgs: [barcode,Supabase.instance.client.auth.currentUser!.id], limit: 1);
    if (result.isEmpty) return null;
    return Productclass.fromMap(result.first);
  }

  Future<void> _refreshLocalProducts() async {
    final productService = ProductService();
    final online = await productService.isOnline1();
    if (online) await productService.syncOnlineProducts();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (isProcessing) return;

    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final code = barcodes.first.rawValue;
    if (code == null) return;

    final barcode = code.trim();
    if (barcode.isEmpty) return;

    // ✅ Skip if barcode already scanned
    if (scannedCodes.contains(barcode)) return;

    isProcessing = true;
    scannedCodes.add(barcode); // Add to set to prevent duplicates

    final product = await _findProduct(barcode);

    // 🔹 DEBUG: Print scanned barcode and product info
    if (product != null) {
      debugPrint("✅ PRODUCT SCANNED BARCODE: $barcode");
      debugPrint("➡️ PRODUCT ID: ${product.id}");
      debugPrint("➡️ PRODUCT NAME: ${product.name}");
      debugPrint("➡️ PRODUCT PRICE: ₱${product.retailPrice}");
    } else {
      debugPrint("❌ PRODUCT NOT FOUND FOR BARCODE: $barcode");
    }

    setState(() {
      scannedProduct = product;
      if (product != null) scannedList.add(product);
    });

    widget.onBarcodeScanned(barcode);

    try {
      await player.play(AssetSource('sounds/beep.mp3'));
    } catch (_) {}

    if (await Vibration.hasVibrator() ?? false) Vibration.vibrate(duration: 70);

    await Future.delayed(const Duration(milliseconds: 300)); // short debounce
    isProcessing = false;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final boxWidth = 300.0;
    final boxHeight = 220.0;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Barcode Scanner"),
        centerTitle: true,
        backgroundColor: Colors.black87,
      ),
      body: Stack(
        children: [
          MobileScanner(controller: controller, onDetect: _onDetect),

          // Overlay painter
          Positioned.fill(
            child: CustomPaint(
              painter: _ScanOverlayPainter(
                boxWidth: boxWidth,
                boxHeight: boxHeight,
                screenWidth: screenWidth,
                screenHeight: screenHeight,
              ),
            ),
          ),

          // Scan box border
          Positioned(
            top: screenHeight * 0.15,
            left: (screenWidth - boxWidth) / 2,
            child: Container(
              width: boxWidth,
              height: boxHeight,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.greenAccent, width: 3),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),

          // Laser scan line
          Positioned(
            top: screenHeight * 0.15 + scanLinePosition,
            left: (screenWidth - boxWidth) / 2,
            child: Container(
              width: boxWidth,
              height: 3,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.red.withOpacity(0.0),
                    Colors.red,
                    Colors.red.withOpacity(0.0)
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(1.5),
              ),
            ),
          ),

          // Torch toggle using Stack + GestureDetector
          Positioned(
            top: screenHeight * 0.08,
            left: (screenWidth - 60) / 2, // adjust para center
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Circle background
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isTorchOn ? Colors.yellowAccent : Colors.white70,
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 6,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                ),
                // Icon with GestureDetector
                GestureDetector(
                  onTap: () async {
                    await controller.toggleTorch();
                    setState(() => isTorchOn = !isTorchOn);
                  },
                  child: Icon(
                    isTorchOn ? Icons.flashlight_on : Icons.flashlight_off,
                    color: Colors.black,
                    size: 28,
                  ),
                ),
              ],
            ),
          ),

          // Product preview
          if (scannedProduct != null)
            Positioned(
              top: screenHeight * 0.15 + boxHeight + 20,
              left: 20,
              right: 20,
              child: Card(
                color: Colors.black87,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 8,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.inventory_2, color: Colors.white, size: 40),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              scannedProduct!.name,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            Text("Barcode: ${scannedProduct!.barcode}",
                                style: const TextStyle(color: Color.fromARGB(179, 20, 11, 11))),
                            Text("Price: ₱${scannedProduct!.retailPrice.toStringAsFixed(2)}",
                                style: const TextStyle(
                                    color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Scanned list
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 300,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
              ),
              child: ListView.builder(
                itemCount: scannedList.length,
                itemBuilder: (context, index) {
                  final p = scannedList[index];
                  return ListTile(
                    leading: CircleAvatar(
                      radius: 14,
                      backgroundColor: Colors.greenAccent,
                      child: Text(
                        "${index + 1}",
                        style: const TextStyle(fontSize: 12, color: Colors.black),
                      ),
                    ),
                    title: Text(p.name),
                    subtitle: Text("₱${p.retailPrice.toStringAsFixed(2)}"),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScanOverlayPainter extends CustomPainter {
  final double boxWidth;
  final double boxHeight;
  final double screenWidth;
  final double screenHeight;

  _ScanOverlayPainter({
    required this.boxWidth,
    required this.boxHeight,
    required this.screenWidth,
    required this.screenHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black54;
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, screenWidth, screenHeight))
      ..addRRect(RRect.fromRectAndRadius(
          Rect.fromLTWH(
            (screenWidth - boxWidth) / 2,
            screenHeight * 0.15,
            boxWidth,
            boxHeight,
          ),
          const Radius.circular(16)))
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
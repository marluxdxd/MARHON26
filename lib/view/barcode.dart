import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:audioplayers/audioplayers.dart';
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
  String? lastScannedCode;

  List<Productclass> scannedList = [];

  final MobileScannerController controller =
      MobileScannerController(facing: CameraFacing.back);

  final AudioPlayer player = AudioPlayer();

  bool isProcessing = false;
  double scanLinePosition = 0;

  @override
  void initState() {
    super.initState();

    /// Scan line animation
    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 16));

      if (!mounted) return false;

      setState(() {
        scanLinePosition += 2;
        if (scanLinePosition > 160) scanLinePosition = 0;
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

  /// ===============================
  /// PRODUCT LOOKUP (SQLite)
  /// ===============================
  Future<Productclass?> _findProduct(String barcode) async {
    final db = await LocalDatabase().database;

    final result = await db.query(
      'products',
      where: 'barcode = ?',
      whereArgs: [barcode],
      limit: 1,
    );

    if (result.isEmpty) return null;

    return Productclass.fromMap(result.first);
  }

  /// ===============================
  /// SCAN ENGINE
  /// ===============================
  Future<void> _onDetect(BarcodeCapture capture) async {
    if (isProcessing) return;

    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final code = barcodes.first.rawValue;
    if (code == null) return;

    final barcode = code.trim();
    if (barcode.isEmpty) return;

    /// Prevent duplicate scan
    if (barcode == lastScannedCode) return;

    isProcessing = true;
    lastScannedCode = barcode;

    final product = await _findProduct(barcode);

    setState(() {
      scannedProduct = product;

      /// Add to list if found
      if (product != null) {
        scannedList.add(product);
      }
    });

    widget.onBarcodeScanned(barcode);

    /// Sound
    try {
      await player.play(AssetSource('sounds/beep.mp3'));
    } catch (_) {}

    /// Vibrate
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 70);
    }

    await Future.delayed(const Duration(milliseconds: 300));

    isProcessing = false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Supermarket Scanner"),
        centerTitle: true,
      ),

      body: Stack(
        children: [

          /// CAMERA
          MobileScanner(
            controller: controller,
            onDetect: _onDetect,
          ),

          /// SCAN BOX
          Center(
            child: Container(
              width: 260,
              height: 160,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.green, width: 3),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          /// LASER SCAN LINE
          Positioned(
            top: MediaQuery.of(context).size.height / 2 - 80 + scanLinePosition,
            left: MediaQuery.of(context).size.width / 2 - 130,
            child: Container(
              width: 260,
              height: 2,
              color: Colors.red,
            ),
          ),

          /// PRODUCT PREVIEW
          if (scannedProduct != null)
            Positioned(
              bottom: 200,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [

                    const Icon(
                      Icons.inventory_2,
                      color: Colors.white,
                      size: 40,
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          Text(
                            scannedProduct!.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          Text(
                            "Barcode: ${scannedProduct!.barcode}",
                            style: const TextStyle(color: Colors.white70),
                          ),

                          Text(
                            "Price: ₱${scannedProduct!.retailPrice.toStringAsFixed(2)}",
                            style: const TextStyle(
                              color: Colors.greenAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),

          /// SCANNED LIST (POS STYLE)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 180,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: ListView.builder(
                itemCount: scannedList.length,
                itemBuilder: (context, index) {
                  final p = scannedList[index];

                  return ListTile(
                    leading: Text("${index + 1}."),
                    title: Text(p.name),
                    subtitle: Text(
                      "₱${p.retailPrice.toStringAsFixed(2)}",
                    ),
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
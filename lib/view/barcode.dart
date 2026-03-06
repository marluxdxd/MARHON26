import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';

class BarcodeScannerPage extends StatefulWidget {
  const BarcodeScannerPage({super.key});

  @override
  State<BarcodeScannerPage> createState() => _BarcodeScannerPageState();
}

class _BarcodeScannerPageState extends State<BarcodeScannerPage> {

  bool isScanned = false;

  final MobileScannerController controller = MobileScannerController();
  final AudioPlayer player = AudioPlayer();

  @override
  void dispose() {
    controller.dispose();
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Scan Barcode")),
      body:MobileScanner(
  onDetect: (capture) async {
    if (isScanned) return;

    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? code = barcodes.first.rawValue;
    if (code == null || code.trim().isEmpty) return;

    isScanned = true;

    // play beep
    player.play(AssetSource('sounds/beep.mp3'));

    // vibrate
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 100);
    }

    // return barcode
    Navigator.pop(context, code.trim());
  },
),
    );
  }
}
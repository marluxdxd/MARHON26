import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';

class EnterpriseScannerPage extends StatefulWidget {
  const EnterpriseScannerPage({super.key});

  @override
  State<EnterpriseScannerPage> createState() =>
      _EnterpriseScannerPageState();
}

class _EnterpriseScannerPageState extends State<EnterpriseScannerPage> {

  final MobileScannerController controller =
      MobileScannerController();

  final AudioPlayer player = AudioPlayer();

  bool isProcessing = false;

  @override
  void dispose() {
    controller.dispose();
    player.dispose();
    super.dispose();
  }

  Future<void> successFeedback() async {
    try {
      await player.play(AssetSource("sounds/beep.mp3"));
    } catch (_) {}

    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 80);
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(title: const Text("Scan Product")),

      body: MobileScanner(
        controller: controller,

        onDetect: (capture) async {

          if (isProcessing) return;

          final barcodes = capture.barcodes;
          if (barcodes.isEmpty) return;

          final code = barcodes.first.rawValue;
          if (code == null || code.trim().isEmpty) return;

          isProcessing = true;

          /// ⭐ Stop camera first
          await controller.stop();

          await successFeedback();

          if (!mounted) return;

          /// ⭐ Return barcode only
          Navigator.pop(context, code.trim());
        },
      ),
    );
  }
}
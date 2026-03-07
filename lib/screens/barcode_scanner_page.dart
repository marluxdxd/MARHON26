// import 'package:flutter/material.dart';
// import 'package:mobile_scanner/mobile_scanner.dart';
// import 'package:audioplayers/audioplayers.dart';
// import 'package:vibration/vibration.dart';

// class BarcodeScannerPage extends StatefulWidget {
//   const BarcodeScannerPage({super.key});

//   @override
//   State<BarcodeScannerPage> createState() => _BarcodeScannerPageState();
// }

// class _BarcodeScannerPageState extends State<BarcodeScannerPage> {

//   final MobileScannerController controller = MobileScannerController();
//   final AudioPlayer player = AudioPlayer();

//   List<String> scannedCodes = [];
//   bool processing = false;

//   @override
//   void dispose() {
//     controller.dispose();
//     player.dispose();
//     super.dispose();
//   }

//   Future<void> _onDetect(BarcodeCapture capture) async {

//   if (isProcessing) return;

//   final barcodes = capture.barcodes;
//   if (barcodes.isEmpty) return;

//   final code = barcodes.first.rawValue;
//   if (code == null) return;

//   final cleanCode = code.trim();
//   if (cleanCode.isEmpty) return;

//   isProcessing = true;

//   /// 🔥 Find product name from DB or product list
//   final product = await _findProductByBarcode(cleanCode);

//   setState(() {
//     lastDetectedProductName =
//         product?.name ?? "Unknown Product";
//   });

//   /// 🔥 Beep + vibration
//   await player.play(AssetSource('sounds/beep.mp3'));

//   if (await Vibration.hasVibrator() ?? false) {
//     Vibration.vibrate(duration: 80);
//   }

//   /// 🔥 Return barcode to POS (continue scanning)
//   if (mounted) {
//     Navigator.pop(context, cleanCode);
//   }

//   await Future.delayed(const Duration(milliseconds: 300));

//   isProcessing = false;
// }

//   @override
//   Widget build(BuildContext context) {

//     return Scaffold(
//       appBar: AppBar(title: const Text("Scan Barcode")),
//       body: Column(
//         children: [

//           Expanded(
//             flex: 2,
//             child: MobileScanner(
//               controller: controller,
//               onDetect: _onDetect,
//             ),
//           ),

//           Expanded(
//             child: ListView.builder(
//               itemCount: scannedCodes.length,
//               itemBuilder: (_, i) {
//                 return ListTile(
//                   title: Text(scannedCodes[i]),
//                 );
//               },
//             ),
//           )

//         ],
//       ),
//     );
//   }
// }
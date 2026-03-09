import 'package:flutter/material.dart';

class BarcodeFAB extends StatelessWidget {
  final VoidCallback onPressed;
  final Object? heroTag; // optional, for unique Hero tags

  const BarcodeFAB({
    super.key,
    required this.onPressed,
    this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, 22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: 'null', // default unique tag
            backgroundColor: Colors.white,
            onPressed: onPressed,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(
                color: Colors.blue,
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.qr_code_scanner_sharp,
              size: 30,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            "Barcode",
            style: TextStyle(
              fontSize: 9,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
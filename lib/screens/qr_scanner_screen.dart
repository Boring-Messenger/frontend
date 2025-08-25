import 'package:flutter/material.dart';
// import 'package:mobile_scanner/mobile_scanner.dart'; // Uncomment when implementing

class QRScannerScreen extends StatelessWidget {
  const QRScannerScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan QR Code')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 250,
              height: 250,
              color: Colors.grey[300],
              child: const Center(child: Text('QR Scanner Placeholder')),
              // child: MobileScanner(...), // Uncomment for real scanner
            ),
            const SizedBox(height: 16),
            const Text('Point your camera at a QR code'),
          ],
        ),
      ),
    );
  }
}

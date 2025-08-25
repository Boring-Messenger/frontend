import 'package:flutter/material.dart';
// import 'package:qr_flutter/qr_flutter.dart'; // Uncomment when implementing

class QRCodeScreen extends StatelessWidget {
  const QRCodeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Placeholder session ID
    final sessionId = 'SESSION123456';
    return Scaffold(
      appBar: AppBar(title: const Text('Your QR Code')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Placeholder for QR code
            Container(
              width: 200,
              height: 200,
              color: Colors.grey[300],
              child: const Center(child: Text('QR Code Placeholder')),
              // child: QrImage(data: sessionId, size: 200), // Uncomment for real QR
            ),
            const SizedBox(height: 16),
            Text('Session ID: $sessionId'),
          ],
        ),
      ),
    );
  }
}

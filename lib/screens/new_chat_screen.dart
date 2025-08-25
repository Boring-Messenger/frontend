import 'package:flutter/material.dart';

class NewChatScreen extends StatelessWidget {
  const NewChatScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Chat')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Scan QR Code'),
              onPressed: () {
                Navigator.pushNamed(context, '/qr_scanner');
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.qr_code),
              label: const Text('Generate QR Code'),
              onPressed: () {
                Navigator.pushNamed(context, '/qr_code');
              },
            ),
          ],
        ),
      ),
    );
  }
}

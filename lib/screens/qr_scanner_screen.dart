import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../services/profile_service.dart';
import '../services/qr_service.dart';
import '../services/chat_service.dart';
import 'chat_screen.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  bool _handled = false;

  void _onDetect(BarcodeCapture capture) async {
    if (_handled) return;
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;
    final value = barcodes.first.rawValue;
    if (value == null) return;
    final parsed = QrService().parsePayload(value);
    if (parsed == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid QR code')));
      }
      return;
    }
    final myId = await ProfileService().getOrCreateUserId();
    if (parsed.userId == myId) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('That is your own QR')));
      }
      return;
    }
    _handled = true;
    try {
      final myProfile = await ProfileService().loadLocalProfile();
      final myName = myProfile?.username ?? 'Me';
      final roomId = await ChatService().createOrGetRoomByUserId(
        myUserId: myId,
        myUsername: myName,
        otherUserId: parsed.userId,
        otherUsername: parsed.username,
      );
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ChatScreen(roomId: roomId)));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to join chat')));
      }
      _handled = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Align(
          alignment: Alignment.centerLeft,
          child: Text('Scan QR Code'),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Scan friend's QR code",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              'Scan friends QR code to establish a connection and start texting!',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: MobileScanner(
                    onDetect: _onDetect,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text(
                'Point your camera at a QR code',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

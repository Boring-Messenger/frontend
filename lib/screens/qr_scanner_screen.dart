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
      appBar: AppBar(title: const Text('Scan QR Code')),
      body: Column(
        children: [
          Expanded(
            child: MobileScanner(
              onDetect: _onDetect,
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(12.0),
            child: Text('Point your camera at a QR code'),
          ),
        ],
      ),
    );
  }
}

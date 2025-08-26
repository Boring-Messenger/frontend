import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/services.dart';

import '../services/profile_service.dart';
import '../services/qr_service.dart';

class QRCodeScreen extends StatefulWidget {
  const QRCodeScreen({super.key});

  @override
  State<QRCodeScreen> createState() => _QRCodeScreenState();
}

class _QRCodeScreenState extends State<QRCodeScreen> {
  String? _payload;

  @override
  void initState() {
    super.initState();
    _buildPayload();
  }

  Future<void> _buildPayload() async {
    final id = await ProfileService().getOrCreateUserId();
    final profile = await ProfileService().loadLocalProfile();
    final name = profile?.username ?? 'User';
    final payload = QrService().buildPayload(userId: id, username: name);
    if (!mounted) return;
    setState(() => _payload = payload);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your QR Code')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_payload == null)
              const SizedBox(
                width: 200,
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              )
            else
              QrImageView(data: _payload!, size: 220),
            const SizedBox(height: 16),
            if (_payload != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _payload!));
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('QR payload copied')));
                    },
                    icon: const Icon(Icons.copy),
                    label: const Text('Copy payload'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

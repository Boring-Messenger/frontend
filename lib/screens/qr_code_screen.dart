import 'package:flutter/material.dart';
import 'dart:async';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/services.dart';

import '../services/profile_service.dart';
import '../services/qr_service.dart';
import '../services/chat_service.dart';
import 'chat_screen.dart';

class QRCodeScreen extends StatefulWidget {
  const QRCodeScreen({super.key});

  @override
  State<QRCodeScreen> createState() => _QRCodeScreenState();
}

class _QRCodeScreenState extends State<QRCodeScreen> {
  String? _payload;
  Timer? _pollTimer;
  Set<String> _knownRoomIds = {};

  @override
  void initState() {
    super.initState();
    _buildPayload();
    _startPollingForActivation();
  }

  Future<void> _buildPayload() async {
    final id = await ProfileService().getOrCreateUserId();
    final profile = await ProfileService().loadLocalProfile();
    final name = profile?.username ?? 'User';
    final payload = QrService().buildPayload(userId: id, username: name);
    if (!mounted) return;
    setState(() => _payload = payload);
  }

  void _startPollingForActivation() async {
    final myUserId = await ProfileService().getOrCreateUserId();
    // Seed known rooms from local DB
    final existing = await ChatService().recentRooms();
    _knownRoomIds = existing.map((e) => e.roomId).toSet();
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (t) async {
      // Resync will pull newly activated rooms based on per-user index
      await ChatService().resyncForUser(myUserId, pullLastNMessages: 10);
      final rooms = await ChatService().recentRooms();
      for (final r in rooms) {
        if (!_knownRoomIds.contains(r.roomId)) {
          _knownRoomIds.add(r.roomId);
          if (!mounted) return;
          // Navigate into the newly activated chat
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => ChatScreen(roomId: r.roomId)),
          );
          break;
        }
      }
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
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

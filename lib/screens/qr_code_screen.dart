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
      appBar: AppBar(
        title: const Align(
          alignment: Alignment.centerLeft,
          child: Text('Your QR Code'),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Show QR to friend',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              'Show this QR to friend and once done return to home and wait for your friend to initiate the chat',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: _payload == null
                  ? const SizedBox(
                      width: 200,
                      height: 200,
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(32),
                      ),
                      child: QrImageView(data: _payload!, size: 220),
                    ),
            ),
            const SizedBox(height: 16),
            if (_payload != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FilledButton.icon(
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

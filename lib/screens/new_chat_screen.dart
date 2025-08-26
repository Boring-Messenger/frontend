import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../services/chat_service.dart';
import '../services/profile_service.dart';
import 'chat_screen.dart';

class NewChatScreen extends StatefulWidget {
  const NewChatScreen({Key? key}) : super(key: key);

  @override
  State<NewChatScreen> createState() => _NewChatScreenState();
}

class _NewChatScreenState extends State<NewChatScreen> {
  final _roomCtrl = TextEditingController();
  final _otherIdCtrl = TextEditingController();
  final _otherNameCtrl = TextEditingController();
  final _uuid = const Uuid();
  bool _busy = false;

  @override
  void dispose() {
  _roomCtrl.dispose();
  _otherIdCtrl.dispose();
  _otherNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _join(String roomId) async {
    if (roomId.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a room ID')));
      return;
    }
    setState(() => _busy = true);
    try {
      final profile = await ProfileService().loadLocalProfile();
      final userId = await ProfileService().getOrCreateUserId();
      final username = profile?.username ?? 'User';
      await ChatService().createOrJoinRoom(roomId: roomId.trim(), userId: userId, username: username);
      if (!mounted) return;
      Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(roomId: roomId.trim())));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to join room')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _create() async {
    // Temporary: unique chat by userIds
    final otherId = _otherIdCtrl.text.trim();
    final otherName = _otherNameCtrl.text.trim().isEmpty ? 'User' : _otherNameCtrl.text.trim();
    if (otherId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter other user ID')));
      return;
    }
    setState(() => _busy = true);
    try {
      final myId = await ProfileService().getOrCreateUserId();
      final myProfile = await ProfileService().loadLocalProfile();
      final myName = myProfile?.username ?? 'Me';
      final roomId = await ChatService().createOrGetRoomByUserId(
        myUserId: myId,
        myUsername: myName,
        otherUserId: otherId,
        otherUsername: otherName,
      );
      if (!mounted) return;
      Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(roomId: roomId)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to create/get room')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: SafeArea(
          child: Container(
            margin: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      'New Chat',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _SquareButton(
                  icon: Icons.qr_code_scanner,
                  label: 'Scan QR',
                  onTap: () => Navigator.pushNamed(context, '/qr_scanner'),
                ),
                const SizedBox(width: 16),
                _SquareButton(
                  icon: Icons.qr_code,
                  label: 'My QR',
                  onTap: () => Navigator.pushNamed(context, '/qr_code'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 12),
            Text('Manual join (for testing now)', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            TextField(
              controller: _roomCtrl,
              decoration: const InputDecoration(
                labelText: 'Room ID',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            Text('Unique chat by userId (pre-QR)', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            TextField(
              controller: _otherIdCtrl,
              decoration: const InputDecoration(
                labelText: 'Other user ID',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _otherNameCtrl,
              decoration: const InputDecoration(
                labelText: 'Other user name (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _busy ? null : _create,
                    icon: const Icon(Icons.add),
                    label: const Text('Create Room'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _busy ? null : () => _join(_roomCtrl.text),
                    icon: const Icon(Icons.login),
                    label: const Text('Join Room'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SquareButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _SquareButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      height: 140,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: EdgeInsets.zero,
        ),
        onPressed: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40),
            const SizedBox(height: 12),
            Text(label, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

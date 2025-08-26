import 'package:flutter/material.dart';

import '../models/chat_message.dart';
import '../services/chat_service.dart';
import '../services/profile_service.dart';
import '../models/chat_room.dart';
import '../models/contact.dart';
import 'package:sqflite/sqflite.dart';
import '../services/local_db_service.dart';

class ChatScreen extends StatefulWidget {
  final String roomId;
  const ChatScreen({super.key, required this.roomId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _msgCtrl = TextEditingController();
  late final Stream<List<ChatMessage>> _stream;
  String _userId = '';
  String? _title;

  @override
  void initState() {
    super.initState();
    _stream = ChatService().messageStream(widget.roomId);
    ProfileService().getOrCreateUserId().then((id) => setState(() => _userId = id));
  _loadTitle();
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadTitle() async {
    final db = await LocalDbService().database;
    final rooms = await db.query('chat_rooms', where: 'room_id = ?', whereArgs: [widget.roomId], limit: 1);
    if (rooms.isNotEmpty) {
      final chatRoom = ChatRoom.fromMap(rooms.first);
      if (chatRoom.contactId != null) {
        final contact = await ChatService().getContact(chatRoom.contactId!);
        if (!mounted) return;
        setState(() => _title = contact?.username ?? chatRoom.contactId);
        return;
      }
    }
    if (mounted) setState(() => _title = 'Room ${widget.roomId}');
  }

  Future<void> _send() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    try {
      await ChatService().sendMessage(roomId: widget.roomId, userId: _userId, content: text);
      _msgCtrl.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to send message')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
  appBar: AppBar(title: Text(_title ?? '...')),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: _stream,
              builder: (context, snapshot) {
                final messages = snapshot.data ?? const <ChatMessage>[];
                return ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final m = messages[index];
                    final mine = m.senderId == _userId;
                    return Align(
                      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        decoration: BoxDecoration(
                          color: mine ? Colors.blue[200] : Colors.grey[300],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            Text(m.content),
                            const SizedBox(height: 4),
                            Text(
                              DateTime.fromMillisecondsSinceEpoch(m.timestamp).toLocal().toString().substring(11, 16),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _msgCtrl,
                      decoration: const InputDecoration(
                        hintText: 'Type a message',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: _send,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

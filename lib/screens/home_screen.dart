import 'package:flutter/material.dart';
import 'dart:async';
import '../models/chat_room.dart';
import '../services/chat_service.dart';
import 'chat_screen.dart';
import '../services/profile_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  List<ChatRoom> _rooms = const [];
  bool _loading = true;
  StreamSubscription? _roomsSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  _resyncAndLoad();
  _startRoomsListener();
  }

  @override
  void dispose() {
  _roomsSub?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _resyncAndLoad();
    }
  }

  Future<void> _resyncAndLoad() async {
    final myUserId = await ProfileService().getOrCreateUserId();
    await ChatService().resyncForUser(myUserId);
    await _load();
  }

  Future<void> _startRoomsListener() async {
    final myUserId = await ProfileService().getOrCreateUserId();
    _roomsSub?.cancel();
    _roomsSub = ChatService().userRoomsStream(myUserId).listen((_) {
      if (!mounted) return;
      _resyncAndLoad();
    });
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final rooms = await ChatService().recentRooms();
    if (!mounted) return;
    setState(() {
      _rooms = rooms;
      _loading = false;
    });
  }

  Future<void> _deleteRoom(ChatRoom r) async {
    final myUserId = await ProfileService().getOrCreateUserId();
    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete conversation?'),
        content: Text('This will remove the chat with ${r.contactId ?? r.roomId} from this device.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ChatService().leaveRoom(r.roomId, myUserId);
      await ChatService().deleteRoomLocal(r.roomId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Conversation deleted')));
      _load();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to delete')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _resyncAndLoad,
              child: ListView.builder(
                itemCount: _rooms.length,
                itemBuilder: (context, index) {
                  final r = _rooms[index];
                  return FutureBuilder(
                    future: r.contactId != null ? ChatService().getContact(r.contactId!) : Future.value(null),
                    builder: (context, snapshot) {
                      final contact = snapshot.data;
                      final title = contact?.username ?? (r.contactId ?? 'Room ${r.roomId}');
                      return Dismissible(
                        key: ValueKey(r.roomId),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          alignment: Alignment.centerRight,
                          color: Colors.red,
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        confirmDismiss: (_) async {
                          await _deleteRoom(r);
                          return false; // handled manually
                        },
                        child: ListTile(
                          title: Text(title),
                          subtitle: Text(r.lastMessage ?? 'No messages yet'),
                          leading: const CircleAvatar(child: Icon(Icons.forum)),
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(roomId: r.roomId)));
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.pushNamed(context, '/new_chat');
          if (!mounted) return;
          _resyncAndLoad();
        },
        tooltip: 'Start New Chat',
        child: const Icon(Icons.add),
      ),
    );
  }
}

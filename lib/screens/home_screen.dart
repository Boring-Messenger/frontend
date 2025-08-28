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
  title: const Align(
    alignment: Alignment.centerLeft,
    child: Text('Boring Messenger'),
  ),
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
    : (_rooms.isEmpty
    ? _buildEmptyState(context)
    : RefreshIndicator(
        onRefresh: _resyncAndLoad,
        child: ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      itemCount: _rooms.length,
      itemBuilder: (context, index) {
        final r = _rooms[index];
        return FutureBuilder(
          future: r.contactId != null
          ? ChatService().getContact(r.contactId!)
          : Future.value(null),
          builder: (context, snapshot) {
        final contact = snapshot.data;
        final title = contact?.username ?? (r.contactId ?? 'Room ${r.roomId}');
        return Dismissible(
          key: ValueKey(r.roomId),
          direction: DismissDirection.endToStart,
          background: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.centerRight,
            color: Theme.of(context).colorScheme.error,
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          confirmDismiss: (_) async {
            await _deleteRoom(r);
            return false; 
          },
          child: Card(
            elevation: 0,
            margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: _Avatar(title: title),
          title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(
            r.lastMessage ?? 'No messages yet',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ChatScreen(roomId: r.roomId)),
            );
          },
            ),
          ),
        );
          },
        );
      },
        ),
      )),
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

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.forum_outlined, size: 72, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 12),
            const Text('No conversations yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(
              'Start a new chat by scanning or sharing a QR code.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Theme.of(context).textTheme.bodySmall?.color),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () async {
                await Navigator.pushNamed(context, '/new_chat');
                if (!mounted) return;
                _resyncAndLoad();
              },
              icon: const Icon(Icons.qr_code),
              label: const Text('New chat'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String title;
  const _Avatar({required this.title});

  @override
  Widget build(BuildContext context) {
  final t = title.trim();
  final char = t.isNotEmpty ? t.substring(0, 1).toUpperCase() : '?';
    return CircleAvatar(
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
      child: Text(char),
    );
  }
}

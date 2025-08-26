import 'package:flutter/material.dart';
import '../models/chat_room.dart';
import '../services/chat_service.dart';
import 'chat_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  List<ChatRoom> _rooms = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _load();
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
              onRefresh: _load,
              child: ListView.builder(
                itemCount: _rooms.length,
                itemBuilder: (context, index) {
                  final r = _rooms[index];
                  return ListTile(
                    title: Text(r.roomId),
                    subtitle: Text(r.lastMessage ?? 'No messages yet'),
                    leading: const CircleAvatar(child: Icon(Icons.forum)),
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(roomId: r.roomId)));
                    },
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.pushNamed(context, '/new_chat');
          if (!mounted) return;
          _load();
        },
        child: const Icon(Icons.add),
        tooltip: 'Start New Chat',
      ),
    );
  }
}

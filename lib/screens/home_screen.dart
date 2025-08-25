import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

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
      body: ListView(
        children: const [
          // Placeholder for chat list
          ListTile(
            leading: CircleAvatar(child: Icon(Icons.person)),
            title: Text('User 1'),
            subtitle: Text('Last message preview...'),
          ),
          ListTile(
            leading: CircleAvatar(child: Icon(Icons.person)),
            title: Text('User 2'),
            subtitle: Text('Last message preview...'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/new_chat');
        },
        child: const Icon(Icons.add),
        tooltip: 'Start New Chat',
      ),
    );
  }
}

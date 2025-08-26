import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:uuid/uuid.dart';
import 'package:sqflite/sqflite.dart';

import '../models/chat_message.dart';
import '../models/chat_room.dart';
import 'firebase_service.dart';
import 'local_db_service.dart';

class ChatService {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  final _firebase = FirebaseService();
  final _uuid = const Uuid();

  // Create or join a room and store locally for home listing
  Future<void> createOrJoinRoom({
    required String roomId,
    required String userId,
    required String username,
  }) async {
    // Remote: register as participant
    await _firebase.createOrJoinChatRoom(roomId, userId, {
      'username': username,
    });

    // Local: upsert chat_rooms
    final db = await LocalDbService().database;
    await db.insert(
      'chat_rooms',
      ChatRoom(roomId: roomId).toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> sendMessage({
    required String roomId,
    required String userId,
    required String content,
  }) async {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final messageId = _uuid.v4();
    final msg = ChatMessage(
      messageId: messageId,
      roomId: roomId,
      senderId: userId,
      content: content,
      timestamp: ts,
    );

    // Write to remote first; in a more robust setup you'd do local-first w/ outbox
    await _firebase.sendMessage(roomId, {
      'message_id': messageId,
      'sender_id': userId,
      'content': content,
      'timestamp': ts,
    });

    // Upsert local message and update chat room
    final db = await LocalDbService().database;
    await db.insert('messages', msg.toMap(), conflictAlgorithm: ConflictAlgorithm.ignore);
    await db.insert(
      'chat_rooms',
      ChatRoom(roomId: roomId, lastMessage: content, lastUpdated: ts).toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Stream messages by listening to Firebase and mirroring into SQLite;
  // return a local stream from polling SQLite for simplicity (no advanced change listeners in sqflite).
  Stream<List<ChatMessage>> messageStream(String roomId) {
    // Start Firebase listener that mirrors to local DB
    _firebase.messageStream(roomId).listen((DatabaseEvent event) async {
      final data = event.snapshot.value;
      if (data is Map) {
        final messages = data.values.whereType<Map>();
        final db = await LocalDbService().database;
        final batch = db.batch();
        for (final m in messages) {
          final map = Map<String, dynamic>.from(m);
          final msg = ChatMessage(
            messageId: (map['message_id'] ?? _uuid.v4()).toString(),
            roomId: roomId,
            senderId: map['sender_id']?.toString() ?? '',
            content: map['content']?.toString() ?? '',
            timestamp: int.tryParse(map['timestamp'].toString()) ?? 0,
          );
          batch.insert('messages', msg.toMap(), conflictAlgorithm: ConflictAlgorithm.ignore);
        }
        await batch.commit(noResult: true);
      }
    });

    // Poll local DB every 500ms for simplicity
    final dbFuture = LocalDbService().database;
    return Stream.periodic(const Duration(milliseconds: 500)).asyncMap((_) async {
      final db = await dbFuture;
      final rows = await db.query(
        'messages',
        where: 'room_id = ?',
        whereArgs: [roomId],
        orderBy: 'timestamp ASC',
      );
      return rows.map((e) => ChatMessage.fromMap(e)).toList();
    });
  }

  Future<List<ChatRoom>> recentRooms() async {
    final db = await LocalDbService().database;
  final rows = await db.query('chat_rooms', orderBy: 'COALESCE(last_updated, 0) DESC');
    return rows.map((e) => ChatRoom.fromMap(e)).toList();
  }
}

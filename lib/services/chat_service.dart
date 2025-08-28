import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:uuid/uuid.dart';
import 'package:sqflite/sqflite.dart';

import '../models/chat_message.dart';
import '../models/chat_room.dart';
import '../models/contact.dart';
import 'firebase_service.dart';
import 'local_db_service.dart';

class ChatService {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  final _firebase = FirebaseService();
  final _uuid = const Uuid();

  String pairKeyFor(String a, String b) {
    final list = [a, b]..sort();
    return '${list[0]}:${list[1]}';
  }

  Future<void> createOrJoinRoom({
    required String roomId,
    required String userId,
    required String username,
  }) async {
    await _firebase.createOrJoinChatRoom(roomId, userId, {
      'username': username,
    });

    final db = await LocalDbService().database;
    await db.insert(
      'chat_rooms',
      ChatRoom(roomId: roomId).toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }


  Future<String> createOrGetRoomByUserId({
    required String myUserId,
    required String myUsername,
    required String otherUserId,
    required String otherUsername,
  }) async {
    final pairKey = pairKeyFor(myUserId, otherUserId);
    final roomId = await _firebase.createOrGetRoomByPairKey(pairKey, {
      'username': myUsername,
      'active': true,
    });
    await _firebase.setParticipant(roomId, myUserId, {
      'username': myUsername,
      'active': true,
    });
    await _firebase.setParticipant(roomId, otherUserId, {
      'username': otherUsername,
      'active': true,
    });

    final db = await LocalDbService().database;
    await db.insert('contacts', Contact(contactId: otherUserId, username: otherUsername).toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
    await db.insert('chat_rooms', ChatRoom(roomId: roomId, contactId: otherUserId).toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
    return roomId;
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

    await _firebase.sendMessage(roomId, {
      'message_id': messageId,
      'sender_id': userId,
      'content': content,
      'timestamp': ts,
    });

    final db = await LocalDbService().database;
    await db.insert('messages', msg.toMap(), conflictAlgorithm: ConflictAlgorithm.ignore);
    await db.insert(
      'chat_rooms',
      ChatRoom(roomId: roomId, lastMessage: content, lastUpdated: ts).toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Stream<List<ChatMessage>> messageStream(String roomId) {
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

  Future<Contact?> getContact(String contactId) async {
    final db = await LocalDbService().database;
    final rows = await db.query('contacts', where: 'contact_id = ?', whereArgs: [contactId], limit: 1);
    if (rows.isEmpty) return null;
    return Contact.fromMap(rows.first);
  }

  Future<void> upsertContact(Contact contact) async {
    final db = await LocalDbService().database;
    await db.insert('contacts', contact.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> leaveRoom(String roomId, String myUserId) async {
    try {
      await _firebase.leaveRoom(roomId, myUserId);
    } catch (_) {}
  }

  Future<void> deleteRoomLocal(String roomId) async {
    final db = await LocalDbService().database;
    final batch = db.batch();
    batch.delete('messages', where: 'room_id = ?', whereArgs: [roomId]);
    batch.delete('chat_rooms', where: 'room_id = ?', whereArgs: [roomId]);
    await batch.commit(noResult: true);
  }

  Future<void> resyncForUser(String userId, {int pullLastNMessages = 30}) async {
    final roomsMap = await _firebase.getUserRooms(userId);
    if (roomsMap.isEmpty) return;

    final db = await LocalDbService().database;
    final batch = db.batch();

    for (final entry in roomsMap.entries) {
      final roomId = entry.key;
      final meta = (entry.value is Map) ? Map<String, dynamic>.from(entry.value) : <String, dynamic>{};
      final status = meta['status']?.toString() ?? 'active';
      final leftAt = int.tryParse(meta['leftAt']?.toString() ?? '');
      final roomSnap = await _firebase.getChatRoom(roomId);
      if (!roomSnap.exists) continue;
  final data = roomSnap.value;
  if (data is! Map) continue;
  final map = Map<String, dynamic>.from(data);
      final participants = (map['participants'] is Map) ? Map<String, dynamic>.from(map['participants']) : <String, dynamic>{};
      final lastMessage = map['last_message']?.toString();
      final lastUpdated = int.tryParse(map['last_updated']?.toString() ?? '');

      if (status == 'inactive' && leftAt != null && lastUpdated != null && lastUpdated <= leftAt) {
        continue;
      }

      String? otherUserId;
      String? otherUsername;
      participants.forEach((pid, pval) {
        if (pid != userId && otherUserId == null) {
          otherUserId = pid;
          if (pval is Map) {
            otherUsername = (pval['username'] ?? '').toString();
          }
        }
      });

      if (otherUserId != null) {
        batch.insert(
          'contacts',
          Contact(contactId: otherUserId!, username: otherUsername ?? otherUserId!).toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      batch.insert(
        'chat_rooms',
        ChatRoom(
          roomId: roomId,
          contactId: otherUserId,
          lastMessage: lastMessage,
          lastUpdated: lastUpdated,
        ).toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      if (pullLastNMessages > 0) {
        try {
          final msgsSnap = await _firebase.getRecentMessages(roomId, limit: pullLastNMessages);
          final val = msgsSnap.value;
          if (val is Map) {
            final msgs = val.values.whereType<Map>();
            for (final m in msgs) {
              final map = Map<String, dynamic>.from(m);
              final msg = ChatMessage(
                messageId: (map['message_id'] ?? _uuid.v4()).toString(),
                roomId: roomId,
                senderId: map['sender_id']?.toString() ?? '',
                content: map['content']?.toString() ?? '',
                timestamp: int.tryParse(map['timestamp']?.toString() ?? '') ?? 0,
              );
              batch.insert('messages', msg.toMap(), conflictAlgorithm: ConflictAlgorithm.ignore);
            }
          }
        } catch (_) {
          // Implement error catching
        }
      }


      try {
        await _firebase.clearHasNew(userId, roomId);
      } catch (_) {
        // Implement error catching...
      }
    }

    await batch.commit(noResult: true);
  }

  Stream<DatabaseEvent> userRoomsStream(String userId) => _firebase.userRoomsStream(userId);
}

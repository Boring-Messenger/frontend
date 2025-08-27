import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';

class FirebaseService {
  static const String _dbUrl =
    'https://prjkt-boring-default-rtdb.asia-southeast1.firebasedatabase.app';

  FirebaseDatabase get _database =>
    FirebaseDatabase.instanceFor(app: Firebase.app(), databaseURL: _dbUrl);

  DatabaseReference get _db => _database.ref();

  // Create or update a user profile
  Future<void> setUserProfile(String userId, Map<String, dynamic> profile) async {
    // Use update so we don't wipe out the per-user rooms index
    await _db.child('users/$userId').update(profile);
  }

  // Get a user profile
  Future<DataSnapshot> getUserProfile(String userId) async {
    return await _db.child('users/$userId').get();
  }

  // Create or join a chat room
  Future<void> createOrJoinChatRoom(String roomId, String userId, Map<String, dynamic> profile) async {
  await _db.child('chat_rooms/$roomId/participants/$userId').set(profile);
  await _db.child('users/$userId/rooms/$roomId').set(true);
  }

  // Transactionally create or get a room for a pair key; returns the roomId
  Future<String> createOrGetRoomByPairKey(String pairKey, Map<String, dynamic> myProfile) async {
    final pairRef = _db.child('pair_index/$pairKey');
    String? roomId;
    await pairRef.runTransaction((current) {
      if (current is String && current.isNotEmpty) {
        roomId = current;
        return Transaction.success(current);
      }
      // create a new deterministic roomId from pairKey
      final id = pairKey.replaceAll(':', '_');
      roomId = id;
      return Transaction.success(id);
    });
    final id = roomId!;
    // Ensure room exists and participant registered
    await _db.child('chat_rooms/$id').update({
      'last_updated': ServerValue.timestamp,
    });
    // Caller must then set participants
    return id;
  }

  Future<void> setParticipant(String roomId, String userId, Map<String, dynamic> profile) async {
    await _db.child('chat_rooms/$roomId/participants/$userId').update(profile);
    // Maintain per-user room index for quick discovery with metadata
    await _db.child('users/$userId/rooms/$roomId').update({
      'status': (profile['active'] == false) ? 'inactive' : 'active',
    });
  }

  Future<void> leaveRoom(String roomId, String userId) async {
    await _db.child('chat_rooms/$roomId/participants/$userId').update({
      'active': false,
      'leftAt': ServerValue.timestamp,
    });
    // Keep per-user room index with inactive status to enable auto-rediscovery
    await _db.child('users/$userId/rooms/$roomId').update({
      'status': 'inactive',
      'leftAt': ServerValue.timestamp,
    });
  }

  Future<void> deleteRoom(String roomId) async {
    await _db.child('chat_rooms/$roomId').remove();
  }

  // Send a message to a chat room
  Future<void> sendMessage(String roomId, Map<String, dynamic> message) async {
    await _db.child('chat_rooms/$roomId/messages').push().set(message);
    await _db.child('chat_rooms/$roomId').update({
      'last_message': message['content'],
      'last_updated': message['timestamp'],
    });
    // Update per-user room indexes so receivers can auto-rediscover
    try {
      final participantsSnap = await _db.child('chat_rooms/$roomId/participants').get();
      if (participantsSnap.exists && participantsSnap.value is Map) {
        final participants = Map<String, dynamic>.from(participantsSnap.value as Map);
        final ts = message['timestamp'];
        final senderId = message['sender_id']?.toString();
        for (final entry in participants.entries) {
          final uid = entry.key;
          await _db.child('users/$uid/rooms/$roomId').update({
            'last_updated': ts,
            if (senderId != null) 'last_sender': senderId,
            if (senderId != null && uid != senderId) 'has_new': true,
          });
        }
      }
    } catch (_) {}
  }

  // Listen for messages in a chat room
  Stream<DatabaseEvent> messageStream(String roomId) {
    return _db.child('chat_rooms/$roomId/messages').orderByChild('timestamp').onValue;
  }

  // Get chat room info
  Future<DataSnapshot> getChatRoom(String roomId) async {
    return await _db.child('chat_rooms/$roomId').get();
  }

  // List room ids for a user from the per-user index
  Future<List<String>> getUserRoomIds(String userId) async {
    final snap = await _db.child('users/$userId/rooms').get();
    if (!snap.exists) return const [];
    final val = snap.value;
    if (val is Map) {
      return val.keys.map((e) => e.toString()).toList();
    }
    return const [];
  }

  // Get the full per-user rooms map (roomId -> metadata)
  Future<Map<String, dynamic>> getUserRooms(String userId) async {
    final snap = await _db.child('users/$userId/rooms').get();
    if (!snap.exists || snap.value is! Map) return <String, dynamic>{};
    return Map<String, dynamic>.from(snap.value as Map);
  }

  // Fetch recent N messages for a room
  Future<DataSnapshot> getRecentMessages(String roomId, {int limit = 50}) async {
    return await _db
        .child('chat_rooms/$roomId/messages')
        .orderByChild('timestamp')
        .limitToLast(limit)
        .get();
  }

  // Stream that emits whenever the per-user rooms index changes
  Stream<DatabaseEvent> userRoomsStream(String userId) {
    return _db.child('users/$userId/rooms').onValue;
  }

  Future<void> clearHasNew(String userId, String roomId) async {
    await _db.child('users/$userId/rooms/$roomId/has_new').remove();
  }
}

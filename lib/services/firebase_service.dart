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
    await _db.child('users/$userId').set(profile);
  }

  // Get a user profile
  Future<DataSnapshot> getUserProfile(String userId) async {
    return await _db.child('users/$userId').get();
  }

  // Create or join a chat room
  Future<void> createOrJoinChatRoom(String roomId, String userId, Map<String, dynamic> profile) async {
    await _db.child('chat_rooms/$roomId/participants/$userId').set(profile);
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
  }

  Future<void> leaveRoom(String roomId, String userId) async {
    await _db.child('chat_rooms/$roomId/participants/$userId').update({
      'active': false,
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
  }

  // Listen for messages in a chat room
  Stream<DatabaseEvent> messageStream(String roomId) {
    return _db.child('chat_rooms/$roomId/messages').orderByChild('timestamp').onValue;
  }

  // Get chat room info
  Future<DataSnapshot> getChatRoom(String roomId) async {
    return await _db.child('chat_rooms/$roomId').get();
  }
}

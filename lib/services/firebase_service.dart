import 'package:firebase_database/firebase_database.dart';

class FirebaseService {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  // Create or update a user profile
  Future<void> setUserProfile(String userId, Map<String, dynamic> profile) async {
    await _db.child('users/$userId').set(profile);
  }

  // Get a user profile
  Future<DataSnapshot> getUserProfile(String userId) async {
    return await _db.child('users/$userId').get();
  }

  // Create or join a chat room
  Future<void> createOrJoinChatRoom(String roomId, Map<String, dynamic> userProfile) async {
    await _db.child('chat_rooms/$roomId/participants').update(userProfile);
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

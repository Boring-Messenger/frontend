class ChatRoom {
  final String roomId;
  final String? contactId; // optional for future
  final String? lastMessage;
  final int? lastUpdated;

  ChatRoom({
    required this.roomId,
    this.contactId,
    this.lastMessage,
    this.lastUpdated,
  });

  Map<String, dynamic> toMap() => {
        'room_id': roomId,
        'contact_id': contactId,
        'last_message': lastMessage,
        'last_updated': lastUpdated,
      };

  factory ChatRoom.fromMap(Map<String, dynamic> map) => ChatRoom(
        roomId: map['room_id'] as String,
        contactId: map['contact_id'] as String?,
        lastMessage: map['last_message'] as String?,
        lastUpdated: map['last_updated'] as int?,
      );
}

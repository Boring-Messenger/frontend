class ChatMessage {
  final String messageId; // client-generated UUID
  final String roomId;
  final String senderId;
  final String content;
  final int timestamp; // ms since epoch

  ChatMessage({
    required this.messageId,
    required this.roomId,
    required this.senderId,
    required this.content,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() => {
        'message_id': messageId,
        'room_id': roomId,
        'sender_id': senderId,
        'content': content,
        'timestamp': timestamp,
      };

  factory ChatMessage.fromMap(Map<String, dynamic> map) => ChatMessage(
        messageId: map['message_id'] as String,
        roomId: map['room_id'] as String,
        senderId: map['sender_id'] as String,
        content: map['content'] as String,
        timestamp: map['timestamp'] as int,
      );
}

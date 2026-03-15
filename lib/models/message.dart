// models/message.dart
class Message {
  final String id;
  final String conversationId;
  final String senderId;
  final String content;
  final String status;
  final DateTime createdAt;
  final bool seen;

  Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    required this.status,
    required this.createdAt,
    required this.seen,
  });

  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      id: map['id'].toString(),
      conversationId: map['conversation_id'],
      senderId: map['sender_id'],
      content: map['content'],
      status: map['status'] ?? 'sent',
      createdAt: DateTime.parse(map['created_at']),
      seen: map['seen'] ?? false,
    );
  }
}

class Conversation {
  final String id;
  final String title;

  Conversation({required this.id, required this.title});

  factory Conversation.fromMap(Map<String, dynamic> map) {
    return Conversation(id: map['id'], title: map['title'] ?? 'Chat');
  }
}
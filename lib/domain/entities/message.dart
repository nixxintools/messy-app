/// Honest delivery states — the UI never claims more than it can prove.
enum MessageStatus { draft, queued, sentToMesh, delivered, failed }

enum MessageDirection { outgoing, incoming }

class Message {
  const Message({
    required this.messageId, // UUIDv7 — time-sortable, dedupe key
    required this.chatId,
    required this.direction,
    required this.body,
    required this.sentAt,
    required this.status,
    this.mediaId,
    this.receivedAt,
    this.expiresAt, // disappearing messages / public-room 24 h expiry
  });

  final String messageId;
  final String chatId;
  final MessageDirection direction;
  final String body;
  final DateTime sentAt;
  final MessageStatus status;
  final String? mediaId;
  final DateTime? receivedAt;
  final DateTime? expiresAt;
}

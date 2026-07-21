/// Protocol constants — see docs/ARCHITECTURE.md §4 (wire format).
abstract final class Protocol {
  static const int version = 0x01;

  // Frame types
  static const int frameHello = 0x01;
  static const int frameEnvelope = 0x02;
  static const int frameAck = 0x03;
  static const int frameSummary = 0x04;
  static const int frameWant = 0x05;
  static const int frameChunkReq = 0x06;
  static const int frameContactReq = 0x07;
  static const int frameContactAccept = 0x08;

  // Payload types (inside envelope)
  static const int payloadText = 0x01;
  static const int payloadMediaManifest = 0x02;
  static const int payloadMediaChunk = 0x03;
  static const int payloadDeliveryReceipt = 0x04;
  static const int payloadPublicText = 0x05;
  static const int payloadGroupText = 0x06;
  static const int payloadGroupInvite = 0x07; // sent 1:1, carries group key

  // Routing
  static const int ttlDirect = 8; // 1:1 messages
  static const int ttlPublic = 5; // public-room broadcasts
  static const int chunkSize = 32 * 1024; // media chunk plaintext bytes
  static const int relayBudgetBytes = 256 * 1024 * 1024;
  static const Duration relayRetention = Duration(hours: 72);
  static const Duration publicRetention = Duration(hours: 24);
  static const Duration seenRetention = Duration(days: 7);
  static const int relayedMediaCapBytes = 25 * 1024 * 1024;

  /// Recipient key of all zeros = public-room broadcast envelope.
  static const int recipientKeyLength = 32;

  static const String hkdfSalt = 'messy-v1';
  static const String publicRoomInfo = 'messy-public-room';
}

class AppConstants {
  // Message types
  static const String messageTypeText = 'text';
  static const String messageTypeImage = 'image';
  static const String messageTypeFile = 'file';
  static const String messageTypeAudio = 'audio';
  static const String messageTypeVideo = 'video';
  static const String messageTypeRecall = 'recall';

  // Message status
  static const String messageStatusSending = 'sending';
  static const String messageStatusSent = 'sent';
  static const String messageStatusDelivered = 'delivered';
  static const String messageStatusRead = 'read';
  static const String messageStatusFailed = 'failed';

  // Call types
  static const String callTypeAudio = 'audio';
  static const String callTypeVideo = 'video';

  // Call status
  static const String callStatusRinging = 'ringing';
  static const String callStatusAccepted = 'accepted';
  static const String callStatusRejected = 'rejected';
  static const String callStatusEnded = 'ended';
  static const String callStatusMissed = 'missed';

  // WebSocket events
  static const String wsEventMessage = 'message';
  static const String wsEventTyping = 'typing';
  static const String wsEventOnline = 'online';
  static const String wsEventOffline = 'offline';
  static const String wsEventCall = 'call';
  static const String wsEventCallOffer = 'offer';
  static const String wsEventCallAnswer = 'answer';
  static const String wsEventCallIce = 'ice';
  static const String wsEventCallEnd = 'end';

  // Friend request status
  static const String friendStatusPending = 'pending';
  static const String friendStatusAccepted = 'accepted';
  static const String friendStatusRejected = 'rejected';

  // Chat types
  static const String chatTypePrivate = 'private';
  static const String chatTypeGroup = 'group';

  // Pagination
  static const int maxMessagePageSize = 50;
  static const int maxFriendPageSize = 30;
  static const int maxGroupPageSize = 20;

  // File limits
  static const int maxImageSize = 10 * 1024 * 1024; // 10MB
  static const int maxFileSize = 100 * 1024 * 1024; // 100MB
}

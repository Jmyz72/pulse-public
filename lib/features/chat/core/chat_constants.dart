class ChatConstants {
  ChatConstants._();

  static const int messagePaginationLimit = 30;
  static const int batchDeleteLimit = 500;
  static const int presenceWhereInLimit = 30;
  static const int typingTimeoutSeconds = 10;
  static const int streamReconnectMaxAttempts = 5;
  static const Duration streamReconnectBaseDelay = Duration(seconds: 2);
}

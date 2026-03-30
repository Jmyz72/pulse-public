/// API Keys Configuration
class ApiKeys {
  /// Public repository placeholder. Real key removed.
  static const String geminiApiKey = 'REMOVED_FOR_PUBLIC_REPO';

  /// Public repository placeholder. Real key removed.
  static const String googleMapsApiKey = 'REMOVED_FOR_PUBLIC_REPO';

  static bool get isGeminiConfigured =>
      geminiApiKey.isNotEmpty && geminiApiKey != 'REMOVED_FOR_PUBLIC_REPO';
}

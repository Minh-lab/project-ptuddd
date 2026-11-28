import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Client settings supplied by Flutter's `--dart-define-from-file`.
class SharedClientConfig {
  const SharedClientConfig();

  String get supabaseUrl => const String.fromEnvironment('TEAM_SUPABASE_URL');
  String get supabasePublishableKey =>
      const String.fromEnvironment('TEAM_SUPABASE_PUBLISHABLE_KEY');
  String get aiEndpoint => const String.fromEnvironment('TEAM_AI_ENDPOINT');

  FirebaseOptions? firebaseOptionsFor(TargetPlatform platform) {
    if (kIsWeb) return null;
    const projectId = String.fromEnvironment('TEAM_FIREBASE_PROJECT_ID');
    const senderId = String.fromEnvironment(
      'TEAM_FIREBASE_MESSAGING_SENDER_ID',
    );
    final (apiKey, appId) = switch (platform) {
      TargetPlatform.android => (
        const String.fromEnvironment('TEAM_FIREBASE_ANDROID_API_KEY'),
        const String.fromEnvironment('TEAM_FIREBASE_ANDROID_APP_ID'),
      ),
      TargetPlatform.iOS => (
        const String.fromEnvironment('TEAM_FIREBASE_IOS_API_KEY'),
        const String.fromEnvironment('TEAM_FIREBASE_IOS_APP_ID'),
      ),
      _ => ('', ''),
    };
    if (projectId.isEmpty ||
        senderId.isEmpty ||
        apiKey.isEmpty ||
        appId.isEmpty) {
      return null;
    }
    return FirebaseOptions(
      apiKey: apiKey,
      appId: appId,
      messagingSenderId: senderId,
      projectId: projectId,
      iosBundleId: platform == TargetPlatform.iOS
          ? const String.fromEnvironment('TEAM_FIREBASE_IOS_BUNDLE_ID')
          : null,
    );
  }
}

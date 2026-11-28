import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_note/core/services/shared_client_config.dart';

void main() {
  test('đọc cấu hình client theo nền tảng khi có file riêng', () {
    const config = SharedClientConfig();
    final android = config.firebaseOptionsFor(
      TargetPlatform.android,
      web: false,
    );
    final ios = config.firebaseOptionsFor(TargetPlatform.iOS, web: false);
    final web = config.firebaseOptionsFor(TargetPlatform.iOS, web: true);

    if (const String.fromEnvironment('TEAM_FIREBASE_ANDROID_API_KEY').isEmpty) {
      expect(android, isNull);
    } else {
      expect(android?.appId, contains(':android:'));
      expect(android?.projectId, 'smartnote-nhom03-65ktpm');
    }
    if (const String.fromEnvironment('TEAM_FIREBASE_IOS_API_KEY').isEmpty) {
      expect(ios, isNull);
    } else {
      expect(ios?.appId, contains(':ios:'));
      expect(ios?.iosBundleId, 'com.smartnote.smartNote');
    }
    if (config.supabaseUrl.isNotEmpty) {
      expect(config.supabasePublishableKey, startsWith('sb_publishable_'));
      expect(
        Uri.parse(config.aiEndpoint).origin,
        Uri.parse(config.supabaseUrl).origin,
      );
    }
    if (const String.fromEnvironment('TEAM_FIREBASE_WEB_API_KEY').isEmpty) {
      expect(web, isNull);
    } else {
      expect(web?.appId, contains(':web:'));
      expect(web?.projectId, 'smartnote-nhom03-65ktpm');
      expect(web?.authDomain, 'smartnote-nhom03-65ktpm.firebaseapp.com');
      expect(web?.iosBundleId, isNull);
    }
  });
}

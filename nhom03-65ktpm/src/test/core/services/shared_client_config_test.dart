import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_note/core/services/shared_client_config.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'cấu hình Android, iOS và Supabase được đóng gói cùng ứng dụng',
    () async {
      final config = await SharedClientConfig.load();
      final android = config.firebaseOptionsFor(TargetPlatform.android)!;
      final ios = config.firebaseOptionsFor(TargetPlatform.iOS)!;

      expect(android.projectId, 'smartnote-nhom03-65ktpm');
      expect(ios.projectId, android.projectId);
      expect(android.appId, contains(':android:'));
      expect(ios.appId, contains(':ios:'));
      expect(ios.iosBundleId, 'com.smartnote.smartNote');
      expect(config.supabasePublishableKey, startsWith('sb_publishable_'));

      final supabase = Uri.parse(config.supabaseUrl);
      final ai = Uri.parse(config.aiEndpoint);
      expect(supabase.scheme, 'https');
      expect(ai.origin, supabase.origin);
      expect(ai.path, '/functions/v1/summarize-note');
    },
  );
}

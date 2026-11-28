import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/di/app_dependencies.dart';
import 'core/services/firebase_bootstrap.dart';
import 'core/services/shared_client_config.dart';
import 'core/services/supabase_bootstrap.dart';
import 'features/auth/presentation/pages/firebase_config_error_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final SharedClientConfig shared;

  try {
    shared = await SharedClientConfig.load();
    await FirebaseBootstrap.initialize(
      sharedOptions: shared.firebaseOptionsFor(defaultTargetPlatform),
    );
  } on FirebaseException catch (error) {
    runApp(FirebaseConfigErrorPage(detail: 'Mã lỗi: ${error.code}'));
    return;
  } catch (error) {
    runApp(FirebaseConfigErrorPage(detail: '$error'));
    return;
  }

  // Supabase là kho dữ liệu dùng chung (#21). Không cấu hình thì trả `null` và
  // app chạy ở chế độ chỉ lưu trên máy.
  final SupabaseClient? supabase = await SupabaseBootstrap.initialize(
    accessToken: _firebaseIdToken,
    sharedUrl: shared.supabaseUrl,
    sharedPublishableKey: shared.supabasePublishableKey,
  );
  final dependencies = AppDependencies.create(
    supabaseClient: supabase,
    defaultAiEndpoint: shared.aiEndpoint,
  );
  runApp(SmartNoteApp(dependencies: dependencies));
}

/// Supabase dùng JWT của Firebase (Third-party auth → Firebase), nên mỗi lần
/// Supabase cần token (REST, Realtime, refresh) ta trả ID token hiện tại.
Future<String?> _firebaseIdToken() async {
  final user = FirebaseAuth.instance.currentUser;
  return user?.getIdToken();
}

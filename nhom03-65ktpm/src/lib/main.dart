import 'package:app_links/app_links.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'core/di/app_dependencies.dart';
import 'core/services/firebase_bootstrap.dart';
import 'core/services/supabase_bootstrap.dart';
import 'features/auth/presentation/pages/firebase_config_error_page.dart';
import 'features/notes/data/repositories/supabase_note_share_repository.dart';
import 'features/notes/data/repositories/unavailable_note_share_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env', isOptional: true);
  final appLinks = AppLinks();
  final initialLink = await appLinks.getInitialLink();

  try {
    await FirebaseBootstrap.initialize();
  } on FirebaseException catch (error) {
    runApp(FirebaseConfigErrorPage(detail: 'Mã lỗi: ${error.code}'));
    return;
  } catch (error) {
    runApp(FirebaseConfigErrorPage(detail: '$error'));
    return;
  }
  final user = FirebaseAuth.instance.currentUser;

if (user != null) {
  final tokenResult = await user.getIdTokenResult(true);

  debugPrint('Firebase UID: ${user.uid}');
  debugPrint('Firebase claims: ${tokenResult.claims}');
  debugPrint('Role: ${tokenResult.claims?['role']}');
}

  SupabaseClient? supabaseClient;
  String? supabaseError;
  try {
    supabaseClient = await SupabaseBootstrap.initialize();
  } on FormatException catch (error) {
    supabaseError = 'Cấu hình Supabase không hợp lệ: ${error.message}';
  }
  final noteShareRepository = supabaseClient != null
      ? SupabaseNoteShareRepository(supabaseClient)
      : supabaseError == null
      ? UnavailableNoteShareRepository()
      : UnavailableNoteShareRepository(supabaseError);
  final dependencies = AppDependencies.create(
    noteShareRepository: noteShareRepository,
    supabaseClient: supabaseClient,
  );
  runApp(
    SmartNoteApp(
      dependencies: dependencies,
      initialLink: initialLink,
      linkStream: appLinks.uriLinkStream,
    ),
  );
}

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'core/di/app_dependencies.dart';
import 'core/services/firebase_bootstrap.dart';
import 'features/auth/presentation/pages/firebase_config_error_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    final firebaseInitialized = await FirebaseBootstrap.initialize();
    final dependencies = AppDependencies.create(
      developmentMode: !firebaseInitialized,
    );
    runApp(SmartNoteApp(dependencies: dependencies));
  } on FirebaseException catch (error) {
    runApp(FirebaseConfigErrorPage(detail: 'Mã lỗi: ${error.code}'));
  } catch (error) {
    runApp(FirebaseConfigErrorPage(detail: '$error'));
  }
}

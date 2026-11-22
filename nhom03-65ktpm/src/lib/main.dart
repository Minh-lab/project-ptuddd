import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'core/di/app_dependencies.dart';
import 'core/services/firebase_bootstrap.dart';
import 'features/auth/presentation/pages/firebase_config_error_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await FirebaseBootstrap.initialize();
  } on FirebaseException catch (error) {
    runApp(FirebaseConfigErrorPage(detail: 'Mã lỗi: ${error.code}'));
    return;
  } catch (error) {
    runApp(FirebaseConfigErrorPage(detail: '$error'));
    return;
  }

  final dependencies = AppDependencies.create();
  runApp(SmartNoteApp(dependencies: dependencies));
}

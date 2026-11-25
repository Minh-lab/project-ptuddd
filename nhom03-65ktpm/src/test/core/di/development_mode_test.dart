import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_note/app.dart';
import 'package:smart_note/core/di/app_dependencies.dart';
import 'package:smart_note/features/auth/data/repositories/development_auth_repository.dart';
import 'package:smart_note/features/notes/data/repositories/development_note_repository.dart';

void main() {
  test(
    'Development Mode uses mock auth and memory-only sample notes',
    () async {
      final dependencies = AppDependencies.create(developmentMode: true);
      final authRepository =
          dependencies.authRepository as DevelopmentAuthRepository;
      final noteRepository =
          dependencies.noteRepository as DevelopmentNoteRepository;
      addTearDown(() async {
        await dependencies.dispose();
        await authRepository.dispose();
        await noteRepository.dispose();
      });

      expect(dependencies.isDevelopmentMode, isTrue);
      expect(
        dependencies.authRepository.currentUser?.id,
        'smartnote-development-user',
      );
      expect((await noteRepository.getNotes()), isNotEmpty);
      expect(await dependencies.notesDao.getAll(), isEmpty);
    },
  );

  testWidgets('Development Mode opens the app with labeled mock data', (
    WidgetTester tester,
  ) async {
    final dependencies = AppDependencies.create(developmentMode: true);
    final authRepository =
        dependencies.authRepository as DevelopmentAuthRepository;
    final noteRepository =
        dependencies.noteRepository as DevelopmentNoteRepository;

    await tester.pumpWidget(SmartNoteApp(dependencies: dependencies));
    await tester.pumpAndSettle();

    expect(find.text('DEV · MOCK'), findsOneWidget);
    expect(find.text('Ghi chú phát triển'), findsOneWidget);
    expect(find.text('Đăng nhập để đồng bộ ghi chú của bạn'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await dependencies.dispose();
    await authRepository.dispose();
    await noteRepository.dispose();
  });
}

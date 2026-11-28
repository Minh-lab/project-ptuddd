import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_note/core/di/app_dependencies.dart';
import 'package:smart_note/core/theme/app_theme.dart';
import 'package:smart_note/features/notes/domain/entities/note.dart';
import 'package:smart_note/features/notes/presentation/bloc/notes_cubit.dart';
import 'package:smart_note/features/notes/presentation/pages/note_editor_page.dart';
import 'package:smart_note/features/notes/presentation/pages/notes_page.dart';

import '../../../support/fake_auth_repository.dart';
import '../../../support/fake_reminders.dart';

/// Bấm vào thông báo nhắc nhở (#10) thì mở đúng ghi chú.
void main() {
  late FakeAuthRepository authRepository;
  late FakeReminderNotifications notifications;
  late AppDependencies dependencies;

  setUp(() async {
    authRepository = FakeAuthRepository();
    notifications = FakeReminderNotifications(isSupported: false);
    dependencies = AppDependencies.create(
      executor: NativeDatabase.memory(),
      authRepository: authRepository,
      reminderNotifications: notifications,
    );
    final now = DateTime(2026, 11, 28, 9);
    await dependencies.noteRepository.createNote(
      Note(
        id: 'note-1',
        title: 'Giải tích – Chương 3',
        content: 'Đạo hàm và tích phân.',
        kind: NoteKind.note,
        createdAt: now,
        updatedAt: now,
      ),
    );
  });

  tearDown(() async {
    await authRepository.dispose();
  });

  Future<void> pumpPage(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: BlocProvider<NotesCubit>(
          create: (_) => NotesCubit(dependencies.noteRepository)..load(),
          child: NotesPage(dependencies: dependencies),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> disposePage(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await tester.runAsync(dependencies.dispose);
  }

  testWidgets('bấm thông báo thì mở trình soạn của ghi chú đó', (
    WidgetTester tester,
  ) async {
    await pumpPage(tester);

    notifications.taps.add('note-1');
    await tester.pumpAndSettle();

    final editor = tester.widget<NoteEditorPage>(find.byType(NoteEditorPage));
    expect(editor.note?.id, 'note-1');
    expect(find.text('Giải tích – Chương 3'), findsWidgets);

    await disposePage(tester);
  });

  testWidgets('ghi chú đã bị xoá thì báo cho người dùng biết', (
    WidgetTester tester,
  ) async {
    await pumpPage(tester);

    notifications.taps.add('da-xoa');
    await tester.pumpAndSettle();

    expect(find.byType(NoteEditorPage), findsNothing);
    expect(
      find.text('Ghi chú của nhắc nhở này không còn nữa.'),
      findsOneWidget,
    );

    await disposePage(tester);
  });
}

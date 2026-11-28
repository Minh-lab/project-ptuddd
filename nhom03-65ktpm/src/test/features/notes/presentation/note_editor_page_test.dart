import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_note/core/di/app_dependencies.dart';
import 'package:smart_note/core/services/ai_client.dart';
import 'package:smart_note/features/notes/presentation/bloc/notes_cubit.dart';
import 'package:smart_note/features/notes/presentation/pages/note_editor_page.dart';

import '../../../support/fake_auth_repository.dart';

void main() {
  testWidgets('lưu bản nháp trước khi rời màn hình soạn', (
    WidgetTester tester,
  ) async {
    final authRepository = FakeAuthRepository();
    final dependencies = AppDependencies.create(
      executor: NativeDatabase.memory(),
      authRepository: authRepository,
      aiClient: AiClient.demo(),
    );
    final cubit = NotesCubit(dependencies.noteRepository);

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<NotesCubit>.value(
          value: cubit,
          child: Builder(
            builder: (BuildContext context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(
                    builder: (_) => NoteEditorPage(
                      cubit: cubit,
                      summaryRepository: dependencies.summaryRepository,
                    ),
                  ),
                ),
                child: const Text('Mở trình soạn'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Mở trình soạn'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Ghi chú mới');
    await tester.enterText(find.byType(TextField).last, 'Nội dung cần giữ lại');

    await tester.state<NavigatorState>(find.byType(Navigator)).maybePop();
    await tester.pumpAndSettle();

    final notes = await dependencies.noteRepository.getNotes();
    expect(notes, hasLength(1));
    expect(notes.single.title, 'Ghi chú mới');
    expect(notes.single.content, 'Nội dung cần giữ lại');

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await cubit.close();
    await dependencies.dispose();
    await authRepository.dispose();
  });
}

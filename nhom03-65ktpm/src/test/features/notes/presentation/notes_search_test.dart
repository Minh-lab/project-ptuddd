import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_note/features/notes/data/repositories/development_note_repository.dart';
import 'package:smart_note/features/notes/presentation/bloc/notes_cubit.dart';
import 'package:smart_note/features/notes/presentation/pages/notes_page.dart';
import 'package:smart_note/features/notes/presentation/widgets/note_tile.dart';

void main() {
  testWidgets('debounces input, highlights matches and clears the query', (
    WidgetTester tester,
  ) async {
    final repository = DevelopmentNoteRepository();
    final cubit = NotesCubit(repository)..load();

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<NotesCubit>.value(
          value: cubit,
          child: const NotesPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(NoteTile), findsNWidgets(2));

    await tester.enterText(find.byType(TextField), 'ghi chu');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 299));
    expect(find.byType(NoteTile), findsNWidgets(2));

    await tester.pump(const Duration(milliseconds: 1));
    expect(find.byType(NoteTile), findsOneWidget);
    expect(find.text('Ghi chú phát triển'), findsOneWidget);
    final titleRichText = tester.widget<RichText>(
      find
          .descendant(
            of: find.byType(NoteTile),
            matching: find.byType(RichText),
          )
          .first,
    );
    expect(
      (titleRichText.text as TextSpan).children!.any(
        (InlineSpan span) => span.style?.backgroundColor != null,
      ),
      isTrue,
    );

    await tester.enterText(find.byType(TextField), 'khong co ket qua');
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Không tìm thấy ghi chú phù hợp'), findsOneWidget);

    await tester.tap(find.byTooltip('Xóa tìm kiếm'));
    await tester.pump();
    expect(find.byType(NoteTile), findsNWidgets(2));

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await cubit.close();
    await repository.dispose();
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_note/features/notes/data/repositories/development_note_repository.dart';
import 'package:smart_note/features/notes/domain/entities/note.dart';
import 'package:smart_note/features/notes/presentation/bloc/notes_cubit.dart';
import 'package:smart_note/features/notes/presentation/pages/notes_page.dart';
import 'package:smart_note/features/notes/presentation/widgets/note_tile.dart';
import 'package:smart_note/features/notes/domain/usecases/note_search.dart';

void main() {
  testWidgets('highlights an accent-insensitive title match', (
    WidgetTester tester,
  ) async {
    final note = Note(
      id: 'highlight',
      title: 'Ghi chú phát triển',
      content: 'Nội dung',
      kind: NoteKind.note,
      createdAt: DateTime(2026, 11, 25),
      updatedAt: DateTime(2026, 11, 25),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NoteTile(note: note, searchQuery: 'ghi chu'),
        ),
      ),
    );

    final titleRichTextFinder = find.descendant(
      of: find.byType(NoteTile),
      matching: find.byWidgetPredicate(
        (Widget widget) =>
            widget is RichText &&
            widget.text.toPlainText() == 'Ghi chú phát triển',
      ),
    );
    final titleRichTexts = tester.widgetList<RichText>(titleRichTextFinder);
    expect(
      titleRichTexts.any((RichText text) => _hasHighlightedSpan(text.text)),
      isTrue,
    );
  });

  testWidgets('debounces input, highlights matches and clears the query', (
    WidgetTester tester,
  ) async {
    final repository = DevelopmentNoteRepository();
    final cubit = NotesCubit(repository)..load();
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await cubit.close();
      await repository.dispose();
    });

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
    final titleRichTextFinder = find.descendant(
      of: find.byType(NoteTile),
      matching: find.byWidgetPredicate(
        (Widget widget) =>
            widget is RichText &&
            widget.text.toPlainText() == 'Ghi chú phát triển',
      ),
    );
    final titleRichTexts = tester.widgetList<RichText>(titleRichTextFinder);
    expect(cubit.state.searchQuery, 'ghi chu');
    expect(
      const NoteSearch().highlightRanges(
        'Ghi chú phát triển',
        cubit.state.searchQuery,
      ),
      isNotEmpty,
    );
    expect(
      titleRichTexts.any((RichText text) => _hasHighlightedSpan(text.text)),
      isTrue,
    );

    await tester.enterText(find.byType(TextField), 'khong co ket qua');
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Không tìm thấy ghi chú phù hợp'), findsOneWidget);

    await tester.tap(find.byTooltip('Xóa tìm kiếm'));
    await tester.pump();
    expect(find.byType(NoteTile), findsNWidgets(2));
  });
}

bool _hasHighlightedSpan(InlineSpan root) {
  final pending = <InlineSpan>[root];
  while (pending.isNotEmpty) {
    final span = pending.removeLast();
    if (span is TextSpan) {
      if (span.style?.backgroundColor != null) return true;
      pending.addAll(span.children ?? const <InlineSpan>[]);
    }
  }
  return false;
}

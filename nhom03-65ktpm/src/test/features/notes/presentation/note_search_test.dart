import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_note/app.dart';
import 'package:smart_note/core/di/app_dependencies.dart';
import 'package:smart_note/features/auth/domain/entities/app_user.dart';
import 'package:smart_note/features/notes/domain/entities/note.dart';
import 'package:smart_note/features/notes/domain/services/note_search.dart';

import '../../../support/fake_auth_repository.dart';

void main() {
  group('NoteSearch', () {
    final notes = <Note>[
      _note(
        id: 'vietnamese',
        title: 'Đọc Sách Tiếng Việt',
        content: 'Ôn tập Toán',
      ),
      _note(id: 'physics', title: 'Vật lý', content: 'Công thức chuyển động'),
    ];

    test('tìm không dấu trong tiêu đề tiếng Việt có dấu', () {
      expect(
        NoteSearch.filter(notes, 'doc sach tieng viet').map((note) => note.id),
        <String>['vietnamese'],
      );
    });

    test('tìm không dấu trong nội dung và không phân biệt hoa thường', () {
      expect(
        NoteSearch.filter(notes, 'ON TAP TOAN').map((note) => note.id),
        <String>['vietnamese'],
      );
    });

    test('trả về tất cả ghi chú khi truy vấn trống', () {
      expect(NoteSearch.filter(notes, '  '), notes);
    });

    test('không có kết quả khi không ghi chú nào khớp', () {
      expect(NoteSearch.filter(notes, 'khong co'), isEmpty);
    });
  });

  testWidgets('debounce tìm kiếm và tô sáng khớp ở tiêu đề lẫn nội dung', (
    WidgetTester tester,
  ) async {
    final authRepository = FakeAuthRepository(
      initialUser: const AppUser(id: 'uid-search', email: 'search@example.com'),
    );
    final dependencies = AppDependencies.create(
      executor: NativeDatabase.memory(),
      authRepository: authRepository,
    );
    final noteRepository = dependencies.noteRepositoryForUser('uid-search');
    await noteRepository.createNote(
      _note(
        id: 'vietnamese',
        title: 'Đọc Sách Tiếng Việt',
        content: 'Ôn tập Toán',
      ),
    );
    await noteRepository.createNote(
      _note(id: 'physics', title: 'Vật lý', content: 'Công thức chuyển động'),
    );

    try {
      await tester.pumpWidget(SmartNoteApp(dependencies: dependencies));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const ValueKey<String>('notes-search-field')),
        'tieng viet',
      );
      await tester.pump(const Duration(milliseconds: 299));
      expect(find.text('Vật lý', findRichText: true), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 1));
      expect(find.text('Vật lý', findRichText: true), findsNothing);
      expect(
        find.text('Đọc Sách Tiếng Việt', findRichText: true),
        findsOneWidget,
      );
      expect(_hasHighlightedText(tester), isTrue);

      await tester.enterText(
        find.byKey(const ValueKey<String>('notes-search-field')),
        'on tap',
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        find.text('Đọc Sách Tiếng Việt', findRichText: true),
        findsOneWidget,
      );
      expect(_hasHighlightedText(tester), isTrue);

      await tester.enterText(
        find.byKey(const ValueKey<String>('notes-search-field')),
        'khong co ket qua',
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Không tìm thấy ghi chú phù hợp'), findsOneWidget);

      await tester.tap(find.byTooltip('Xóa tìm kiếm'));
      await tester.pump();
      expect(
        find.text('Đọc Sách Tiếng Việt', findRichText: true),
        findsOneWidget,
      );
      expect(find.text('Vật lý', findRichText: true), findsOneWidget);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await tester.runAsync(dependencies.dispose);
      await tester.runAsync(authRepository.dispose);
    }
  });
}

bool _hasHighlightedText(WidgetTester tester) {
  return tester.widgetList<RichText>(find.byType(RichText)).any((richText) {
    return _spanHasHighlight(richText.text);
  });
}

bool _spanHasHighlight(InlineSpan span) {
  if (span is! TextSpan) return false;
  if (span.style?.backgroundColor != null) return true;
  return span.children?.any(_spanHasHighlight) ?? false;
}

Note _note({
  required String id,
  required String title,
  required String content,
}) {
  final now = DateTime(2026, 11, 26);
  return Note(
    id: id,
    title: title,
    content: content,
    kind: NoteKind.note,
    createdAt: now,
    updatedAt: now,
  );
}

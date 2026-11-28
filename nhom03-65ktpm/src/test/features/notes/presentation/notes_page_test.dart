import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_note/core/database/app_database.dart';
import 'package:smart_note/core/di/app_dependencies.dart';
import 'package:smart_note/core/theme/app_theme.dart';
import 'package:smart_note/features/notes/domain/entities/note.dart';
import 'package:smart_note/features/notes/presentation/bloc/notes_cubit.dart';
import 'package:smart_note/features/notes/presentation/pages/notes_page.dart';
import 'package:smart_note/features/notes/presentation/widgets/note_card.dart';

import '../../../support/fake_auth_repository.dart';

void main() {
  late FakeAuthRepository authRepository;
  late AppDependencies dependencies;

  setUp(() async {
    authRepository = FakeAuthRepository();
    dependencies = AppDependencies.create(
      executor: NativeDatabase.memory(),
      authRepository: authRepository,
    );
    final now = DateTime(2026, 11, 24, 9);
    await dependencies.noteRepository.createNote(
      Note(
        id: 'note-1',
        title: 'Giải tích – Chương 3',
        content: 'Đạo hàm và tích phân.',
        kind: NoteKind.note,
        createdAt: now,
        updatedAt: now,
        tags: const <String>['Toán'],
      ),
    );
    await dependencies.noteRepository.createNote(
      Note(
        id: 'note-2',
        title: 'Nhật ký hôm nay',
        content: 'Học xong chương 3.',
        kind: NoteKind.diary,
        createdAt: now,
        updatedAt: now,
        tags: const <String>['Nhật ký'],
      ),
    );
    await dependencies.noteRepository.createNote(
      Note(
        id: 'note-3',
        title: 'Vật lý – Điện từ',
        content: 'Định luật Faraday.',
        kind: NoteKind.note,
        createdAt: now,
        updatedAt: now,
        tags: const <String>['Vật lý'],
      ),
    );
    await dependencies.quizScoresDao.insertScore(
      QuizScoresCompanion.insert(
        id: 'score-1',
        noteId: 'note-1',
        noteTitle: const Value('Giải tích – Chương 3'),
        correctAnswers: 1,
        totalQuestions: 1,
        completedAt: Value(now),
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

  testWidgets('Lưới ghi chú có tiêu đề chủ đề và mở bộ lọc môn', (
    WidgetTester tester,
  ) async {
    await pumpPage(tester);

    expect(find.text('Ghi chú'), findsWidgets);
    expect(find.text('2 ghi chú'), findsOneWidget);
    expect(find.text('Theo chủ đề'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, 'Tất cả'), findsOneWidget);
    await tester.tap(find.byTooltip('Bộ lọc và công cụ'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(ChoiceChip, 'Tất cả'), findsNothing);
    await tester.tap(find.byTooltip('Bộ lọc và công cụ'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(ChoiceChip, 'Toán'), findsOneWidget);
    expect(find.byType(NoteCard), findsNWidgets(2));
    expect(find.text('Giải tích – Chương 3'), findsOneWidget);

    await disposePage(tester);
  });

  testWidgets('Lọc theo chip môn học chỉ giữ ghi chú đúng môn', (
    WidgetTester tester,
  ) async {
    await pumpPage(tester);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Toán'));
    await tester.pumpAndSettle();

    expect(find.text('Giải tích – Chương 3'), findsOneWidget);
    expect(find.text('Nhật ký hôm nay'), findsNothing);
    expect(find.text('Vật lý – Điện từ'), findsNothing);
    expect(find.text('1/2 ghi chú phù hợp'), findsOneWidget);

    await disposePage(tester);
  });

  testWidgets('Các thẻ cùng kích thước ở màn hình nhỏ và cỡ chữ lớn', (
    WidgetTester tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(376, 718);
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await pumpPage(tester);

    final cards = find.byType(NoteCard);
    expect(tester.getSize(cards.first).width, tester.getSize(cards.last).width);
    expect(tester.getRect(cards.first).top, tester.getRect(cards.last).top);
    expect(
      tester.getSize(cards.first).height,
      tester.getSize(cards.last).height,
    );
    expect(tester.takeException(), isNull);
    await disposePage(tester);
  });

  testWidgets('Ôn tập từ ghi chú và lật thẻ để xem nội dung', (tester) async {
    await pumpPage(tester);
    expect(find.text('AI Quiz'), findsOneWidget);
    await tester.tap(find.text('Ôn tập /\nFlashcard'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Giải tích – Chương 3').last);
    await tester.pumpAndSettle();
    expect(find.text('Giải tích – Chương 3'), findsOneWidget);
    expect(find.text('Đạo hàm và tích phân.'), findsNothing);
    await tester.tap(find.text('Lật để xem nội dung'));
    await tester.pumpAndSettle();
    expect(find.text('Đạo hàm và tích phân.'), findsOneWidget);
    await disposePage(tester);
  });

  testWidgets('Nhấn giữ một thẻ thì vào chế độ chọn để xuất Word', (
    WidgetTester tester,
  ) async {
    await pumpPage(tester);

    await tester.longPress(find.text('Giải tích – Chương 3'));
    await tester.pumpAndSettle();

    expect(find.text('1 đã chọn'), findsOneWidget);
    expect(find.byTooltip('Xuất Word'), findsOneWidget);
    expect(find.byTooltip('Tạo ghi chú'), findsNothing);

    await tester.tap(find.byTooltip('Huỷ chọn'));
    await tester.pumpAndSettle();
    expect(find.text('2 ghi chú'), findsOneWidget);

    await disposePage(tester);
  });
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_note/core/theme/app_theme.dart';
import 'package:smart_note/features/stats/domain/entities/study_note.dart';
import 'package:smart_note/features/stats/domain/repositories/study_activity_source.dart';
import 'package:smart_note/features/stats/presentation/bloc/stats_cubit.dart';
import 'package:smart_note/features/stats/presentation/pages/stats_page.dart';

/// Nguồn ghi chú giả, có thể đẩy danh sách mới như khi người dùng viết thêm.
class _FakeSource implements StudyActivitySource {
  _FakeSource(this._initial);

  final List<StudyNote> _initial;
  final StreamController<List<StudyNote>> _controller =
      StreamController<List<StudyNote>>.broadcast();

  void push(List<StudyNote> notes) => _controller.add(notes);

  @override
  Stream<List<StudyNote>> watchStudyNotes() async* {
    yield _initial;
    yield* _controller.stream;
  }
}

/// Thứ Bảy 28/11/2026, 21:00.
final DateTime _now = DateTime(2026, 11, 28, 21);

StudyNote _note(String id, int day, {int month = 11, bool diary = false}) =>
    StudyNote(id: id, createdAt: DateTime(2026, month, day, 9), isDiary: diary);

void main() {
  Future<_FakeSource> pumpPage(
    WidgetTester tester,
    List<StudyNote> notes,
  ) async {
    final source = _FakeSource(notes);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: BlocProvider<StatsCubit>(
          create: (_) => StatsCubit(source, clock: () => _now)..load(),
          child: const StatsPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return source;
  }

  String textOf(WidgetTester tester, String key) =>
      tester.widget<Text>(find.byKey(ValueKey<String>(key))).data!;

  testWidgets('chưa có ghi chú: streak 0 và gợi ý bắt đầu chuỗi', (
    WidgetTester tester,
  ) async {
    await pumpPage(tester, <StudyNote>[]);

    expect(textOf(tester, 'streak-current'), '0');
    expect(textOf(tester, 'streak-longest'), '0 ngày');
    expect(
      find.text('Viết một ghi chú hôm nay để bắt đầu chuỗi mới.'),
      findsOneWidget,
    );
    expect(textOf(tester, 'week-total'), '0 ghi chú');
  });

  testWidgets('hôm nay chưa học thì cảnh báo giữ chuỗi; viết ghi chú thì '
      'streak tăng ngay', (WidgetTester tester) async {
    final notes = <StudyNote>[_note('a', 26), _note('b', 27)];
    final source = await pumpPage(tester, notes);

    expect(textOf(tester, 'streak-current'), '2');
    expect(
      find.text('Viết một ghi chú hôm nay để giữ chuỗi 2 ngày.'),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);

    source.push(<StudyNote>[...notes, _note('c', 28)]);
    await tester.pumpAndSettle();

    expect(textOf(tester, 'streak-current'), '3');
    expect(find.text('Hôm nay bạn đã học rồi. Giữ vững nhé!'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
  });

  testWidgets('tổng quan: tổng ghi chú, nhật ký, ngày học trong tháng', (
    WidgetTester tester,
  ) async {
    await pumpPage(tester, <StudyNote>[
      _note('a', 2),
      _note('b', 2, diary: true),
      _note('c', 28, diary: true),
      _note('d', 30, month: 10),
    ]);

    String tileValue(String key) => tester
        .widget<Text>(
          find
              .descendant(
                of: find.byKey(ValueKey<String>(key)),
                matching: find.byType(Text),
              )
              .first,
        )
        .data!;

    expect(tileValue('stat-total-notes'), '4');
    expect(tileValue('stat-diary'), '2');
    expect(tileValue('stat-month-days'), '2');
  });

  testWidgets('biểu đồ tuần: tổng, so với tuần trước và chuyển tuần', (
    WidgetTester tester,
  ) async {
    await pumpPage(tester, <StudyNote>[
      _note('a', 17), // tuần 16–22/11
      _note('b', 23),
      _note('c', 23),
      _note('d', 25),
    ]);

    expect(find.text('Tuần này · 23/11 – 29/11/2026'), findsOneWidget);
    expect(textOf(tester, 'week-total'), '3 ghi chú');
    expect(textOf(tester, 'week-delta'), '+2 so với tuần trước');
    // Không cho xem tuần tương lai.
    expect(
      tester
          .widget<IconButton>(find.byKey(const ValueKey<String>('next-week')))
          .onPressed,
      isNull,
    );

    await tester.tap(find.byKey(const ValueKey<String>('previous-week')));
    await tester.pumpAndSettle();

    expect(find.text('16/11 – 22/11/2026'), findsOneWidget);
    expect(textOf(tester, 'week-total'), '1 ghi chú');
    expect(textOf(tester, 'week-delta'), '+1 so với tuần trước');

    await tester.tap(find.byKey(const ValueKey<String>('next-week')));
    await tester.pumpAndSettle();
    expect(find.text('Tuần này · 23/11 – 29/11/2026'), findsOneWidget);
  });

  testWidgets('mỗi cột có mô tả đầy đủ và xem được dạng bảng', (
    WidgetTester tester,
  ) async {
    await pumpPage(tester, <StudyNote>[
      _note('a', 23),
      _note('b', 23),
      _note('c', 25),
    ]);

    // Tooltip/trình đọc màn hình đọc được số của từng ngày.
    expect(find.byTooltip('Thứ Hai 23/11: 2 ghi chú'), findsOneWidget);
    expect(find.byTooltip('Thứ Tư 25/11: 1 ghi chú'), findsOneWidget);

    final weekly = find.byKey(const ValueKey<String>('weekly-chart'));
    final toTable = find.descendant(
      of: weekly,
      matching: find.text('Xem dạng bảng'),
    );
    await tester.ensureVisible(toTable);
    await tester.pumpAndSettle();
    await tester.tap(toTable);
    await tester.pumpAndSettle();

    expect(
      find.descendant(of: weekly, matching: find.text('Xem biểu đồ')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: weekly, matching: find.text('T2')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: weekly, matching: find.text('2')),
      findsOneWidget,
    );
  });

  testWidgets('dải 7 ngày đánh dấu đúng ngày có học trong tuần này', (
    WidgetTester tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pumpPage(tester, <StudyNote>[_note('a', 23), _note('b', 28)]);

    expect(find.bySemanticsLabel('Thứ Hai 23/11: có học'), findsOneWidget);
    expect(find.bySemanticsLabel('Thứ Ba 24/11: chưa học'), findsOneWidget);
    expect(find.bySemanticsLabel('Thứ Bảy 28/11: có học'), findsOneWidget);
    expect(find.bySemanticsLabel('Chủ nhật 29/11: chưa tới'), findsOneWidget);
    semantics.dispose();
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_note/features/reminders/domain/entities/notification_permission.dart';
import 'package:smart_note/features/reminders/domain/entities/reminder.dart';
import 'package:smart_note/features/reminders/domain/entities/reminder_note.dart';
import 'package:smart_note/features/reminders/presentation/bloc/reminders_cubit.dart';
import 'package:smart_note/features/reminders/presentation/pages/reminders_page.dart';

import '../../../support/fake_reminders.dart';

/// Thứ Bảy 28/11/2026, 14:10 — form mặc định gợi ý 15:00.
final DateTime _now = DateTime(2026, 11, 28, 14, 10);

const List<ReminderNote> _notes = <ReminderNote>[
  ReminderNote(id: 'n1', title: 'Đạo hàm'),
  ReminderNote(id: 'n2', title: 'Từ vựng tiếng Anh'),
];

void main() {
  Future<void> pumpPage(
    WidgetTester tester,
    FakeReminderRepository repository, {
    List<ReminderNote> notes = _notes,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<RemindersCubit>(
          create: (_) => RemindersCubit(
            repository,
            FakeReminderNoteSource(notes),
            clock: () => _now,
          )..load(),
          child: const RemindersPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('chưa có ghi chú thì hướng dẫn tạo ghi chú trước', (
    WidgetTester tester,
  ) async {
    await pumpPage(tester, FakeReminderRepository(), notes: <ReminderNote>[]);

    expect(find.text('Chưa có ghi chú nào'), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('add-reminder')), findsNothing);
  });

  testWidgets('tạo nhắc nhở hằng ngày rồi thấy trong danh sách', (
    WidgetTester tester,
  ) async {
    final repository = FakeReminderRepository();
    await pumpPage(tester, repository);
    expect(find.text('Chưa có nhắc nhở'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey<String>('add-reminder')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hằng ngày'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('save-reminder')));
    await tester.pumpAndSettle();

    final saved = repository.reminders.single;
    expect(saved.noteId, 'n1');
    expect(saved.repeat, ReminderRepeat.daily);
    expect(saved.hour, 15);
    expect(find.text('Đạo hàm'), findsOneWidget);
    expect(
      find.text('Hằng ngày · 15:00\nLần tới: 28/11/2026 15:00'),
      findsOneWidget,
    );
    expect(find.text('Đã lưu nhắc nhở.'), findsOneWidget);
  });

  testWidgets('theo thứ mà bỏ hết các thứ thì báo lỗi ngay trên form', (
    WidgetTester tester,
  ) async {
    final repository = FakeReminderRepository();
    await pumpPage(tester, repository);

    await tester.tap(find.byKey(const ValueKey<String>('add-reminder')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Theo thứ'));
    await tester.pumpAndSettle();
    // Mặc định chọn sẵn thứ hôm nay (thứ Bảy); bỏ chọn.
    await tester.tap(find.byKey(const ValueKey<String>('weekday-6')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('save-reminder')));
    await tester.pumpAndSettle();

    expect(find.text('Hãy chọn ít nhất một ngày trong tuần.'), findsOneWidget);
    expect(repository.reminders, isEmpty);
  });

  testWidgets('chưa có quyền thì hỏi quyền khi lưu; bị từ chối thì hướng '
      'dẫn mở cài đặt', (WidgetTester tester) async {
    final repository = FakeReminderRepository(
      permission: NotificationPermission.denied,
      permissionAfterRequest: NotificationPermission.denied,
    );
    await pumpPage(tester, repository);
    expect(
      find.byKey(const ValueKey<String>('notification-permission-banner')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey<String>('add-reminder')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('save-reminder')));
    await tester.pumpAndSettle();

    expect(repository.requestCount, 1);
    // Nhắc nhở vẫn được lưu, chỉ là chưa hiện thông báo.
    expect(repository.reminders, hasLength(1));
    expect(
      find.text('Đã lưu, nhưng thông báo đang tắt nên sẽ chưa được nhắc.'),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('open-notification-settings')),
    );
    await tester.pump();
    expect(repository.openSettingsCount, 1);
  });

  testWidgets('đã có quyền thì không hỏi lại và không hiện hướng dẫn', (
    WidgetTester tester,
  ) async {
    final repository = FakeReminderRepository();
    await pumpPage(tester, repository);

    await tester.tap(find.byKey(const ValueKey<String>('add-reminder')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('save-reminder')));
    await tester.pumpAndSettle();

    expect(repository.requestCount, 0);
    expect(
      find.byKey(const ValueKey<String>('notification-permission-banner')),
      findsNothing,
    );
  });

  testWidgets('sửa nhắc nhở rồi xoá sau khi xác nhận', (
    WidgetTester tester,
  ) async {
    final repository = FakeReminderRepository(
      reminders: <Reminder>[
        Reminder(
          id: 'r1',
          noteId: 'n2',
          repeat: ReminderRepeat.weekly,
          remindAt: DateTime(2026, 1, 1, 19, 30),
          weekdays: const <int>[1, 3, 5],
          createdAt: _now,
          updatedAt: _now,
        ),
      ],
    );
    await pumpPage(tester, repository);
    expect(
      find.text('T2, T4, T6 · 19:30\nLần tới: 30/11/2026 19:30'),
      findsOneWidget,
    );

    // Sửa: thêm thứ Bảy.
    await tester.tap(find.text('Từ vựng tiếng Anh'));
    await tester.pumpAndSettle();
    expect(find.text('Sửa nhắc nhở'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey<String>('weekday-6')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('save-reminder')));
    await tester.pumpAndSettle();
    expect(repository.reminders.single.weekdays, <int>[1, 3, 5, 6]);
    expect(
      find.text('T2, T4, T6, T7 · 19:30\nLần tới: 28/11/2026 19:30'),
      findsOneWidget,
    );

    // Xoá.
    await tester.tap(find.byKey(const ValueKey<String>('delete-reminder-r1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xoá'));
    await tester.pumpAndSettle();
    expect(repository.reminders, isEmpty);
    expect(find.text('Chưa có nhắc nhở'), findsOneWidget);
  });

  testWidgets('nhắc nhở của ghi chú đã xoá được đánh dấu rõ', (
    WidgetTester tester,
  ) async {
    final repository = FakeReminderRepository(
      reminders: <Reminder>[
        Reminder(
          id: 'r1',
          noteId: 'da-xoa',
          repeat: ReminderRepeat.daily,
          remindAt: DateTime(2026, 1, 1, 20),
          createdAt: _now,
          updatedAt: _now,
        ),
      ],
    );
    await pumpPage(tester, repository);

    expect(find.text('Ghi chú đã bị xoá'), findsOneWidget);
    expect(find.text('Hằng ngày · 20:00\nSẽ không nhắc nữa'), findsOneWidget);
  });
}

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_note/core/database/app_database.dart';
import 'package:smart_note/core/database/reminders_dao.dart';
import 'package:smart_note/core/error/failure.dart';
import 'package:smart_note/features/reminders/data/models/reminder_notification_ids.dart';
import 'package:smart_note/features/reminders/data/repositories/reminder_repository_impl.dart';
import 'package:smart_note/features/reminders/domain/entities/reminder.dart';
import 'package:smart_note/features/reminders/domain/entities/reminder_note.dart';
import 'package:smart_note/features/reminders/domain/usecases/reminder_schedule.dart';

import '../../../support/fake_reminders.dart';

/// Thứ Bảy 28/11/2026, 14:10.
final DateTime _now = DateTime(2026, 11, 28, 14, 10);

Reminder _reminder(
  String id,
  ReminderRepeat repeat,
  DateTime remindAt, {
  String noteId = 'n1',
  List<int> weekdays = const <int>[],
}) => Reminder(
  id: id,
  noteId: noteId,
  repeat: repeat,
  remindAt: remindAt,
  weekdays: weekdays,
  createdAt: _now,
  updatedAt: _now,
);

void main() {
  late AppDatabase database;
  late FakeReminderNotifications notifications;
  late FakeReminderNoteSource notes;
  late ReminderRepositoryImpl repository;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    notifications = FakeReminderNotifications();
    notes = FakeReminderNoteSource(const <ReminderNote>[
      ReminderNote(id: 'n1', title: 'Đạo hàm'),
      ReminderNote(id: 'n2', title: ''),
    ]);
    repository = ReminderRepositoryImpl(
      dao: () => RemindersDao(database),
      notifications: notifications,
      notes: notes,
      clock: () => _now,
    );
  });

  tearDown(() async {
    await database.close();
  });

  test('lưu nhắc nhở thì đọc lại đủ dữ liệu, kể cả các thứ', () async {
    final reminder = _reminder(
      'r1',
      ReminderRepeat.weekly,
      DateTime(2026, 11, 28, 19, 30),
      weekdays: <int>[1, 3, 5],
    );

    await repository.saveReminder(reminder);

    expect(await repository.watchReminders().first, <Reminder>[reminder]);
  });

  test('nhắc một lần: lên lịch đúng giờ, mở đúng ghi chú khi bấm', () async {
    await repository.saveReminder(
      _reminder('r1', ReminderRepeat.once, DateTime(2026, 12, 1, 8)),
    );

    final scheduled = notifications.scheduled.values.single;
    expect(scheduled.id, reminderNotificationId('r1', 0));
    expect(scheduled.at, DateTime(2026, 12, 1, 8));
    expect(scheduled.match, ReminderMatch.none);
    expect(scheduled.title, ReminderRepositoryImpl.notificationTitle);
    expect(scheduled.body, 'Ôn lại: Đạo hàm');
    expect(scheduled.payload, 'n1');
  });

  test('ghi chú chưa có tiêu đề vẫn có nội dung thông báo', () async {
    await repository.saveReminder(
      _reminder(
        'r1',
        ReminderRepeat.daily,
        DateTime(2026, 1, 1, 20),
        noteId: 'n2',
      ),
    );

    expect(
      notifications.scheduled.values.single.body,
      'Ôn lại: (Chưa có tiêu đề)',
    );
  });

  test('sửa từ theo thứ sang hằng ngày thì huỷ thông báo cũ', () async {
    final weekly = _reminder(
      'r1',
      ReminderRepeat.weekly,
      DateTime(2026, 1, 1, 9),
      weekdays: <int>[1, 6],
    );
    await repository.saveReminder(weekly);
    expect(
      notifications.scheduled.keys,
      unorderedEquals(<int>[
        reminderNotificationId('r1', 1),
        reminderNotificationId('r1', 6),
      ]),
    );

    await repository.saveReminder(
      weekly.copyWith(repeat: ReminderRepeat.daily, weekdays: <int>[]),
    );

    final daily = notifications.scheduled.values.single;
    expect(daily.id, reminderNotificationId('r1', 0));
    expect(daily.match, ReminderMatch.dailyTime);
    expect(daily.at, DateTime(2026, 11, 29, 9));
  });

  test('xoá nhắc nhở thì huỷ thông báo', () async {
    await repository.saveReminder(
      _reminder('r1', ReminderRepeat.daily, DateTime(2026, 1, 1, 20)),
    );

    await repository.deleteReminder('r1');

    expect(await repository.watchReminders().first, isEmpty);
    expect(notifications.scheduled, isEmpty);
  });

  test('xoá nhắc nhở không tồn tại báo lỗi', () async {
    expect(
      () => repository.deleteReminder('khong-co'),
      throwsA(isA<DatabaseFailure>()),
    );
  });

  test('ghi chú đã bị xoá thì không lên lịch', () async {
    await repository.saveReminder(
      _reminder(
        'r1',
        ReminderRepeat.daily,
        DateTime(2026, 1, 1, 20),
        noteId: 'da-xoa',
      ),
    );

    expect(notifications.scheduled, isEmpty);
  });

  test('lên lịch lại: huỷ hết thông báo chờ rồi đặt theo dữ liệu', () async {
    await repository.saveReminder(
      _reminder('r1', ReminderRepeat.daily, DateTime(2026, 1, 1, 20)),
    );
    await repository.saveReminder(
      _reminder('r2', ReminderRepeat.once, DateTime(2026, 11, 1, 8)),
    );
    notifications.scheduled.clear();

    await repository.rescheduleAll();

    expect(notifications.cancelAllCount, 1);
    // Nhắc một lần đã qua không được đặt lại.
    expect(notifications.scheduled.keys, <int>[
      reminderNotificationId('r1', 0),
    ]);
  });

  test('máy không hỗ trợ thông báo thì không lên lịch lại', () async {
    final unsupported = FakeReminderNotifications(isSupported: false);
    await ReminderRepositoryImpl(
      dao: () => RemindersDao(database),
      notifications: unsupported,
      notes: notes,
    ).rescheduleAll();

    expect(unsupported.cancelAllCount, 0);
  });

  group('Id thông báo', () {
    test('ổn định, khác nhau theo slot và nhỏ hơn 2^31', () {
      const id = '2f1c7a2e-8a4b-4c55-9d1e-0b3f6f7a9c10';
      expect(reminderNotificationId(id, 3), reminderNotificationId(id, 3));
      expect(allReminderNotificationIds(id).toSet(), hasLength(8));
      for (final value in allReminderNotificationIds(id)) {
        expect(value, lessThan(1 << 31));
        expect(value, greaterThanOrEqualTo(0));
      }
    });
  });
}

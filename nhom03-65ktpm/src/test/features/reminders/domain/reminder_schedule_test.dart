import 'package:flutter_test/flutter_test.dart';
import 'package:smart_note/features/reminders/domain/entities/reminder.dart';
import 'package:smart_note/features/reminders/domain/usecases/reminder_schedule.dart';

/// Thứ Bảy 28/11/2026, 14:10.
final DateTime _now = DateTime(2026, 11, 28, 14, 10);

Reminder _reminder(
  ReminderRepeat repeat,
  DateTime remindAt, {
  List<int> weekdays = const <int>[],
  String noteId = 'n1',
}) => Reminder(
  id: 'r1',
  noteId: noteId,
  repeat: repeat,
  remindAt: remindAt,
  weekdays: weekdays,
  createdAt: _now,
  updatedAt: _now,
);

void main() {
  test('28/11/2026 là thứ Bảy (mốc dùng trong test)', () {
    expect(_now.weekday, DateTime.saturday);
  });

  group('Một lần', () {
    test('thời điểm trong tương lai được lên lịch đúng lúc', () {
      final reminder = _reminder(ReminderRepeat.once, DateTime(2026, 12, 1, 8));

      expect(ReminderSchedule.validate(reminder, _now), isNull);
      expect(ReminderSchedule.triggersFor(reminder, _now), <ReminderTrigger>[
        ReminderTrigger(
          slot: 0,
          firstAt: DateTime(2026, 12, 1, 8),
          match: ReminderMatch.none,
        ),
      ]);
    });

    test('thời điểm đã qua thì báo lỗi và không lên lịch', () {
      final reminder = _reminder(
        ReminderRepeat.once,
        DateTime(2026, 11, 28, 14),
      );

      expect(
        ReminderSchedule.validate(reminder, _now),
        'Thời điểm nhắc đã qua, hãy chọn lúc khác.',
      );
      expect(ReminderSchedule.triggersFor(reminder, _now), isEmpty);
      expect(ReminderSchedule.nextOccurrence(reminder, _now), isNull);
    });
  });

  group('Hằng ngày', () {
    test('giờ chưa tới thì báo ngay hôm nay', () {
      final reminder = _reminder(
        ReminderRepeat.daily,
        DateTime(2026, 1, 1, 15),
      );

      expect(
        ReminderSchedule.nextOccurrence(reminder, _now),
        DateTime(2026, 11, 28, 15),
      );
      expect(
        ReminderSchedule.triggersFor(reminder, _now).single.match,
        ReminderMatch.dailyTime,
      );
    });

    test('giờ đã qua thì báo từ ngày mai, kể cả sang tháng mới', () {
      final reminder = _reminder(
        ReminderRepeat.daily,
        DateTime(2026, 1, 1, 9, 30),
      );

      expect(
        ReminderSchedule.nextOccurrence(reminder, DateTime(2026, 11, 30, 10)),
        DateTime(2026, 12, 1, 9, 30),
      );
    });
  });

  group('Theo thứ', () {
    test('mỗi thứ là một thông báo riêng, lần gần nhất là thứ Hai', () {
      final reminder = _reminder(
        ReminderRepeat.weekly,
        DateTime(2026, 1, 1, 9),
        weekdays: <int>[DateTime.monday, DateTime.saturday],
      );

      expect(ReminderSchedule.triggersFor(reminder, _now), <ReminderTrigger>[
        ReminderTrigger(
          slot: DateTime.monday,
          firstAt: DateTime(2026, 11, 30, 9),
          match: ReminderMatch.weeklyDayAndTime,
        ),
        // Thứ Bảy 9:00 hôm nay đã qua nên dời sang tuần sau.
        ReminderTrigger(
          slot: DateTime.saturday,
          firstAt: DateTime(2026, 12, 5, 9),
          match: ReminderMatch.weeklyDayAndTime,
        ),
      ]);
      expect(
        ReminderSchedule.nextOccurrence(reminder, _now),
        DateTime(2026, 11, 30, 9),
      );
    });

    test('đúng thứ hôm nay và giờ chưa tới thì báo hôm nay', () {
      final reminder = _reminder(
        ReminderRepeat.weekly,
        DateTime(2026, 1, 1, 20),
        weekdays: <int>[DateTime.saturday],
      );

      expect(
        ReminderSchedule.nextOccurrence(reminder, _now),
        DateTime(2026, 11, 28, 20),
      );
    });

    test('bỏ thứ trùng hoặc không hợp lệ', () {
      final reminder = _reminder(
        ReminderRepeat.weekly,
        DateTime(2026, 1, 1, 20),
        weekdays: <int>[6, 6, 9, 0],
      );

      expect(
        ReminderSchedule.triggersFor(
          reminder,
          _now,
        ).map((ReminderTrigger t) => t.slot),
        <int>[6],
      );
    });

    test('chưa chọn thứ nào thì báo lỗi', () {
      expect(
        ReminderSchedule.validate(
          _reminder(ReminderRepeat.weekly, DateTime(2026, 1, 1, 20)),
          _now,
        ),
        'Hãy chọn ít nhất một ngày trong tuần.',
      );
    });
  });

  test('chưa chọn ghi chú thì báo lỗi', () {
    expect(
      ReminderSchedule.validate(
        _reminder(ReminderRepeat.daily, DateTime(2026, 1, 1, 20), noteId: ''),
        _now,
      ),
      'Hãy chọn ghi chú cần nhắc.',
    );
  });
}

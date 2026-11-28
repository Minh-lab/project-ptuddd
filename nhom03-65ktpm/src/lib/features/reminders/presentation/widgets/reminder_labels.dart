import '../../domain/entities/reminder.dart';

/// Chuỗi hiển thị cho nhắc nhở (chỉ định dạng, không chứa logic nghiệp vụ).
class ReminderLabels {
  const ReminderLabels._();

  static const Map<int, String> _weekdayShort = <int, String>{
    DateTime.monday: 'T2',
    DateTime.tuesday: 'T3',
    DateTime.wednesday: 'T4',
    DateTime.thursday: 'T5',
    DateTime.friday: 'T6',
    DateTime.saturday: 'T7',
    DateTime.sunday: 'CN',
  };

  static String weekdayShort(int weekday) => _weekdayShort[weekday] ?? '?';

  static String repeatName(ReminderRepeat repeat) => switch (repeat) {
    ReminderRepeat.once => 'Một lần',
    ReminderRepeat.daily => 'Hằng ngày',
    ReminderRepeat.weekly => 'Theo thứ',
  };

  static String time(int hour, int minute) => '${_two(hour)}:${_two(minute)}';

  static String date(DateTime value) =>
      '${_two(value.day)}/${_two(value.month)}/${value.year}';

  static String dateTime(DateTime value) =>
      '${date(value)} ${time(value.hour, value.minute)}';

  /// Ví dụ: "Một lần · 30/11/2026 08:00", "Hằng ngày · 20:00",
  /// "T2, T4, T6 · 19:30".
  static String schedule(Reminder reminder) {
    final at = time(reminder.hour, reminder.minute);
    return switch (reminder.repeat) {
      ReminderRepeat.once => 'Một lần · ${dateTime(reminder.remindAt)}',
      ReminderRepeat.daily => 'Hằng ngày · $at',
      ReminderRepeat.weekly =>
        '${reminder.weekdays.map(weekdayShort).join(', ')} · $at',
    };
  }

  static String next(DateTime? next) =>
      next == null ? 'Đã qua' : 'Lần tới: ${dateTime(next)}';

  static String _two(int value) => value.toString().padLeft(2, '0');
}

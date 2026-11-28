import '../entities/reminder.dart';

/// Cách thông báo lặp lại sau lần báo đầu tiên.
enum ReminderMatch {
  /// Không lặp.
  none,

  /// Lặp mỗi ngày vào cùng giờ.
  dailyTime,

  /// Lặp mỗi tuần vào cùng thứ và giờ.
  weeklyDayAndTime,
}

/// Một lần lên lịch thông báo cho nhắc nhở.
///
/// Nhắc nhở theo thứ cần một thông báo riêng cho mỗi thứ, phân biệt bằng
/// [slot] (chính là số thứ 1…7); nhắc một lần và hằng ngày dùng slot 0.
class ReminderTrigger {
  const ReminderTrigger({
    required this.slot,
    required this.firstAt,
    required this.match,
  });

  final int slot;
  final DateTime firstAt;
  final ReminderMatch match;

  @override
  bool operator ==(Object other) =>
      other is ReminderTrigger &&
      other.slot == slot &&
      other.firstAt == firstAt &&
      other.match == match;

  @override
  int get hashCode => Object.hash(slot, firstAt, match);

  @override
  String toString() => 'ReminderTrigger($slot, $firstAt, $match)';
}

/// Quy tắc thời gian của nhắc nhở (Dart thuần, không phụ thuộc nền tảng).
class ReminderSchedule {
  const ReminderSchedule._();

  /// Thông báo lỗi nếu nhắc nhở chưa hợp lệ, `null` nếu lưu được.
  static String? validate(Reminder reminder, DateTime now) {
    if (reminder.noteId.trim().isEmpty) {
      return 'Hãy chọn ghi chú cần nhắc.';
    }
    switch (reminder.repeat) {
      case ReminderRepeat.once:
        if (!reminder.remindAt.isAfter(now)) {
          return 'Thời điểm nhắc đã qua, hãy chọn lúc khác.';
        }
      case ReminderRepeat.daily:
        break;
      case ReminderRepeat.weekly:
        if (reminder.weekdays.isEmpty) {
          return 'Hãy chọn ít nhất một ngày trong tuần.';
        }
    }
    return null;
  }

  /// Lần báo kế tiếp sau [now], `null` nếu nhắc một lần đã qua.
  static DateTime? nextOccurrence(Reminder reminder, DateTime now) {
    final triggers = triggersFor(reminder, now);
    if (triggers.isEmpty) return null;
    return triggers
        .map((ReminderTrigger t) => t.firstAt)
        .reduce((DateTime a, DateTime b) => a.isBefore(b) ? a : b);
  }

  /// Các thông báo cần lên lịch cho [reminder] tính từ [now].
  static List<ReminderTrigger> triggersFor(Reminder reminder, DateTime now) {
    switch (reminder.repeat) {
      case ReminderRepeat.once:
        if (!reminder.remindAt.isAfter(now)) return const <ReminderTrigger>[];
        return <ReminderTrigger>[
          ReminderTrigger(
            slot: 0,
            firstAt: reminder.remindAt,
            match: ReminderMatch.none,
          ),
        ];
      case ReminderRepeat.daily:
        return <ReminderTrigger>[
          ReminderTrigger(
            slot: 0,
            firstAt: _nextDaily(reminder, now),
            match: ReminderMatch.dailyTime,
          ),
        ];
      case ReminderRepeat.weekly:
        return <ReminderTrigger>[
          for (final weekday in reminder.weekdays.toSet().toList()..sort())
            if (weekday >= DateTime.monday && weekday <= DateTime.sunday)
              ReminderTrigger(
                slot: weekday,
                firstAt: _nextWeekday(reminder, weekday, now),
                match: ReminderMatch.weeklyDayAndTime,
              ),
        ];
    }
  }

  static DateTime _atDay(Reminder reminder, DateTime day, int addDays) {
    // Dựng lại từ ngày/tháng/năm để không lệch giờ khi cộng ngày.
    return DateTime(
      day.year,
      day.month,
      day.day + addDays,
      reminder.hour,
      reminder.minute,
    );
  }

  static DateTime _nextDaily(Reminder reminder, DateTime now) {
    final today = _atDay(reminder, now, 0);
    return today.isAfter(now) ? today : _atDay(reminder, now, 1);
  }

  static DateTime _nextWeekday(Reminder reminder, int weekday, DateTime now) {
    final daysAhead = (weekday - now.weekday) % 7;
    final candidate = _atDay(reminder, now, daysAhead);
    return candidate.isAfter(now) ? candidate : _atDay(reminder, now, 7);
  }
}

import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/entities/reminder.dart';

/// Chuyển đổi giữa model Drift ([ReminderRow]) và entity của domain.
extension ReminderRowMapper on ReminderRow {
  Reminder toEntity() {
    return Reminder(
      id: id,
      noteId: noteId,
      repeat: _repeatFromName(repeatRule),
      remindAt: remindAt,
      weekdays: _parseWeekdays(weekdays),
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

extension ReminderEntityMapper on Reminder {
  RemindersCompanion toCompanion() {
    return RemindersCompanion.insert(
      id: id,
      noteId: noteId,
      repeatRule: repeat.name,
      remindAt: remindAt,
      weekdays: Value<String>(weekdays.join(',')),
      createdAt: Value<DateTime>(createdAt),
      updatedAt: Value<DateTime>(updatedAt),
    );
  }
}

ReminderRepeat _repeatFromName(String name) {
  for (final repeat in ReminderRepeat.values) {
    if (repeat.name == name) return repeat;
  }
  return ReminderRepeat.once;
}

List<int> _parseWeekdays(String raw) {
  final days = <int>{
    for (final part in raw.split(','))
      if (int.tryParse(part.trim()) case final int day
          when day >= DateTime.monday && day <= DateTime.sunday)
        day,
  };
  return days.toList()..sort();
}

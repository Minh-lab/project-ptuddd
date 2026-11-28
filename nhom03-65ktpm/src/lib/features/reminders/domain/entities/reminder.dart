import 'package:equatable/equatable.dart';

/// Kiểu lặp của nhắc nhở.
enum ReminderRepeat {
  /// Báo một lần vào đúng ngày giờ đã chọn.
  once,

  /// Báo mỗi ngày vào cùng giờ.
  daily,

  /// Báo vào các thứ đã chọn trong tuần.
  weekly,
}

/// Nhắc nhở học tập gắn với một ghi chú (#10).
class Reminder extends Equatable {
  const Reminder({
    required this.id,
    required this.noteId,
    required this.repeat,
    required this.remindAt,
    required this.createdAt,
    required this.updatedAt,
    this.weekdays = const <int>[],
  });

  final String id;
  final String noteId;
  final ReminderRepeat repeat;

  /// Kiểu [ReminderRepeat.once]: ngày giờ báo. Các kiểu khác chỉ dùng giờ và
  /// phút của giá trị này.
  final DateTime remindAt;

  /// Kiểu [ReminderRepeat.weekly]: các thứ được báo, theo quy ước của
  /// [DateTime.weekday] (1 = thứ Hai … 7 = Chủ nhật), đã sắp xếp tăng dần.
  final List<int> weekdays;

  final DateTime createdAt;
  final DateTime updatedAt;

  int get hour => remindAt.hour;
  int get minute => remindAt.minute;

  Reminder copyWith({
    String? noteId,
    ReminderRepeat? repeat,
    DateTime? remindAt,
    List<int>? weekdays,
    DateTime? updatedAt,
  }) {
    return Reminder(
      id: id,
      noteId: noteId ?? this.noteId,
      repeat: repeat ?? this.repeat,
      remindAt: remindAt ?? this.remindAt,
      weekdays: weekdays ?? this.weekdays,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    id,
    noteId,
    repeat,
    remindAt,
    weekdays,
    createdAt,
    updatedAt,
  ];
}

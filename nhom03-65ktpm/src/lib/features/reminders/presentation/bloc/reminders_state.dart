import 'package:equatable/equatable.dart';

import '../../domain/entities/notification_permission.dart';
import '../../domain/entities/reminder.dart';
import '../../domain/entities/reminder_note.dart';

enum RemindersStatus { initial, loading, success, failure }

class RemindersState extends Equatable {
  const RemindersState({
    this.status = RemindersStatus.initial,
    this.reminders = const <Reminder>[],
    this.notes = const <ReminderNote>[],
    this.permission,
    this.errorMessage,
  });

  final RemindersStatus status;
  final List<Reminder> reminders;
  final List<ReminderNote> notes;

  /// `null` khi chưa kiểm tra xong.
  final NotificationPermission? permission;
  final String? errorMessage;

  bool get isLoading =>
      status == RemindersStatus.initial || status == RemindersStatus.loading;

  bool get permissionDenied => permission == NotificationPermission.denied;

  bool get notificationsUnsupported =>
      permission == NotificationPermission.unsupported;

  /// `null` nếu ghi chú đã bị xoá.
  ReminderNote? noteFor(String noteId) {
    for (final note in notes) {
      if (note.id == noteId) return note;
    }
    return null;
  }

  RemindersState copyWith({
    RemindersStatus? status,
    List<Reminder>? reminders,
    List<ReminderNote>? notes,
    NotificationPermission? permission,
    String? errorMessage,
  }) {
    return RemindersState(
      status: status ?? this.status,
      reminders: reminders ?? this.reminders,
      notes: notes ?? this.notes,
      permission: permission ?? this.permission,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    status,
    reminders,
    notes,
    permission,
    errorMessage,
  ];
}

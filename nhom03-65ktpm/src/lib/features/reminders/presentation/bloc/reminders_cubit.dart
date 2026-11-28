import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/error/failure.dart';
import '../../domain/entities/notification_permission.dart';
import '../../domain/entities/reminder.dart';
import '../../domain/entities/reminder_note.dart';
import '../../domain/repositories/reminder_note_source.dart';
import '../../domain/repositories/reminder_repository.dart';
import '../../domain/usecases/reminder_schedule.dart';
import 'reminders_state.dart';

/// Quản lý danh sách nhắc nhở và quyền thông báo (#10).
class RemindersCubit extends Cubit<RemindersState> {
  RemindersCubit(this._reminders, this._notes, {this.clock = DateTime.now})
    : super(const RemindersState());

  final ReminderRepository _reminders;
  final ReminderNoteSource _notes;

  /// Đồng hồ hiện tại; test truyền giờ cố định.
  final DateTime Function() clock;

  StreamSubscription<List<Reminder>>? _remindersSub;
  StreamSubscription<List<ReminderNote>>? _notesSub;

  DateTime get now => clock();

  Future<void> load() async {
    emit(state.copyWith(status: RemindersStatus.loading));
    await _remindersSub?.cancel();
    await _notesSub?.cancel();
    _remindersSub = _reminders.watchReminders().listen(
      (List<Reminder> reminders) => emit(
        state.copyWith(status: RemindersStatus.success, reminders: reminders),
      ),
      onError: _onStreamError,
    );
    _notesSub = _notes.watchNotes().listen(
      (List<ReminderNote> notes) => emit(state.copyWith(notes: notes)),
      onError: _onStreamError,
    );
    await refreshPermission();
  }

  void _onStreamError(Object error) {
    if (isClosed) return;
    emit(
      state.copyWith(
        status: RemindersStatus.failure,
        errorMessage: error is Failure
            ? error.message
            : 'Không tải được nhắc nhở.',
      ),
    );
  }

  /// Gọi khi mở màn hình và khi người dùng quay lại từ trang cài đặt.
  Future<void> refreshPermission() async {
    try {
      final permission = await _reminders.checkPermission();
      if (!isClosed) emit(state.copyWith(permission: permission));
    } on Failure catch (failure) {
      if (!isClosed) emit(state.copyWith(errorMessage: failure.message));
    }
  }

  /// Tạo nhắc nhở mới từ dữ liệu trên form (chưa lưu).
  Reminder draft({
    required String noteId,
    required ReminderRepeat repeat,
    required DateTime remindAt,
    List<int> weekdays = const <int>[],
    Reminder? editing,
  }) {
    final time = now;
    final sortedDays = weekdays.toSet().toList()..sort();
    if (editing != null) {
      return editing.copyWith(
        noteId: noteId,
        repeat: repeat,
        remindAt: remindAt,
        weekdays: sortedDays,
        updatedAt: time,
      );
    }
    return Reminder(
      id: const Uuid().v4(),
      noteId: noteId,
      repeat: repeat,
      remindAt: remindAt,
      weekdays: sortedDays,
      createdAt: time,
      updatedAt: time,
    );
  }

  /// Lưu nhắc nhở; trả thông báo lỗi để form hiện, `null` nếu thành công.
  ///
  /// Chưa có quyền thông báo thì hỏi quyền trước. Bị từ chối vẫn lưu nhắc
  /// nhở, màn hình sẽ hướng dẫn bật lại thông báo.
  Future<String?> save(Reminder reminder) async {
    final invalid = ReminderSchedule.validate(reminder, now);
    if (invalid != null) return invalid;
    try {
      if (state.permission != NotificationPermission.granted &&
          state.permission != NotificationPermission.unsupported) {
        final permission = await _reminders.requestPermission();
        if (!isClosed) emit(state.copyWith(permission: permission));
      }
      await _reminders.saveReminder(reminder);
      return null;
    } on Failure catch (failure) {
      return failure.message;
    }
  }

  Future<void> delete(String id) async {
    try {
      await _reminders.deleteReminder(id);
    } on Failure catch (failure) {
      if (!isClosed) emit(state.copyWith(errorMessage: failure.message));
    }
  }

  Future<void> openNotificationSettings() async {
    try {
      await _reminders.openNotificationSettings();
    } on Failure catch (failure) {
      if (!isClosed) emit(state.copyWith(errorMessage: failure.message));
    }
  }

  /// Lần báo kế tiếp để hiện trên danh sách.
  DateTime? nextOccurrence(Reminder reminder) =>
      ReminderSchedule.nextOccurrence(reminder, now);

  @override
  Future<void> close() async {
    await _remindersSub?.cancel();
    await _notesSub?.cancel();
    return super.close();
  }
}

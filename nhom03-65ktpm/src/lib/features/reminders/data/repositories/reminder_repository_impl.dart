import 'dart:developer' as developer;

import '../../../../core/database/app_database.dart';
import '../../../../core/database/reminders_dao.dart';
import '../../../../core/error/failure.dart';
import '../../domain/entities/notification_permission.dart';
import '../../domain/entities/reminder.dart';
import '../../domain/repositories/reminder_note_source.dart';
import '../../domain/repositories/reminder_repository.dart';
import '../../domain/usecases/reminder_schedule.dart';
import '../datasources/local/reminder_notifications_data_source.dart';
import '../models/reminder_mapper.dart';
import '../models/reminder_notification_ids.dart';

/// Hiện thực [ReminderRepository]: lưu trên Drift, lên lịch bằng thông báo
/// cục bộ của máy.
class ReminderRepositoryImpl implements ReminderRepository {
  ReminderRepositoryImpl({
    required this.dao,
    required this.notifications,
    required this.notes,
    this.clock = DateTime.now,
  });

  /// Lấy DAO tại thời điểm dùng, vì mỗi tài khoản có database riêng khi bật
  /// đồng bộ (xem `AppDependencies`).
  final RemindersDao Function() dao;
  final ReminderNotificationsDataSource notifications;
  final ReminderNoteSource notes;
  final DateTime Function() clock;

  static const String notificationTitle = 'Đến giờ ôn bài rồi';

  @override
  Stream<List<Reminder>> watchReminders() {
    return dao().watchAll().map(
      (List<ReminderRow> rows) =>
          rows.map((ReminderRow row) => row.toEntity()).toList(),
    );
  }

  @override
  Future<void> saveReminder(Reminder reminder) async {
    try {
      await dao().upsertReminder(reminder.toCompanion());
    } on Object catch (error) {
      throw DatabaseFailure('Không lưu được nhắc nhở: $error');
    }
    try {
      await _cancel(reminder.id);
      await _schedule(reminder, await _noteTitles());
    } on Object catch (error) {
      throw DatabaseFailure(
        'Đã lưu nhắc nhở nhưng chưa đặt được thông báo: $error',
      );
    }
  }

  @override
  Future<void> deleteReminder(String id) async {
    final bool deleted;
    try {
      deleted = await dao().deleteReminder(id);
    } on Object catch (error) {
      throw DatabaseFailure('Không xoá được nhắc nhở: $error');
    }
    if (!deleted) throw const DatabaseFailure('Không tìm thấy nhắc nhở');
    try {
      await _cancel(id);
    } on Object catch (error) {
      throw DatabaseFailure(
        'Đã xoá nhắc nhở nhưng chưa huỷ được thông báo: $error',
      );
    }
  }

  @override
  Future<void> rescheduleAll() async {
    try {
      // Máy không có thông báo (web, máy tính, test) thì không cần đọc dữ liệu.
      if (!notifications.isSupported) return;
      await notifications.cancelAllPending();
      final titles = await _noteTitles();
      for (final row in await dao().getAll()) {
        await _schedule(row.toEntity(), titles);
      }
    } on Object catch (error, stackTrace) {
      // Không chặn việc mở app; lần lưu nhắc nhở sau sẽ lên lịch lại.
      developer.log(
        'Không lên lịch lại được nhắc nhở',
        name: 'reminders',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<NotificationPermission> checkPermission() =>
      _guard(notifications.checkPermission);

  @override
  Future<NotificationPermission> requestPermission() =>
      _guard(notifications.requestPermission);

  @override
  Future<void> openNotificationSettings() async {
    try {
      await notifications.openSettings();
    } on Object catch (error) {
      throw DatabaseFailure('Không mở được cài đặt thông báo: $error');
    }
  }

  Future<NotificationPermission> _guard(
    Future<NotificationPermission> Function() action,
  ) async {
    try {
      return await action();
    } on Object catch (error) {
      throw DatabaseFailure('Không kiểm tra được quyền thông báo: $error');
    }
  }

  Future<Map<String, String>> _noteTitles() async {
    return <String, String>{
      for (final note in await notes.getNotes()) note.id: note.displayTitle,
    };
  }

  /// Ghi chú đã bị xoá thì không báo nữa.
  Future<void> _schedule(Reminder reminder, Map<String, String> titles) async {
    final title = titles[reminder.noteId];
    if (title == null) return;
    for (final trigger in ReminderSchedule.triggersFor(reminder, clock())) {
      await notifications.schedule(
        id: reminderNotificationId(reminder.id, trigger.slot),
        at: trigger.firstAt,
        match: trigger.match,
        title: notificationTitle,
        body: 'Ôn lại: $title',
        payload: reminder.noteId,
      );
    }
  }

  Future<void> _cancel(String reminderId) async {
    for (final id in allReminderNotificationIds(reminderId)) {
      await notifications.cancel(id);
    }
  }
}

import 'dart:async';

import 'package:smart_note/core/error/failure.dart';
import 'package:smart_note/features/reminders/data/datasources/local/reminder_notifications_data_source.dart';
import 'package:smart_note/features/reminders/domain/entities/notification_permission.dart';
import 'package:smart_note/features/reminders/domain/entities/reminder.dart';
import 'package:smart_note/features/reminders/domain/entities/reminder_note.dart';
import 'package:smart_note/features/reminders/domain/repositories/reminder_note_source.dart';
import 'package:smart_note/features/reminders/domain/repositories/reminder_repository.dart';
import 'package:smart_note/features/reminders/domain/usecases/reminder_schedule.dart';

/// Một thông báo đã được lên lịch trên [FakeReminderNotifications].
class ScheduledNotification {
  const ScheduledNotification({
    required this.id,
    required this.at,
    required this.match,
    required this.title,
    required this.body,
    required this.payload,
  });

  final int id;
  final DateTime at;
  final ReminderMatch match;
  final String title;
  final String body;
  final String payload;
}

/// Thông báo giả: ghi lại các lần lên lịch/huỷ, không gọi hệ điều hành.
class FakeReminderNotifications implements ReminderNotificationsDataSource {
  FakeReminderNotifications({
    this.isSupported = true,
    this.permission = NotificationPermission.granted,
  });

  @override
  final bool isSupported;
  NotificationPermission permission;
  final Map<int, ScheduledNotification> scheduled =
      <int, ScheduledNotification>{};
  int cancelAllCount = 0;
  final StreamController<String> taps = StreamController<String>.broadcast();

  @override
  Future<NotificationPermission> checkPermission() async => permission;

  @override
  Future<NotificationPermission> requestPermission() async => permission;

  @override
  Future<void> openSettings() async {}

  @override
  Future<void> schedule({
    required int id,
    required DateTime at,
    required ReminderMatch match,
    required String title,
    required String body,
    required String payload,
  }) async {
    scheduled[id] = ScheduledNotification(
      id: id,
      at: at,
      match: match,
      title: title,
      body: body,
      payload: payload,
    );
  }

  @override
  Future<void> cancel(int id) async => scheduled.remove(id);

  @override
  Future<void> cancelAllPending() async {
    cancelAllCount++;
    scheduled.clear();
  }

  @override
  Stream<String> get openedNoteIds => taps.stream;

  @override
  Future<void> dispose() => taps.close();
}

/// Nguồn ghi chú giả cho feature nhắc nhở.
class FakeReminderNoteSource implements ReminderNoteSource {
  FakeReminderNoteSource(this.notes);

  List<ReminderNote> notes;

  @override
  Stream<List<ReminderNote>> watchNotes() async* {
    yield notes;
  }

  @override
  Future<List<ReminderNote>> getNotes() async => notes;
}

/// Repository nhắc nhở giả lưu trong bộ nhớ, dùng cho widget test.
class FakeReminderRepository implements ReminderRepository {
  FakeReminderRepository({
    List<Reminder> reminders = const <Reminder>[],
    this.permission = NotificationPermission.granted,
    this.permissionAfterRequest = NotificationPermission.granted,
  }) : _reminders = List<Reminder>.of(reminders);

  final List<Reminder> _reminders;
  final StreamController<List<Reminder>> _controller =
      StreamController<List<Reminder>>.broadcast();

  NotificationPermission permission;
  NotificationPermission permissionAfterRequest;
  int requestCount = 0;
  int openSettingsCount = 0;

  List<Reminder> get reminders => List<Reminder>.unmodifiable(_reminders);

  @override
  Stream<List<Reminder>> watchReminders() async* {
    yield reminders;
    yield* _controller.stream;
  }

  @override
  Future<void> saveReminder(Reminder reminder) async {
    final index = _reminders.indexWhere((Reminder r) => r.id == reminder.id);
    if (index < 0) {
      _reminders.add(reminder);
    } else {
      _reminders[index] = reminder;
    }
    _controller.add(reminders);
  }

  @override
  Future<void> deleteReminder(String id) async {
    final before = _reminders.length;
    _reminders.removeWhere((Reminder r) => r.id == id);
    if (_reminders.length == before) {
      throw const DatabaseFailure('Không tìm thấy nhắc nhở');
    }
    _controller.add(reminders);
  }

  @override
  Future<void> rescheduleAll() async {}

  @override
  Future<NotificationPermission> checkPermission() async => permission;

  @override
  Future<NotificationPermission> requestPermission() async {
    requestCount++;
    return permission = permissionAfterRequest;
  }

  @override
  Future<void> openNotificationSettings() async => openSettingsCount++;

  Future<void> dispose() => _controller.close();
}

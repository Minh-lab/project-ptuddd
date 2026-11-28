import '../../../domain/entities/notification_permission.dart';
import '../../../domain/usecases/reminder_schedule.dart';

/// Thông báo cục bộ của hệ điều hành cho nhắc nhở (#10).
abstract interface class ReminderNotificationsDataSource {
  /// `false` ở web, máy tính và khi chạy test: mọi hàm khác không làm gì.
  bool get isSupported;

  Future<NotificationPermission> checkPermission();

  Future<NotificationPermission> requestPermission();

  Future<void> openSettings();

  /// Lên lịch một thông báo; [payload] là id ghi chú cần mở khi bấm vào.
  Future<void> schedule({
    required int id,
    required DateTime at,
    required ReminderMatch match,
    required String title,
    required String body,
    required String payload,
  });

  Future<void> cancel(int id);

  /// Huỷ mọi thông báo đang chờ (không xoá thông báo đã hiện).
  Future<void> cancelAllPending();

  /// Id ghi chú mỗi khi người dùng bấm vào thông báo, kể cả lần bấm làm app
  /// khởi động từ trạng thái đã đóng.
  Stream<String> get openedNoteIds;

  Future<void> dispose();
}

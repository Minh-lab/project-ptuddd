import '../entities/notification_permission.dart';
import '../entities/reminder.dart';

/// Lưu nhắc nhở và lên lịch thông báo tương ứng.
abstract interface class ReminderRepository {
  Stream<List<Reminder>> watchReminders();

  /// Thêm mới hoặc cập nhật nhắc nhở, rồi lên lịch lại thông báo của nó.
  Future<void> saveReminder(Reminder reminder);

  /// Xoá nhắc nhở và huỷ thông báo đã lên lịch.
  Future<void> deleteReminder(String id);

  /// Huỷ mọi thông báo đang chờ rồi lên lịch lại theo dữ liệu hiện có
  /// (gọi khi mở app hoặc đổi tài khoản). Không ném lỗi.
  Future<void> rescheduleAll();

  Future<NotificationPermission> checkPermission();

  /// Hỏi quyền hiện thông báo (hộp thoại của hệ điều hành).
  Future<NotificationPermission> requestPermission();

  /// Mở trang cài đặt thông báo của ứng dụng trong hệ điều hành.
  Future<void> openNotificationSettings();
}

/// Trạng thái quyền hiện thông báo của ứng dụng.
enum NotificationPermission {
  /// Đã được phép, thông báo nhắc nhở sẽ hiện đúng giờ.
  granted,

  /// Người dùng đã tắt hoặc từ chối thông báo.
  denied,

  /// Thiết bị không hỗ trợ thông báo cục bộ (web, máy tính, môi trường test).
  unsupported,
}

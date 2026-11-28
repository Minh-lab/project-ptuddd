/// Số slot thông báo tối đa của một nhắc nhở: slot 0 (một lần, hằng ngày) và
/// slot 1…7 (mỗi thứ trong tuần).
const int kReminderSlots = 8;

/// Id số nguyên cho thông báo, suy ra ổn định từ id (UUID) của nhắc nhở.
///
/// Dùng băm FNV-1a thay cho `String.hashCode` vì giá trị `hashCode` không được
/// đảm bảo giống nhau giữa các lần chạy app, mà thông báo đã lên lịch cần huỷ
/// được ở lần mở app sau. Kết quả luôn nhỏ hơn 2^31 như Android yêu cầu.
int reminderNotificationId(String reminderId, int slot) {
  assert(slot >= 0 && slot < kReminderSlots, 'slot phải trong 0…7');
  var hash = 0x811c9dc5;
  for (final unit in reminderId.codeUnits) {
    hash ^= unit;
    hash = (hash * 0x01000193) & 0xffffffff;
  }
  return (hash % 100000000) * 10 + slot;
}

/// Mọi id thông báo có thể có của một nhắc nhở — dùng khi huỷ.
List<int> allReminderNotificationIds(String reminderId) => <int>[
  for (var slot = 0; slot < kReminderSlots; slot++)
    reminderNotificationId(reminderId, slot),
];

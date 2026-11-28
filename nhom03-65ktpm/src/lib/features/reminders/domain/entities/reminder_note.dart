import 'package:equatable/equatable.dart';

/// Ghi chú nhìn từ góc độ nhắc nhở: chỉ cần id và tiêu đề để chọn ghi chú,
/// hiện trên thông báo và mở lại khi người dùng bấm vào thông báo.
///
/// Feature này không import entity `Note` của feature notes (quy định không
/// import chéo giữa các feature); dữ liệu vẫn đọc từ cùng bảng `notes`.
class ReminderNote extends Equatable {
  const ReminderNote({required this.id, required this.title});

  final String id;
  final String title;

  String get displayTitle =>
      title.trim().isEmpty ? '(Chưa có tiêu đề)' : title.trim();

  @override
  List<Object?> get props => <Object?>[id, title];
}

import 'package:equatable/equatable.dart';

/// Ghi chú nhìn từ góc độ thống kê: chỉ cần thời điểm tạo và loại.
///
/// Feature này không import entity `Note` của feature notes (quy định không
/// import chéo giữa các feature); dữ liệu vẫn đọc từ cùng bảng `notes`.
class StudyNote extends Equatable {
  const StudyNote({
    required this.id,
    required this.createdAt,
    this.isDiary = false,
  });

  final String id;
  final DateTime createdAt;
  final bool isDiary;

  @override
  List<Object?> get props => <Object?>[id, createdAt, isDiary];
}

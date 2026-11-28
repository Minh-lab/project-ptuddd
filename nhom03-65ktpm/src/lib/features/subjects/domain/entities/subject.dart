import 'package:equatable/equatable.dart';

/// Môn học dùng để phân loại ghi chú — Dart thuần.
class Subject extends Equatable {
  const Subject({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    this.color,
  });

  final String id;
  final String name;

  /// Màu hiển thị dạng `#RRGGBB`; `null` thì dùng màu mặc định.
  final String? color;
  final DateTime createdAt;
  final DateTime updatedAt;

  Subject copyWith({String? name, String? color, DateTime? updatedAt}) {
    return Subject(
      id: id,
      name: name ?? this.name,
      color: color ?? this.color,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => <Object?>[id, name, color, createdAt, updatedAt];
}

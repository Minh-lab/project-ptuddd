import 'dart:typed_data';

/// Thực thể ảnh quét vở (chụp từ camera hoặc chọn từ thư viện).
class ScannedImage {
  const ScannedImage({
    required this.id,
    required this.originalPath,
    required this.originalBytes,
    this.croppedBytes,
    this.croppedPath,
    this.createdAt,
  });

  /// Mã định danh duy nhất của lượt quét/ảnh.
  final String id;

  /// Đường dẫn tệp ảnh gốc.
  final String originalPath;

  /// Dữ liệu byte của ảnh gốc.
  final Uint8List originalBytes;

  /// Dữ liệu byte của ảnh sau khi cắt (nếu đã cắt).
  final Uint8List? croppedBytes;

  /// Đường dẫn tệp ảnh sau khi cắt (nếu đã lưu file).
  final String? croppedPath;

  /// Thời điểm tạo/chụp ảnh.
  final DateTime? createdAt;

  /// Trả về dữ liệu ảnh hiện hành (ưu tiên ảnh đã cắt).
  Uint8List get activeBytes => croppedBytes ?? originalBytes;

  /// Trả về đường dẫn ảnh hiện hành (ưu tiên ảnh đã cắt).
  String get activePath => croppedPath ?? originalPath;

  /// Cho biết ảnh này đã qua thao tác cắt hay chưa.
  bool get isCropped => croppedBytes != null;

  ScannedImage copyWith({
    String? id,
    String? originalPath,
    Uint8List? originalBytes,
    Uint8List? croppedBytes,
    String? croppedPath,
    DateTime? createdAt,
  }) {
    return ScannedImage(
      id: id ?? this.id,
      originalPath: originalPath ?? this.originalPath,
      originalBytes: originalBytes ?? this.originalBytes,
      croppedBytes: croppedBytes ?? this.croppedBytes,
      croppedPath: croppedPath ?? this.croppedPath,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

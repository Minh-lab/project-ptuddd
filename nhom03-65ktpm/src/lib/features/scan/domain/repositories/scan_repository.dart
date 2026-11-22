import 'dart:typed_data';

import '../entities/scanned_image.dart';

/// Hợp đồng Repository cho nghiệp vụ quét, chọn và cắt ảnh trang vở.
abstract interface class ScanRepository {
  /// Chụp ảnh mới từ camera của thiết bị.
  Future<ScannedImage?> captureFromCamera();

  /// Chọn một ảnh từ thư viện/bộ sưu tập ảnh của thiết bị.
  Future<ScannedImage?> pickFromGallery();

  /// Lưu trữ dữ liệu ảnh đã cắt và cập nhật vào [ScannedImage].
  Future<ScannedImage> saveCroppedImage({
    required ScannedImage image,
    required Uint8List croppedBytes,
  });
}

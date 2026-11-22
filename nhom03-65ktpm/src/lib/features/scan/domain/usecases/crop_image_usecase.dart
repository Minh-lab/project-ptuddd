import 'dart:typed_data';

import '../entities/scanned_image.dart';
import '../repositories/scan_repository.dart';

/// Ca sử dụng: Cắt và lưu trữ ảnh sau khi người dùng căn chỉnh.
class CropImageUseCase {
  const CropImageUseCase(this._repository);

  final ScanRepository _repository;

  Future<ScannedImage> call({
    required ScannedImage image,
    required Uint8List croppedBytes,
  }) {
    return _repository.saveCroppedImage(
      image: image,
      croppedBytes: croppedBytes,
    );
  }
}

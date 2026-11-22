import '../entities/scanned_image.dart';
import '../repositories/scan_repository.dart';

/// Ca sử dụng: Chọn ảnh trang vở từ thư viện ảnh thiết bị.
class PickImageUseCase {
  const PickImageUseCase(this._repository);

  final ScanRepository _repository;

  Future<ScannedImage?> call() => _repository.pickFromGallery();
}

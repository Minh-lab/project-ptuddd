import '../entities/scanned_image.dart';
import '../repositories/scan_repository.dart';

/// Ca sử dụng: Chụp ảnh trang vở bằng Camera.
class CaptureImageUseCase {
  const CaptureImageUseCase(this._repository);

  final ScanRepository _repository;

  Future<ScannedImage?> call() => _repository.captureFromCamera();
}

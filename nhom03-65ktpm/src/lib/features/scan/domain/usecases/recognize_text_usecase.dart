import '../entities/ocr_result.dart';
import '../repositories/ocr_repository.dart';

/// Use case nhận dạng chữ từ ảnh trang vở đã quét/cắt.
class RecognizeTextUseCase {
  const RecognizeTextUseCase(this._repository);

  final OcrRepository _repository;

  Future<OcrResult> call({required String imagePath, String? imageId}) {
    return _repository.recognizeText(imagePath: imagePath, imageId: imageId);
  }
}

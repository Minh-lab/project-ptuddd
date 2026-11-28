import '../entities/ocr_result.dart';

/// Hợp đồng nhận dạng chữ (OCR) từ ảnh trang vở.
abstract interface class OcrRepository {
  /// Nhận dạng văn bản từ tệp ảnh tại [imagePath].
  ///
  /// Ném [ScanFailure] nếu tệp không tồn tại hoặc xử lý thất bại.
  Future<OcrResult> recognizeText({required String imagePath, String? imageId});
}

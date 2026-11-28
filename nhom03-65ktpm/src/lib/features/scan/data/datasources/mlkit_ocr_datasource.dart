import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../../domain/entities/ocr_result.dart';

/// Dữ liệu thô trả về từ bộ nhận dạng ML Kit trước khi đóng gói thành [OcrResult].
class OcrRecognitionPayload {
  const OcrRecognitionPayload({required this.fullText, required this.blocks});

  final String fullText;
  final List<OcrBlock> blocks;
}

/// Nguồn dữ liệu nhận dạng chữ (OCR) trên thiết bị.
abstract interface class MlKitOcrDataSource {
  /// Chạy OCR trên tệp ảnh tại [imagePath].
  Future<OcrRecognitionPayload> processImageFile(String imagePath);

  /// Giải phóng tài nguyên của bộ nhận dạng khi không dùng nữa.
  Future<void> dispose();
}

/// Hiện thực sử dụng `google_mlkit_text_recognition` (script Latin hỗ trợ tiếng Việt).
class MlKitOcrDataSourceImpl implements MlKitOcrDataSource {
  MlKitOcrDataSourceImpl({TextRecognizer? textRecognizer})
    : _textRecognizer =
          textRecognizer ?? TextRecognizer(script: TextRecognitionScript.latin);

  final TextRecognizer _textRecognizer;

  @override
  Future<OcrRecognitionPayload> processImageFile(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final recognized = await _textRecognizer.processImage(inputImage);

    final blocks = recognized.blocks
        .map(
          (TextBlock block) => OcrBlock(
            text: block.text,
            lines: block.lines.map((TextLine line) => line.text).toList(),
          ),
        )
        .toList();

    return OcrRecognitionPayload(
      fullText: recognized.text.trim(),
      blocks: blocks,
    );
  }

  @override
  Future<void> dispose() => _textRecognizer.close();
}

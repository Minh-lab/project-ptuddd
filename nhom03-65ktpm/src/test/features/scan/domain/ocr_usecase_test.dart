import 'package:flutter_test/flutter_test.dart';
import 'package:smart_note/features/scan/domain/entities/ocr_result.dart';
import 'package:smart_note/features/scan/domain/repositories/ocr_repository.dart';
import 'package:smart_note/features/scan/domain/usecases/recognize_text_usecase.dart';

class _FakeOcrRepository implements OcrRepository {
  OcrResult resultToReturn = const OcrResult(text: '');

  @override
  Future<OcrResult> recognizeText({
    required String imagePath,
    String? imageId,
  }) async {
    return resultToReturn.copyWith(imageId: imageId);
  }
}

void main() {
  group('RecognizeTextUseCase', () {
    test('trả về kết quả nhận dạng tiếng Việt từ repository', () async {
      final repo = _FakeOcrRepository()
        ..resultToReturn = const OcrResult(
          text: 'Bài 1: Giải tích hàm số',
          blocks: <OcrBlock>[OcrBlock(text: 'Bài 1: Giải tích hàm số')],
          durationMs: 420,
        );
      final useCase = RecognizeTextUseCase(repo);

      final result = await useCase(imagePath: '/tmp/page.jpg', imageId: 'img1');
      expect(result.text, equals('Bài 1: Giải tích hàm số'));
      expect(result.isEmptyText, isFalse);
      expect(result.imageId, equals('img1'));
    });

    test('đánh dấu isEmptyText = true khi không có chữ', () async {
      final repo = _FakeOcrRepository()
        ..resultToReturn = const OcrResult(text: '   \n  ');
      final useCase = RecognizeTextUseCase(repo);

      final result = await useCase(imagePath: '/tmp/blur.jpg');
      expect(result.isEmptyText, isTrue);
    });
  });
}

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_note/core/error/failure.dart';
import 'package:smart_note/features/scan/data/datasources/mlkit_ocr_datasource.dart';
import 'package:smart_note/features/scan/data/repositories/ocr_repository_impl.dart';
import 'package:smart_note/features/scan/domain/entities/ocr_result.dart';

class _FakeMlKitDataSource implements MlKitOcrDataSource {
  OcrRecognitionPayload payload = const OcrRecognitionPayload(
    fullText: '',
    blocks: <OcrBlock>[],
  );
  Exception? errorToThrow;

  @override
  Future<OcrRecognitionPayload> processImageFile(String imagePath) async {
    if (errorToThrow != null) {
      throw errorToThrow!;
    }
    return payload;
  }

  @override
  Future<void> dispose() async {}
}

void main() {
  late Directory tempDir;
  late File sampleFile;
  late _FakeMlKitDataSource dataSource;
  late OcrRepositoryImpl repository;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('smart_note_ocr_test_');
    sampleFile = File('${tempDir.path}/page.jpg');
    await sampleFile.writeAsBytes(<int>[1, 2, 3, 4]);
    dataSource = _FakeMlKitDataSource();
    repository = OcrRepositoryImpl(dataSource: dataSource);
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('OcrRepositoryImpl', () {
    test('nhận dạng thành công văn bản tiếng Việt và đo thời gian', () async {
      dataSource.payload = const OcrRecognitionPayload(
        fullText: 'Chương 1: Phương trình vi phân',
        blocks: <OcrBlock>[OcrBlock(text: 'Chương 1: Phương trình vi phân')],
      );

      final result = await repository.recognizeText(
        imagePath: sampleFile.path,
        imageId: 'scan-1',
      );

      expect(result.text, equals('Chương 1: Phương trình vi phân'));
      expect(result.isEmptyText, isFalse);
      expect(result.imageId, equals('scan-1'));
      expect(result.durationMs, greaterThanOrEqualTo(0));
    });

    test('trả về OcrResult rỗng khi ảnh mờ / không có chữ', () async {
      dataSource.payload = const OcrRecognitionPayload(
        fullText: '',
        blocks: <OcrBlock>[],
      );

      final result = await repository.recognizeText(imagePath: sampleFile.path);
      expect(result.isEmptyText, isTrue);
    });

    test('ném ScanFailure khi tệp ảnh không tồn tại', () async {
      expect(
        () =>
            repository.recognizeText(imagePath: '${tempDir.path}/missing.jpg'),
        throwsA(isA<ScanFailure>()),
      );
    });

    test('chuyển PlatformException thành ScanFailure', () async {
      dataSource.errorToThrow = PlatformException(
        code: 'ocr_failed',
        message: 'Model unavailable',
      );

      expect(
        () => repository.recognizeText(imagePath: sampleFile.path),
        throwsA(isA<ScanFailure>()),
      );
    });
  });
}

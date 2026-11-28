import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_note/core/error/failure.dart';
import 'package:smart_note/features/scan/domain/entities/ocr_result.dart';
import 'package:smart_note/features/scan/domain/entities/scanned_image.dart';
import 'package:smart_note/features/scan/domain/repositories/ocr_note_saver.dart';
import 'package:smart_note/features/scan/domain/repositories/ocr_repository.dart';
import 'package:smart_note/features/scan/domain/usecases/recognize_text_usecase.dart';
import 'package:smart_note/features/scan/presentation/bloc/ocr_cubit.dart';
import 'package:smart_note/features/scan/presentation/bloc/ocr_state.dart';

class _MockOcrRepository implements OcrRepository {
  OcrResult result = const OcrResult(text: '');
  Exception? error;

  @override
  Future<OcrResult> recognizeText({
    required String imagePath,
    String? imageId,
  }) async {
    if (error != null) throw error!;
    return result;
  }
}

class _SpyOcrNoteSaver implements OcrNoteSaver {
  String? savedTitle;
  String? savedContent;
  String? savedOriginalPath;

  @override
  Future<String> saveAsNote({
    required String title,
    required String content,
    required String originalImagePath,
    String? croppedImagePath,
    String? ocrRawText,
  }) async {
    savedTitle = title;
    savedContent = content;
    savedOriginalPath = originalImagePath;
    return 'note-ocr-1';
  }
}

void main() {
  late _MockOcrRepository repository;
  late _SpyOcrNoteSaver noteSaver;
  late OcrCubit cubit;
  final sampleImage = ScannedImage(
    id: 'img-1',
    originalPath: '/scans/img-1/original.jpg',
    originalBytes: Uint8List.fromList(<int>[1, 2, 3]),
    croppedPath: '/scans/img-1/cropped.png',
    croppedBytes: Uint8List.fromList(<int>[4, 5, 6]),
  );

  setUp(() {
    repository = _MockOcrRepository();
    noteSaver = _SpyOcrNoteSaver();
    cubit = OcrCubit(
      recognizeTextUseCase: RecognizeTextUseCase(repository),
      noteSaver: noteSaver,
    );
  });

  tearDown(() => cubit.close());

  group('OcrCubit', () {
    test('recognizeImage thành công chuyển sang success', () async {
      repository.result = const OcrResult(
        text: 'Ôn tập Giải tích 1',
        durationMs: 350,
      );

      expectLater(
        cubit.stream,
        emitsInOrder(<dynamic>[
          const OcrState(status: OcrStatus.loading),
          predicate<OcrState>(
            (s) =>
                s.status == OcrStatus.success &&
                s.editedText == 'Ôn tập Giải tích 1',
          ),
        ]),
      );

      await cubit.recognizeImage(sampleImage);
    });

    test('recognizeImage ảnh mờ không có chữ chuyển sang empty', () async {
      repository.result = const OcrResult(text: '');

      expectLater(
        cubit.stream,
        emitsInOrder(<dynamic>[
          const OcrState(status: OcrStatus.loading),
          predicate<OcrState>(
            (s) => s.status == OcrStatus.empty && s.editedText.isEmpty,
          ),
        ]),
      );

      await cubit.recognizeImage(sampleImage);
    });

    test('recognizeImage lỗi chuyển sang failure', () async {
      repository.error = const ScanFailure('Không đọc được tệp ảnh');

      expectLater(
        cubit.stream,
        emitsInOrder(<dynamic>[
          const OcrState(status: OcrStatus.loading),
          predicate<OcrState>(
            (s) =>
                s.status == OcrStatus.failure &&
                s.errorMessage == 'Không đọc được tệp ảnh',
          ),
        ]),
      );

      await cubit.recognizeImage(sampleImage);
    });

    test('updateText và saveAsNote lưu ghi chú kèm ảnh gốc', () async {
      repository.result = const OcrResult(text: 'Nội dung cũ');
      await cubit.recognizeImage(sampleImage);

      cubit.updateText('Nội dung đã sửa chính tả');
      await cubit.saveAsNote(title: 'Toán cao cấp', image: sampleImage);

      expect(cubit.state.status, equals(OcrStatus.saved));
      expect(cubit.state.savedNoteId, equals('note-ocr-1'));
      expect(noteSaver.savedTitle, equals('Toán cao cấp'));
      expect(noteSaver.savedContent, equals('Nội dung đã sửa chính tả'));
      expect(noteSaver.savedOriginalPath, equals('/scans/img-1/original.jpg'));
    });
  });
}

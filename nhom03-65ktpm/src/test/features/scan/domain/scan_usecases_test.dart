import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_note/features/scan/domain/entities/scanned_image.dart';
import 'package:smart_note/features/scan/domain/repositories/scan_repository.dart';
import 'package:smart_note/features/scan/domain/usecases/capture_image_usecase.dart';
import 'package:smart_note/features/scan/domain/usecases/crop_image_usecase.dart';
import 'package:smart_note/features/scan/domain/usecases/pick_image_usecase.dart';

class FakeScanRepository implements ScanRepository {
  ScannedImage? imageToReturn;
  ScannedImage? capturedImageToReturn;

  @override
  Future<ScannedImage?> captureFromCamera() async => capturedImageToReturn;

  @override
  Future<ScannedImage?> pickFromGallery() async => imageToReturn;

  @override
  Future<ScannedImage> saveCroppedImage({
    required ScannedImage image,
    required Uint8List croppedBytes,
  }) async {
    return image.copyWith(
      croppedBytes: croppedBytes,
      croppedPath: '/tmp/cropped_${image.id}.jpg',
    );
  }
}

void main() {
  late FakeScanRepository repository;
  late final testImage = ScannedImage(
    id: 'test-1',
    originalPath: '/test/path.jpg',
    originalBytes: Uint8List.fromList(<int>[1, 2, 3]),
    createdAt: DateTime(2026, 11, 22),
  );

  setUp(() {
    repository = FakeScanRepository();
  });

  group('Scan UseCases', () {
    test('CaptureImageUseCase gọi đúng repository', () async {
      repository.capturedImageToReturn = testImage;
      final useCase = CaptureImageUseCase(repository);

      final result = await useCase();
      expect(result, equals(testImage));
      expect(result?.activePath, equals('/test/path.jpg'));
    });

    test('PickImageUseCase gọi đúng repository', () async {
      repository.imageToReturn = testImage;
      final useCase = PickImageUseCase(repository);

      final result = await useCase();
      expect(result, equals(testImage));
      expect(result?.isCropped, isFalse);
    });

    test('CropImageUseCase cập nhật croppedBytes và croppedPath', () async {
      final useCase = CropImageUseCase(repository);
      final croppedBytes = Uint8List.fromList(<int>[4, 5, 6]);

      final result = await useCase(
        image: testImage,
        croppedBytes: croppedBytes,
      );

      expect(result.isCropped, isTrue);
      expect(result.croppedBytes, equals(croppedBytes));
      expect(result.activeBytes, equals(croppedBytes));
      expect(result.activePath, equals('/tmp/cropped_test-1.jpg'));
    });
  });
}

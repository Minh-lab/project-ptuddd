import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_note/features/scan/domain/entities/scanned_image.dart';
import 'package:smart_note/features/scan/domain/repositories/scan_repository.dart';
import 'package:smart_note/features/scan/domain/usecases/capture_image_usecase.dart';
import 'package:smart_note/features/scan/domain/usecases/crop_image_usecase.dart';
import 'package:smart_note/features/scan/domain/usecases/pick_image_usecase.dart';
import 'package:smart_note/features/scan/presentation/bloc/scan_cubit.dart';
import 'package:smart_note/features/scan/presentation/bloc/scan_state.dart';

class MockScanRepository implements ScanRepository {
  ScannedImage? imageResult;
  Exception? errorToThrow;

  @override
  Future<ScannedImage?> captureFromCamera() async {
    if (errorToThrow != null) throw errorToThrow!;
    return imageResult;
  }

  @override
  Future<ScannedImage?> pickFromGallery() async {
    if (errorToThrow != null) throw errorToThrow!;
    return imageResult;
  }

  @override
  Future<ScannedImage> saveCroppedImage({
    required ScannedImage image,
    required Uint8List croppedBytes,
  }) async {
    if (errorToThrow != null) throw errorToThrow!;
    return image.copyWith(croppedBytes: croppedBytes);
  }
}

void main() {
  late MockScanRepository repository;
  late ScanCubit cubit;
  final sampleImage = ScannedImage(
    id: 'img-101',
    originalPath: '/path/test.png',
    originalBytes: Uint8List.fromList(<int>[10, 20, 30]),
  );

  setUp(() {
    repository = MockScanRepository();
    cubit = ScanCubit(
      captureImageUseCase: CaptureImageUseCase(repository),
      pickImageUseCase: PickImageUseCase(repository),
      cropImageUseCase: CropImageUseCase(repository),
    );
  });

  tearDown(() => cubit.close());

  group('ScanCubit', () {
    test('trạng thái ban đầu là initial và không có ảnh', () {
      expect(cubit.state.status, equals(ScanStatus.initial));
      expect(cubit.state.hasImage, isFalse);
    });

    test('captureImage thành công chuyển trạng thái sang imageReady', () async {
      repository.imageResult = sampleImage;

      expectLater(
        cubit.stream,
        emitsInOrder(<dynamic>[
          const ScanState(status: ScanStatus.loading),
          ScanState(status: ScanStatus.imageReady, image: sampleImage),
        ]),
      );

      await cubit.captureImage();
    });

    test('captureImage hủy bỏ thì trở về initial nếu chưa có ảnh', () async {
      repository.imageResult = null;

      expectLater(
        cubit.stream,
        emitsInOrder(<dynamic>[
          const ScanState(status: ScanStatus.loading),
          const ScanState(status: ScanStatus.initial),
        ]),
      );

      await cubit.captureImage();
    });

    test('pickImage thành công chuyển trạng thái sang imageReady', () async {
      repository.imageResult = sampleImage;

      expectLater(
        cubit.stream,
        emitsInOrder(<dynamic>[
          const ScanState(status: ScanStatus.loading),
          ScanState(status: ScanStatus.imageReady, image: sampleImage),
        ]),
      );

      await cubit.pickImage();
    });

    test('pickImage lỗi thì chuyển sang failure', () async {
      repository.errorToThrow = Exception('Mất quyền truy cập');

      expectLater(
        cubit.stream,
        emitsInOrder(<dynamic>[
          const ScanState(status: ScanStatus.loading),
          predicate<ScanState>(
            (s) =>
                s.status == ScanStatus.failure &&
                s.errorMessage!.contains('Mất quyền truy cập'),
          ),
        ]),
      );

      await cubit.pickImage();
    });

    test(
      'applyCrop cắt ảnh thành công chuyển trạng thái sang success',
      () async {
        repository.imageResult = sampleImage;
        await cubit.pickImage();

        final croppedBytes = Uint8List.fromList(<int>[99, 88]);

        expectLater(
          cubit.stream,
          emitsInOrder(<dynamic>[
            predicate<ScanState>((s) => s.status == ScanStatus.cropping),
            predicate<ScanState>(
              (s) =>
                  s.status == ScanStatus.success &&
                  s.image?.croppedBytes == croppedBytes,
            ),
          ]),
        );

        await cubit.applyCrop(croppedBytes);
      },
    );

    test('clearImage xóa ảnh và trả về initial', () async {
      repository.imageResult = sampleImage;
      await cubit.pickImage();
      expect(cubit.state.hasImage, isTrue);

      cubit.clearImage();
      expect(cubit.state.status, equals(ScanStatus.initial));
      expect(cubit.state.image, isNull);
    });
  });
}

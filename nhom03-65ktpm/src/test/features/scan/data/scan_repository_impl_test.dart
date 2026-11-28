import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:smart_note/core/error/failure.dart';
import 'package:smart_note/features/scan/data/datasources/image_picker_datasource.dart';
import 'package:smart_note/features/scan/data/repositories/scan_repository_impl.dart';

class _FakeImagePickerDataSource implements ImagePickerDataSource {
  XFile? fileToReturn;
  PlatformException? exceptionToThrow;

  @override
  Future<XFile?> pickImage(ImageSource source) async {
    if (exceptionToThrow != null) {
      throw exceptionToThrow!;
    }
    return fileToReturn;
  }
}

void main() {
  late Directory tempRoot;
  late _FakeImagePickerDataSource dataSource;
  late ScanRepositoryImpl repository;

  setUp(() async {
    tempRoot = await Directory.systemTemp.createTemp('smart_note_scan_test_');
    dataSource = _FakeImagePickerDataSource();
    repository = ScanRepositoryImpl(
      dataSource: dataSource,
      storageDirectoryProvider: () async => tempRoot,
    );
  });

  tearDown(() async {
    if (await tempRoot.exists()) {
      await tempRoot.delete(recursive: true);
    }
  });

  group('ScanRepositoryImpl', () {
    test('lưu cả ảnh gốc và ảnh đã cắt thành 2 tệp riêng biệt', () async {
      final sourceFile = File('${tempRoot.path}/source.jpg');
      final originalBytes = Uint8List.fromList(<int>[1, 2, 3, 4]);
      await sourceFile.writeAsBytes(originalBytes);
      dataSource.fileToReturn = XFile(sourceFile.path);

      final scanned = await repository.captureFromCamera();
      expect(scanned, isNotNull);
      expect(File(scanned!.originalPath).existsSync(), isTrue);
      expect(scanned.originalBytes, equals(originalBytes));

      final croppedBytes = Uint8List.fromList(<int>[9, 8, 7]);
      final updated = await repository.saveCroppedImage(
        image: scanned,
        croppedBytes: croppedBytes,
      );

      expect(updated.croppedPath, isNotNull);
      expect(updated.croppedPath, isNot(equals(updated.originalPath)));
      expect(File(updated.originalPath).existsSync(), isTrue);
      expect(File(updated.croppedPath!).existsSync(), isTrue);
      expect(updated.originalBytes, equals(originalBytes));
      expect(updated.croppedBytes, equals(croppedBytes));
    });

    test(
      'ném ScanFailure với isPermissionDenied khi bị từ chối quyền camera',
      () async {
        dataSource.exceptionToThrow = PlatformException(
          code: 'camera_access_denied',
          message: 'Camera access denied',
        );

        expect(
          () => repository.captureFromCamera(),
          throwsA(
            predicate<ScanFailure>(
              (f) => f.isPermissionDenied && f.message.contains('Camera'),
            ),
          ),
        );
      },
    );

    test(
      'ném ScanFailure với isPermissionDenied khi bị từ chối quyền thư viện',
      () async {
        dataSource.exceptionToThrow = PlatformException(
          code: 'photo_access_denied',
          message: 'Photo access denied',
        );

        expect(
          () => repository.pickFromGallery(),
          throwsA(
            predicate<ScanFailure>(
              (f) => f.isPermissionDenied && f.message.contains('Thư viện ảnh'),
            ),
          ),
        );
      },
    );

    test('trả về null khi người dùng hủy chọn ảnh', () async {
      dataSource.fileToReturn = null;
      final result = await repository.pickFromGallery();
      expect(result, isNull);
    });
  });
}

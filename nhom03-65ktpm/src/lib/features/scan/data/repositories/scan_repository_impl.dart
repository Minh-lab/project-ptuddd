import 'dart:io';
import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../../core/error/failure.dart';
import '../../domain/entities/scanned_image.dart';
import '../../domain/repositories/scan_repository.dart';
import '../datasources/image_picker_datasource.dart';

/// Hiện thực hóa [ScanRepository] với `ImagePickerDataSource` và lưu tệp tạm.
class ScanRepositoryImpl implements ScanRepository {
  ScanRepositoryImpl({ImagePickerDataSource? dataSource})
    : _dataSource = dataSource ?? ImagePickerDataSourceImpl();

  final ImagePickerDataSource _dataSource;

  @override
  Future<ScannedImage?> captureFromCamera() => _pick(ImageSource.camera);

  @override
  Future<ScannedImage?> pickFromGallery() => _pick(ImageSource.gallery);

  Future<ScannedImage?> _pick(ImageSource source) async {
    try {
      final file = await _dataSource.pickImage(source);
      if (file == null) {
        return null;
      }
      final bytes = await file.readAsBytes();
      final id = DateTime.now().millisecondsSinceEpoch.toString();
      return ScannedImage(
        id: id,
        originalPath: file.path,
        originalBytes: bytes,
        createdAt: DateTime.now(),
      );
    } on Exception catch (e) {
      throw ScanFailure('Không thể tải ảnh: ${e.toString()}');
    }
  }

  @override
  Future<ScannedImage> saveCroppedImage({
    required ScannedImage image,
    required Uint8List croppedBytes,
  }) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final croppedFileName =
          'crop_${image.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final croppedFilePath = p.join(tempDir.path, croppedFileName);
      final file = File(croppedFilePath);
      await file.writeAsBytes(croppedBytes);

      return image.copyWith(
        croppedBytes: croppedBytes,
        croppedPath: croppedFilePath,
      );
    } on Exception {
      // Nếu không ghi được tệp (ví dụ môi trường test hoặc web), vẫn giữ dữ liệu byte trong bộ nhớ
      return image.copyWith(croppedBytes: croppedBytes);
    }
  }
}

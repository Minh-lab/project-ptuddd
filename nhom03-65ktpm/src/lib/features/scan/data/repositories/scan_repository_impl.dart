import 'dart:io';

import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../../core/error/failure.dart';
import '../../domain/entities/scanned_image.dart';
import '../../domain/repositories/scan_repository.dart';
import '../datasources/image_picker_datasource.dart';

/// Hiện thực hóa [ScanRepository] với `ImagePickerDataSource` và lưu bền vững ảnh gốc + ảnh đã cắt.
class ScanRepositoryImpl implements ScanRepository {
  ScanRepositoryImpl({
    ImagePickerDataSource? dataSource,
    Future<Directory> Function()? storageDirectoryProvider,
  }) : _dataSource = dataSource ?? ImagePickerDataSourceImpl(),
       _storageDirectoryProvider =
           storageDirectoryProvider ?? getApplicationDocumentsDirectory;

  final ImagePickerDataSource _dataSource;
  final Future<Directory> Function() _storageDirectoryProvider;

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
      final originalPath = await _persistBytes(
        scanId: id,
        fileName: 'original${_resolveExtension(file.path)}',
        bytes: bytes,
        fallbackPath: file.path,
      );

      return ScannedImage(
        id: id,
        originalPath: originalPath,
        originalBytes: bytes,
        createdAt: DateTime.now(),
      );
    } on PlatformException catch (e) {
      throw _mapPlatformException(e, source);
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
      final croppedFileName =
          'cropped_${DateTime.now().millisecondsSinceEpoch}.png';
      final croppedPath = await _persistBytes(
        scanId: image.id,
        fileName: croppedFileName,
        bytes: croppedBytes,
        fallbackPath: '',
      );

      return image.copyWith(
        croppedBytes: croppedBytes,
        croppedPath: croppedPath.isEmpty ? null : croppedPath,
      );
    } on Exception {
      // Nếu không ghi được tệp (ví dụ môi trường test hoặc web), vẫn giữ dữ liệu byte trong bộ nhớ
      return image.copyWith(croppedBytes: croppedBytes);
    }
  }

  /// Lưu dữ liệu ảnh vào thư mục lưu trữ lâu dài của ứng dụng (`scans/<scanId>/`).
  Future<String> _persistBytes({
    required String scanId,
    required String fileName,
    required Uint8List bytes,
    required String fallbackPath,
  }) async {
    try {
      final rootDir = await _storageDirectoryProvider();
      final scanDir = Directory(p.join(rootDir.path, 'scans', scanId));
      if (!await scanDir.exists()) {
        await scanDir.create(recursive: true);
      }
      final targetPath = p.join(scanDir.path, fileName);
      await File(targetPath).writeAsBytes(bytes, flush: true);
      return targetPath;
    } on Exception {
      return fallbackPath;
    }
  }

  String _resolveExtension(String path) {
    final ext = p.extension(path);
    return ext.isEmpty ? '.jpg' : ext;
  }

  ScanFailure _mapPlatformException(PlatformException e, ImageSource source) {
    final code = e.code.toLowerCase();
    final isCameraDenied =
        code == 'camera_access_denied' ||
        (source == ImageSource.camera && code.contains('denied'));
    final isPhotoDenied =
        code == 'photo_access_denied' ||
        (source == ImageSource.gallery && code.contains('denied'));

    if (isCameraDenied) {
      return const ScanFailure(
        'Ứng dụng chưa có quyền truy cập Camera. Vui lòng cấp quyền Camera trong Cài đặt để chụp ảnh trang vở.',
        isPermissionDenied: true,
      );
    }
    if (isPhotoDenied) {
      return const ScanFailure(
        'Ứng dụng chưa có quyền truy cập Thư viện ảnh. Vui lòng cấp quyền Ảnh trong Cài đặt để chọn ảnh.',
        isPermissionDenied: true,
      );
    }
    return ScanFailure('Không thể tải ảnh (${e.code}): ${e.message ?? ''}');
  }
}

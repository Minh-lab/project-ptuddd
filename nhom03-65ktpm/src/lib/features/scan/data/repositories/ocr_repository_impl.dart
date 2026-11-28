import 'dart:io';

import 'package:flutter/services.dart';

import '../../../../core/error/failure.dart';
import '../../domain/entities/ocr_result.dart';
import '../../domain/repositories/ocr_repository.dart';
import '../datasources/mlkit_ocr_datasource.dart';

/// Hiện thực hóa [OcrRepository] bằng ML Kit on-device.
class OcrRepositoryImpl implements OcrRepository {
  OcrRepositoryImpl({MlKitOcrDataSource? dataSource})
    : _dataSource = dataSource ?? MlKitOcrDataSourceImpl();

  final MlKitOcrDataSource _dataSource;

  @override
  Future<OcrResult> recognizeText({
    required String imagePath,
    String? imageId,
  }) async {
    if (imagePath.trim().isEmpty || !File(imagePath).existsSync()) {
      throw const ScanFailure('Không tìm thấy tệp ảnh để nhận dạng chữ.');
    }

    final stopwatch = Stopwatch()..start();
    try {
      final payload = await _dataSource.processImageFile(imagePath);
      stopwatch.stop();

      return OcrResult(
        text: payload.fullText,
        blocks: payload.blocks,
        durationMs: stopwatch.elapsedMilliseconds,
        imageId: imageId,
        createdAt: DateTime.now(),
      );
    } on PlatformException catch (e) {
      stopwatch.stop();
      throw ScanFailure(
        'Lỗi nhận dạng văn bản (${e.code}): ${e.message ?? 'Không xác định'}',
      );
    } on Exception catch (e) {
      stopwatch.stop();
      throw ScanFailure('Không thể nhận dạng chữ từ ảnh: ${e.toString()}');
    }
  }
}

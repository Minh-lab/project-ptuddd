import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Tiện ích hỗ trợ cắt và xoay ảnh bằng `dart:ui`.
class CropUtils {
  CropUtils._();

  /// Cắt dữ liệu ảnh theo vùng tỉ lệ chuẩn hóa [normalizedRect] (0.0 đến 1.0)
  /// và số lần xoay góc 90 độ [rotationQuarterTurns] (0, 1, 2, 3).
  static Future<Uint8List> cropImage({
    required Uint8List imageBytes,
    required Rect normalizedRect,
    int rotationQuarterTurns = 0,
  }) async {
    final codec = await ui.instantiateImageCodec(imageBytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;
    final imgWidth = image.width.toDouble();
    final imgHeight = image.height.toDouble();

    // Giới hạn tọa độ trong kích thước ảnh thật
    final safeLeft = (normalizedRect.left * imgWidth).clamp(0.0, imgWidth);
    final safeTop = (normalizedRect.top * imgHeight).clamp(0.0, imgHeight);
    final safeRight = (normalizedRect.right * imgWidth).clamp(
      safeLeft + 1,
      imgWidth,
    );
    final safeBottom = (normalizedRect.bottom * imgHeight).clamp(
      safeTop + 1,
      imgHeight,
    );

    final pixelCropRect = Rect.fromLTRB(
      safeLeft,
      safeTop,
      safeRight,
      safeBottom,
    );
    final cropWidth = pixelCropRect.width.toInt().clamp(1, image.width);
    final cropHeight = pixelCropRect.height.toInt().clamp(1, image.height);

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final turns = rotationQuarterTurns % 4;
    final isOddRotation = turns % 2 != 0;
    final outputWidth = isOddRotation ? cropHeight : cropWidth;
    final outputHeight = isOddRotation ? cropWidth : cropHeight;

    if (turns == 0) {
      canvas.drawImageRect(
        image,
        pixelCropRect,
        Rect.fromLTWH(0, 0, cropWidth.toDouble(), cropHeight.toDouble()),
        Paint()..filterQuality = FilterQuality.high,
      );
    } else {
      canvas.save();
      canvas.translate(outputWidth / 2, outputHeight / 2);
      canvas.rotate(turns * math.pi / 2);
      canvas.drawImageRect(
        image,
        pixelCropRect,
        Rect.fromCenter(
          center: Offset.zero,
          width: cropWidth.toDouble(),
          height: cropHeight.toDouble(),
        ),
        Paint()..filterQuality = FilterQuality.high,
      );
      canvas.restore();
    }

    final picture = recorder.endRecording();
    final croppedUiImage = await picture.toImage(outputWidth, outputHeight);
    final byteData = await croppedUiImage.toByteData(
      format: ui.ImageByteFormat.png,
    );

    return byteData!.buffer.asUint8List();
  }
}

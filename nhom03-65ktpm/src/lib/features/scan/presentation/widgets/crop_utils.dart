import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Tiện ích hỗ trợ cắt và xoay ảnh bằng `dart:ui`.
class CropUtils {
  CropUtils._();

  /// Cắt dữ liệu ảnh theo vùng tỉ lệ chuẩn hóa [normalizedRect] (0.0 đến 1.0)
  /// tính trên ảnh **đã xoay** theo [rotationQuarterTurns] (0, 1, 2, 3).
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

    final turns = rotationQuarterTurns % 4;
    final isOddRotation = turns.isOdd;
    final rotatedWidth = isOddRotation ? imgHeight : imgWidth;
    final rotatedHeight = isOddRotation ? imgWidth : imgHeight;

    // Giới hạn tọa độ trong kích thước ảnh sau khi xoay
    final safeLeft = (normalizedRect.left * rotatedWidth).clamp(
      0.0,
      rotatedWidth - 1,
    );
    final safeTop = (normalizedRect.top * rotatedHeight).clamp(
      0.0,
      rotatedHeight - 1,
    );
    final safeRight = (normalizedRect.right * rotatedWidth).clamp(
      safeLeft + 1,
      rotatedWidth,
    );
    final safeBottom = (normalizedRect.bottom * rotatedHeight).clamp(
      safeTop + 1,
      rotatedHeight,
    );

    final cropWidth = (safeRight - safeLeft).round().clamp(
      1,
      rotatedWidth.toInt(),
    );
    final cropHeight = (safeBottom - safeTop).round().clamp(
      1,
      rotatedHeight.toInt(),
    );

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint()..filterQuality = FilterQuality.high;

    if (turns == 0) {
      canvas.drawImageRect(
        image,
        Rect.fromLTRB(safeLeft, safeTop, safeRight, safeBottom),
        Rect.fromLTWH(0, 0, cropWidth.toDouble(), cropHeight.toDouble()),
        paint,
      );
    } else {
      // Xoay ảnh gốc quanh tâm rồi dịch chuyển sao cho góc trên-trái vùng cắt nằm ở (0, 0)
      canvas.save();
      canvas.translate(-safeLeft, -safeTop);
      canvas.translate(rotatedWidth / 2, rotatedHeight / 2);
      canvas.rotate(turns * math.pi / 2);
      canvas.drawImageRect(
        image,
        Rect.fromLTWH(0, 0, imgWidth, imgHeight),
        Rect.fromCenter(
          center: Offset.zero,
          width: imgWidth,
          height: imgHeight,
        ),
        paint,
      );
      canvas.restore();
    }

    final picture = recorder.endRecording();
    final croppedUiImage = await picture.toImage(cropWidth, cropHeight);
    final byteData = await croppedUiImage.toByteData(
      format: ui.ImageByteFormat.png,
    );

    return byteData!.buffer.asUint8List();
  }
}

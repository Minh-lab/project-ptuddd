import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_note/features/scan/presentation/widgets/crop_utils.dart';

Future<Uint8List> _createSolidPng(int width, int height) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawRect(
    Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    Paint()..color = const Color(0xFF336699),
  );
  final picture = recorder.endRecording();
  final img = await picture.toImage(width, height);
  final data = await img.toByteData(format: ui.ImageByteFormat.png);
  return data!.buffer.asUint8List();
}

Future<Size> _decodeSize(Uint8List bytes) async {
  final codec = await ui.instantiateImageCodec(bytes);
  final frame = await codec.getNextFrame();
  return Size(frame.image.width.toDouble(), frame.image.height.toDouble());
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CropUtils', () {
    test('cắt ảnh không xoay cho kích thước đúng tỉ lệ', () async {
      final png = await _createSolidPng(40, 20);
      final cropped = await CropUtils.cropImage(
        imageBytes: png,
        normalizedRect: const Rect.fromLTWH(0, 0, 0.5, 0.5),
        rotationQuarterTurns: 0,
      );

      final size = await _decodeSize(cropped);
      expect(size, equals(const Size(20, 10)));
    });

    test('cắt và xoay 90 độ hoán đổi đúng chiều rộng và chiều cao', () async {
      final png = await _createSolidPng(40, 20);
      final cropped = await CropUtils.cropImage(
        imageBytes: png,
        normalizedRect: const Rect.fromLTWH(0, 0, 0.5, 0.5),
        rotationQuarterTurns: 1,
      );

      final size = await _decodeSize(cropped);
      expect(size, equals(const Size(10, 20)));
    });
  });
}

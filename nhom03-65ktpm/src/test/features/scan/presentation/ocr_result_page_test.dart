import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_note/features/scan/domain/entities/ocr_result.dart';
import 'package:smart_note/features/scan/domain/entities/scanned_image.dart';
import 'package:smart_note/features/scan/domain/repositories/ocr_note_saver.dart';
import 'package:smart_note/features/scan/domain/repositories/ocr_repository.dart';
import 'package:smart_note/features/scan/presentation/pages/ocr_result_page.dart';

class _StubOcrRepository implements OcrRepository {
  OcrResult result = const OcrResult(text: '');

  @override
  Future<OcrResult> recognizeText({
    required String imagePath,
    String? imageId,
  }) async {
    return result;
  }
}

class _FakeNoteSaver implements OcrNoteSaver {
  String? lastSavedContent;
  String? lastOriginalPath;

  @override
  Future<String> saveAsNote({
    required String title,
    required String content,
    required String originalImagePath,
    String? croppedImagePath,
    String? ocrRawText,
  }) async {
    lastSavedContent = content;
    lastOriginalPath = originalImagePath;
    return 'saved-note-1';
  }
}

void main() {
  final samplePng = Uint8List.fromList(<int>[
    137,
    80,
    78,
    71,
    13,
    10,
    26,
    10,
    0,
    0,
    0,
    13,
    73,
    72,
    68,
    82,
    0,
    0,
    0,
    1,
    0,
    0,
    0,
    1,
    8,
    6,
    0,
    0,
    0,
    31,
    21,
    196,
    137,
    0,
    0,
    0,
    10,
    73,
    68,
    65,
    84,
    120,
    156,
    99,
    0,
    1,
    0,
    0,
    5,
    0,
    1,
    13,
    10,
    45,
    180,
    0,
    0,
    0,
    0,
    73,
    69,
    78,
    68,
    174,
    66,
    96,
    130,
  ]);

  final sampleImage = ScannedImage(
    id: 'ocr-ui-1',
    originalPath: '/scans/original.jpg',
    originalBytes: samplePng,
  );

  testWidgets('hiển thị ảnh và văn bản OCR cho phép chỉnh sửa rồi lưu', (
    WidgetTester tester,
  ) async {
    final ocrRepo = _StubOcrRepository()
      ..result = const OcrResult(text: 'Định lý Lagrange', durationMs: 1200);
    final saver = _FakeNoteSaver();

    await tester.pumpWidget(
      MaterialApp(
        home: OcrResultPage(
          image: sampleImage,
          ocrRepository: ocrRepo,
          noteSaver: saver,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(Image), findsOneWidget);
    expect(find.text('Định lý Lagrange'), findsOneWidget);
    expect(find.text('Lưu thành ghi chú'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Định lý Lagrange'),
      'Định lý Lagrange đã sửa',
    );
    await tester.tap(find.text('Lưu thành ghi chú'));
    await tester.pumpAndSettle();

    expect(saver.lastSavedContent, equals('Định lý Lagrange đã sửa'));
    expect(saver.lastOriginalPath, equals('/scans/original.jpg'));
  });

  testWidgets('hiển thị cảnh báo khi ảnh mờ hoặc không có chữ', (
    WidgetTester tester,
  ) async {
    final ocrRepo = _StubOcrRepository()..result = const OcrResult(text: '');

    await tester.pumpWidget(
      MaterialApp(
        home: OcrResultPage(image: sampleImage, ocrRepository: ocrRepo),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Không nhận dạng được chữ trong ảnh'), findsOneWidget);
    expect(find.text('Chụp lại ảnh'), findsOneWidget);
    expect(find.text('Nhập thủ công'), findsOneWidget);
  });
}

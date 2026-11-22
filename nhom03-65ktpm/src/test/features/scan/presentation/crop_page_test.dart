import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_note/features/scan/domain/entities/scanned_image.dart';
import 'package:smart_note/features/scan/presentation/pages/crop_page.dart';
import 'package:smart_note/features/scan/presentation/widgets/crop_overlay.dart';

void main() {
  final sampleBytes = Uint8List.fromList(<int>[
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

  testWidgets('CropPage hiển thị đúng ảnh và các điều khiển cắt xoay', (
    WidgetTester tester,
  ) async {
    final scannedImage = ScannedImage(
      id: 'crop-test-img',
      originalPath: '/test/note.png',
      originalBytes: sampleBytes,
    );

    await tester.pumpWidget(MaterialApp(home: CropPage(image: scannedImage)));

    expect(find.text('Cắt & Căn chỉnh vở'), findsOneWidget);
    expect(find.text('Xong'), findsOneWidget);
    expect(find.text('Xoay 90°'), findsOneWidget);
    expect(find.text('Đặt lại'), findsOneWidget);
    expect(find.byType(CropOverlay), findsOneWidget);

    // Bấm nút xoay 90 độ
    await tester.tap(find.text('Xoay 90°'));
    await tester.pump();
    expect(find.byType(RotatedBox), findsOneWidget);
  });
}

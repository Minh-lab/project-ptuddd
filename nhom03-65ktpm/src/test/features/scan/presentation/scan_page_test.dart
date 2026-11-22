import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_note/features/scan/domain/entities/scanned_image.dart';
import 'package:smart_note/features/scan/domain/repositories/scan_repository.dart';
import 'package:smart_note/features/scan/presentation/pages/scan_page.dart';

class StubScanRepository implements ScanRepository {
  ScannedImage? imageToReturn;

  @override
  Future<ScannedImage?> captureFromCamera() async => imageToReturn;

  @override
  Future<ScannedImage?> pickFromGallery() async => imageToReturn;

  @override
  Future<ScannedImage> saveCroppedImage({
    required ScannedImage image,
    required Uint8List croppedBytes,
  }) async {
    return image.copyWith(croppedBytes: croppedBytes);
  }
}

void main() {
  // 1x1 valid PNG bytes
  final transparentPng = Uint8List.fromList(<int>[
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

  late StubScanRepository repository;

  setUp(() {
    repository = StubScanRepository();
  });

  testWidgets('Hiển thị giao diện ban đầu với 2 nút chụp và chọn ảnh', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: ScanPage(scanRepository: repository)),
    );

    expect(find.text('Quét vở học tập'), findsOneWidget);
    expect(find.text('Số hóa trang vở bài học'), findsOneWidget);
    expect(find.text('Chụp ảnh bằng Camera'), findsOneWidget);
    expect(find.text('Chọn ảnh từ thư viện'), findsOneWidget);
  });

  testWidgets('Hiển thị ảnh và các nút chức năng khi đã có ảnh quét', (
    WidgetTester tester,
  ) async {
    final scannedImage = ScannedImage(
      id: 'img-1',
      originalPath: '/mock/path.png',
      originalBytes: transparentPng,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ScanPage(scanRepository: repository, initialImage: scannedImage),
      ),
    );

    expect(find.text('Ảnh gốc trang vở'), findsOneWidget);
    expect(find.text('Cắt ảnh / Căn viền'), findsOneWidget);
    expect(find.text('Tiếp tục OCR'), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
  });
}

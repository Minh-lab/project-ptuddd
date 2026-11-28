import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../domain/entities/scanned_image.dart';
import '../widgets/crop_overlay.dart';
import '../widgets/crop_utils.dart';

/// Màn hình cắt và căn chỉnh ảnh trang vở đã chụp.
class CropPage extends StatefulWidget {
  const CropPage({required this.image, super.key});

  final ScannedImage image;

  @override
  State<CropPage> createState() => _CropPageState();
}

class _CropPageState extends State<CropPage> {
  int _rotationQuarterTurns = 0;
  Rect? _cropRect;
  Size? _imageBoxSize;
  Size? _intrinsicImageSize;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _decodeImageSize();
  }

  Future<void> _decodeImageSize() async {
    try {
      final codec = await ui.instantiateImageCodec(widget.image.originalBytes);
      final frame = await codec.getNextFrame();
      if (!mounted) return;
      setState(() {
        _intrinsicImageSize = Size(
          frame.image.width.toDouble(),
          frame.image.height.toDouble(),
        );
        _cropRect = null;
      });
    } catch (_) {
      // Giữ fallback theo kích thước container nếu ảnh không giải mã được kích thước trước
    }
  }

  void _rotate() {
    setState(() {
      _rotationQuarterTurns = (_rotationQuarterTurns + 1) % 4;
      // Khi xoay thì reset lại khung cắt vừa với tỷ lệ mới
      _cropRect = null;
    });
  }

  void _resetCrop() {
    if (_imageBoxSize != null) {
      setState(() {
        _cropRect = _calculateDefaultCropRect(_imageBoxSize!);
      });
    }
  }

  Size _computeFittedSize(Size containerSize) {
    final intrinsic = _intrinsicImageSize;
    if (intrinsic == null || intrinsic.isEmpty) {
      return containerSize;
    }
    final isOddRotation = _rotationQuarterTurns.isOdd;
    final rotatedSourceSize = isOddRotation
        ? Size(intrinsic.height, intrinsic.width)
        : intrinsic;
    return applyBoxFit(
      BoxFit.contain,
      rotatedSourceSize,
      containerSize,
    ).destination;
  }

  Rect _calculateDefaultCropRect(Size size) {
    // Khung cắt mặc định chiếm 85% trung tâm ảnh
    final marginX = size.width * 0.075;
    final marginY = size.height * 0.075;
    return Rect.fromLTWH(
      marginX,
      marginY,
      size.width - (marginX * 2),
      size.height - (marginY * 2),
    );
  }

  Future<void> _confirmCrop() async {
    if (_cropRect == null || _imageBoxSize == null || _isProcessing) {
      return;
    }

    setState(() => _isProcessing = true);

    try {
      // Chuẩn hóa tọa độ cắt về khoảng [0.0, 1.0] theo đúng vùng ảnh hiển thị
      final normalizedRect = Rect.fromLTRB(
        _cropRect!.left / _imageBoxSize!.width,
        _cropRect!.top / _imageBoxSize!.height,
        _cropRect!.right / _imageBoxSize!.width,
        _cropRect!.bottom / _imageBoxSize!.height,
      );

      final croppedBytes = await CropUtils.cropImage(
        imageBytes: widget.image.originalBytes,
        normalizedRect: normalizedRect,
        rotationQuarterTurns: _rotationQuarterTurns,
      );

      if (!mounted) return;
      Navigator.of(context).pop<Uint8List>(croppedBytes);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Không thể cắt ảnh: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Cắt & Căn chỉnh vở'),
        actions: <Widget>[
          TextButton.icon(
            onPressed: _isProcessing ? null : _confirmCrop,
            icon: const Icon(Icons.check, color: Colors.greenAccent),
            label: const Text(
              'Xong',
              style: TextStyle(
                color: Colors.greenAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            // Vùng hiển thị ảnh + khung cắt
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: LayoutBuilder(
                    builder:
                        (BuildContext context, BoxConstraints constraints) {
                          final containerSize = Size(
                            constraints.maxWidth,
                            constraints.maxHeight,
                          );
                          final fittedSize = _computeFittedSize(containerSize);
                          if (_imageBoxSize != fittedSize) {
                            _imageBoxSize = fittedSize;
                            _cropRect = _calculateDefaultCropRect(fittedSize);
                          } else {
                            _cropRect ??= _calculateDefaultCropRect(fittedSize);
                          }

                          return SizedBox(
                            width: fittedSize.width,
                            height: fittedSize.height,
                            child: Stack(
                              alignment: Alignment.center,
                              children: <Widget>[
                                // Ảnh nền được xoay vừa khít khung hiển thị
                                RotatedBox(
                                  quarterTurns: _rotationQuarterTurns,
                                  child: Image.memory(
                                    widget.image.originalBytes,
                                    fit: BoxFit.fill,
                                    width: _rotationQuarterTurns.isOdd
                                        ? fittedSize.height
                                        : fittedSize.width,
                                    height: _rotationQuarterTurns.isOdd
                                        ? fittedSize.width
                                        : fittedSize.height,
                                  ),
                                ),

                                // Khung lưới cắt tương tác nằm khớp trên ảnh
                                CropOverlay(
                                  containerSize: fittedSize,
                                  initialRect: _cropRect!,
                                  onRectChanged: (Rect rect) =>
                                      _cropRect = rect,
                                ),

                                // Vòng xoay khi đang xử lý
                                if (_isProcessing)
                                  Container(
                                    color: Colors.black45,
                                    child: const Center(
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                  ),
                ),
              ),
            ),

            // Thanh công cụ phía dưới (Xoay, Khôi phục)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              color: Colors.grey.shade900,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: <Widget>[
                  TextButton.icon(
                    onPressed: _isProcessing ? null : _rotate,
                    icon: const Icon(
                      Icons.rotate_90_degrees_cw,
                      color: Colors.white,
                    ),
                    label: const Text(
                      'Xoay 90°',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _isProcessing ? null : _resetCrop,
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    label: const Text(
                      'Đặt lại',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

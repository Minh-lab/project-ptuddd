import 'package:flutter/material.dart';

/// Khung cắt tương tác cho phép kéo di chuyển và thay đổi kích thước vùng chọn.
class CropOverlay extends StatefulWidget {
  const CropOverlay({
    required this.containerSize,
    required this.initialRect,
    required this.onRectChanged,
    super.key,
  });

  final Size containerSize;
  final Rect initialRect;
  final ValueChanged<Rect> onRectChanged;

  @override
  State<CropOverlay> createState() => _CropOverlayState();
}

class _CropOverlayState extends State<CropOverlay> {
  late Rect _rect;

  @override
  void initState() {
    super.initState();
    _rect = widget.initialRect;
  }

  @override
  void didUpdateWidget(covariant CropOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialRect != oldWidget.initialRect) {
      _rect = widget.initialRect;
    }
  }

  void _updateRect(Rect newRect) {
    final clamped = Rect.fromLTRB(
      newRect.left.clamp(0.0, widget.containerSize.width - 40),
      newRect.top.clamp(0.0, widget.containerSize.height - 40),
      newRect.right.clamp(newRect.left + 40, widget.containerSize.width),
      newRect.bottom.clamp(newRect.top + 40, widget.containerSize.height),
    );
    setState(() => _rect = clamped);
    widget.onRectChanged(clamped);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        // Lớp vẽ vùng tối mờ xung quanh + lưới căn chỉnh
        CustomPaint(
          size: widget.containerSize,
          painter: _CropPainter(rect: _rect),
        ),

        // Vùng chạm kéo di chuyển toàn bộ khung
        Positioned.fromRect(
          rect: _rect,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanUpdate: (DragUpdateDetails details) {
              final next = _rect.shift(details.delta);
              final boundedLeft = next.left.clamp(
                0.0,
                widget.containerSize.width - _rect.width,
              );
              final boundedTop = next.top.clamp(
                0.0,
                widget.containerSize.height - _rect.height,
              );
              _updateRect(
                Rect.fromLTWH(
                  boundedLeft,
                  boundedTop,
                  _rect.width,
                  _rect.height,
                ),
              );
            },
          ),
        ),

        // Nút kéo góc Trên - Trái
        _buildHandle(
          left: _rect.left - 16,
          top: _rect.top - 16,
          onPanUpdate: (d) => _updateRect(
            Rect.fromLTRB(
              _rect.left + d.delta.dx,
              _rect.top + d.delta.dy,
              _rect.right,
              _rect.bottom,
            ),
          ),
        ),

        // Nút kéo góc Trên - Phải
        _buildHandle(
          left: _rect.right - 16,
          top: _rect.top - 16,
          onPanUpdate: (d) => _updateRect(
            Rect.fromLTRB(
              _rect.left,
              _rect.top + d.delta.dy,
              _rect.right + d.delta.dx,
              _rect.bottom,
            ),
          ),
        ),

        // Nút kéo góc Dưới - Trái
        _buildHandle(
          left: _rect.left - 16,
          top: _rect.bottom - 16,
          onPanUpdate: (d) => _updateRect(
            Rect.fromLTRB(
              _rect.left + d.delta.dx,
              _rect.top,
              _rect.right,
              _rect.bottom + d.delta.dy,
            ),
          ),
        ),

        // Nút kéo góc Dưới - Phải
        _buildHandle(
          left: _rect.right - 16,
          top: _rect.bottom - 16,
          onPanUpdate: (d) => _updateRect(
            Rect.fromLTRB(
              _rect.left,
              _rect.top,
              _rect.right + d.delta.dx,
              _rect.bottom + d.delta.dy,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHandle({
    required double left,
    required double top,
    required GestureDragUpdateCallback onPanUpdate,
  }) {
    return Positioned(
      left: left,
      top: top,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanUpdate: onPanUpdate,
        child: Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          child: Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).primaryColor,
                width: 3,
              ),
              boxShadow: const <BoxShadow>[
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CropPainter extends CustomPainter {
  const _CropPainter({required this.rect});

  final Rect rect;

  @override
  void paint(Canvas canvas, Size size) {
    // Vùng mờ bên ngoài
    final backgroundPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.55)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRect(rect)
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, backgroundPaint);

    // Viền khung cắt
    final borderPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    canvas.drawRect(rect, borderPaint);

    // Lưới 1/3 (rule of thirds)
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..strokeWidth = 1.0;

    final oneThirdW = rect.width / 3;
    final oneThirdH = rect.height / 3;

    // Đường dọc
    canvas.drawLine(
      Offset(rect.left + oneThirdW, rect.top),
      Offset(rect.left + oneThirdW, rect.bottom),
      gridPaint,
    );
    canvas.drawLine(
      Offset(rect.left + oneThirdW * 2, rect.top),
      Offset(rect.left + oneThirdW * 2, rect.bottom),
      gridPaint,
    );

    // Đường ngang
    canvas.drawLine(
      Offset(rect.left, rect.top + oneThirdH),
      Offset(rect.right, rect.top + oneThirdH),
      gridPaint,
    );
    canvas.drawLine(
      Offset(rect.left, rect.top + oneThirdH * 2),
      Offset(rect.right, rect.top + oneThirdH * 2),
      gridPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CropPainter oldDelegate) =>
      oldDelegate.rect != rect;
}

import 'package:equatable/equatable.dart';

/// Một khối văn bản được nhận dạng từ ảnh trang vở.
class OcrBlock extends Equatable {
  const OcrBlock({required this.text, this.lines = const <String>[]});

  final String text;
  final List<String> lines;

  @override
  List<Object?> get props => <Object?>[text, lines];
}

/// Kết quả nhận dạng chữ (OCR) trên một trang vở.
///
/// Entity thuần Dart, không phụ thuộc Flutter hay package ML Kit.
class OcrResult extends Equatable {
  const OcrResult({
    required this.text,
    this.blocks = const <OcrBlock>[],
    this.durationMs = 0,
    this.imageId,
    this.createdAt,
  });

  /// Toàn bộ văn bản nhận dạng được.
  final String text;

  /// Danh sách từng khối văn bản theo thứ tự đọc.
  final List<OcrBlock> blocks;

  /// Thời gian xử lý OCR tính bằng mili-giây.
  final int durationMs;

  /// Mã ảnh đã quét tương ứng.
  final String? imageId;

  /// Thời điểm hoàn thành nhận dạng.
  final DateTime? createdAt;

  /// Trả về `true` nếu ảnh mờ, thiếu sáng hoặc không có chữ đọc được.
  bool get isEmptyText => text.trim().isEmpty;

  OcrResult copyWith({
    String? text,
    List<OcrBlock>? blocks,
    int? durationMs,
    String? imageId,
    DateTime? createdAt,
  }) {
    return OcrResult(
      text: text ?? this.text,
      blocks: blocks ?? this.blocks,
      durationMs: durationMs ?? this.durationMs,
      imageId: imageId ?? this.imageId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    text,
    blocks,
    durationMs,
    imageId,
    createdAt,
  ];
}

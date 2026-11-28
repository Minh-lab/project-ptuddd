/// Hợp đồng lưu kết quả OCR thành ghi chú mới kèm ảnh gốc và ảnh đã cắt.
abstract interface class OcrNoteSaver {
  /// Tạo ghi chú mới với [title], [content] và đính kèm [originalImagePath].
  ///
  /// Trả về ID của ghi chú vừa tạo.
  Future<String> saveAsNote({
    required String title,
    required String content,
    required String originalImagePath,
    String? croppedImagePath,
    String? ocrRawText,
  });
}

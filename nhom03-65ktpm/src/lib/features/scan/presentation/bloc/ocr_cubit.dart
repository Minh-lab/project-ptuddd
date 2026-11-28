import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failure.dart';
import '../../domain/entities/scanned_image.dart';
import '../../domain/repositories/ocr_note_saver.dart';
import '../../domain/usecases/recognize_text_usecase.dart';
import 'ocr_state.dart';

/// Quản lý trạng thái nhận dạng chữ ML Kit, chỉnh sửa văn bản và lưu ghi chú.
class OcrCubit extends Cubit<OcrState> {
  OcrCubit({required this.recognizeTextUseCase, this.noteSaver})
    : super(const OcrState());

  final RecognizeTextUseCase recognizeTextUseCase;
  final OcrNoteSaver? noteSaver;

  /// Chạy nhận dạng chữ từ ảnh [image] (ưu tiên ảnh đã cắt).
  Future<void> recognizeImage(ScannedImage image) async {
    emit(state.copyWith(status: OcrStatus.loading));
    try {
      final result = await recognizeTextUseCase(
        imagePath: image.activePath,
        imageId: image.id,
      );

      if (result.isEmptyText) {
        emit(
          state.copyWith(
            status: OcrStatus.empty,
            result: result,
            editedText: '',
          ),
        );
        return;
      }

      emit(
        state.copyWith(
          status: OcrStatus.success,
          result: result,
          editedText: result.text,
        ),
      );
    } on ScanFailure catch (e) {
      emit(state.copyWith(status: OcrStatus.failure, errorMessage: e.message));
    } catch (e) {
      emit(
        state.copyWith(
          status: OcrStatus.failure,
          errorMessage: 'Không thể nhận dạng chữ: ${e.toString()}',
        ),
      );
    }
  }

  /// Cập nhật nội dung văn bản sau khi người dùng chỉnh sửa lỗi OCR.
  void updateText(String value) {
    final nextStatus =
        state.status == OcrStatus.empty && value.trim().isNotEmpty
        ? OcrStatus.success
        : state.status;
    emit(state.copyWith(status: nextStatus, editedText: value));
  }

  /// Chuyển từ cảnh báo ảnh mờ sang chế độ cho phép người dùng tự nhập văn bản.
  void switchToManualEdit() {
    emit(state.copyWith(status: OcrStatus.success));
  }

  /// Lưu văn bản đã chỉnh sửa thành ghi chú mới kèm ảnh gốc.
  Future<void> saveAsNote({
    required String title,
    required ScannedImage image,
  }) async {
    final saver = noteSaver;
    if (saver == null) {
      emit(
        state.copyWith(
          status: OcrStatus.failure,
          errorMessage: 'Chưa cấu hình chức năng lưu ghi chú.',
        ),
      );
      return;
    }
    if (state.editedText.trim().isEmpty) {
      emit(
        state.copyWith(
          status: OcrStatus.failure,
          errorMessage: 'Vui lòng nhập hoặc nhận dạng văn bản trước khi lưu.',
        ),
      );
      return;
    }

    emit(state.copyWith(status: OcrStatus.saving));
    try {
      final noteId = await saver.saveAsNote(
        title: title.trim(),
        content: state.editedText.trim(),
        originalImagePath: image.originalPath,
        croppedImagePath: image.croppedPath,
        ocrRawText: state.result?.text,
      );
      emit(state.copyWith(status: OcrStatus.saved, savedNoteId: noteId));
    } catch (e) {
      emit(
        state.copyWith(
          status: OcrStatus.failure,
          errorMessage: 'Không thể lưu ghi chú: ${e.toString()}',
        ),
      );
    }
  }
}

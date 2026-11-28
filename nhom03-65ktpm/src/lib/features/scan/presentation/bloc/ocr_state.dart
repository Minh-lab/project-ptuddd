import 'package:equatable/equatable.dart';

import '../../domain/entities/ocr_result.dart';

/// Các trạng thái của quá trình nhận dạng chữ và lưu ghi chú từ ảnh quét.
enum OcrStatus { initial, loading, success, empty, saving, saved, failure }

class OcrState extends Equatable {
  const OcrState({
    this.status = OcrStatus.initial,
    this.result,
    this.editedText = '',
    this.errorMessage,
    this.savedNoteId,
  });

  final OcrStatus status;
  final OcrResult? result;
  final String editedText;
  final String? errorMessage;
  final String? savedNoteId;

  bool get isLoading => status == OcrStatus.loading;
  bool get isSaving => status == OcrStatus.saving;
  bool get isEmptyResult => status == OcrStatus.empty;
  bool get canSave => editedText.trim().isNotEmpty && !isLoading && !isSaving;

  OcrState copyWith({
    OcrStatus? status,
    OcrResult? result,
    String? editedText,
    String? errorMessage,
    String? savedNoteId,
  }) {
    return OcrState(
      status: status ?? this.status,
      result: result ?? this.result,
      editedText: editedText ?? this.editedText,
      errorMessage: errorMessage,
      savedNoteId: savedNoteId ?? this.savedNoteId,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    status,
    result,
    editedText,
    errorMessage,
    savedNoteId,
  ];
}

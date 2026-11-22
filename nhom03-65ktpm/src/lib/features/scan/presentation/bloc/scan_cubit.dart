import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/scanned_image.dart';
import '../../domain/usecases/capture_image_usecase.dart';
import '../../domain/usecases/crop_image_usecase.dart';
import '../../domain/usecases/pick_image_usecase.dart';
import 'scan_state.dart';

/// Quản lý trạng thái cho quy trình quét và cắt ảnh vở.
class ScanCubit extends Cubit<ScanState> {
  ScanCubit({
    required this.captureImageUseCase,
    required this.pickImageUseCase,
    required this.cropImageUseCase,
    ScannedImage? initialImage,
  }) : super(
         ScanState(
           status: initialImage != null
               ? ScanStatus.imageReady
               : ScanStatus.initial,
           image: initialImage,
         ),
       );

  final CaptureImageUseCase captureImageUseCase;
  final PickImageUseCase pickImageUseCase;
  final CropImageUseCase cropImageUseCase;

  /// Chụp ảnh trang vở từ camera.
  Future<void> captureImage() async {
    emit(state.copyWith(status: ScanStatus.loading));
    try {
      final image = await captureImageUseCase();
      if (image == null) {
        emit(
          state.copyWith(
            status: state.hasImage ? ScanStatus.imageReady : ScanStatus.initial,
          ),
        );
        return;
      }
      emit(state.copyWith(status: ScanStatus.imageReady, image: image));
    } catch (e) {
      emit(
        state.copyWith(
          status: ScanStatus.failure,
          errorMessage: 'Không thể chụp ảnh: ${e.toString()}',
        ),
      );
    }
  }

  /// Chọn ảnh trang vở từ bộ sưu tập.
  Future<void> pickImage() async {
    emit(state.copyWith(status: ScanStatus.loading));
    try {
      final image = await pickImageUseCase();
      if (image == null) {
        emit(
          state.copyWith(
            status: state.hasImage ? ScanStatus.imageReady : ScanStatus.initial,
          ),
        );
        return;
      }
      emit(state.copyWith(status: ScanStatus.imageReady, image: image));
    } catch (e) {
      emit(
        state.copyWith(
          status: ScanStatus.failure,
          errorMessage: 'Không thể chọn ảnh: ${e.toString()}',
        ),
      );
    }
  }

  /// Cập nhật kết quả sau khi cắt ảnh thành công.
  Future<void> applyCrop(Uint8List croppedBytes) async {
    final current = state.image;
    if (current == null) {
      return;
    }

    emit(state.copyWith(status: ScanStatus.cropping));
    try {
      final updated = await cropImageUseCase(
        image: current,
        croppedBytes: croppedBytes,
      );
      emit(state.copyWith(status: ScanStatus.success, image: updated));
    } catch (e) {
      emit(
        state.copyWith(
          status: ScanStatus.failure,
          errorMessage: 'Lỗi khi lưu ảnh đã cắt: ${e.toString()}',
        ),
      );
    }
  }

  /// Xóa ảnh hiện tại và bắt đầu lại lượt quét mới.
  void clearImage() {
    emit(const ScanState());
  }
}

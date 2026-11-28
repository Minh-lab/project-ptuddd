import 'package:equatable/equatable.dart';

import '../../domain/entities/scanned_image.dart';

enum ScanStatus { initial, loading, imageReady, cropping, success, failure }

class ScanState extends Equatable {
  const ScanState({
    this.status = ScanStatus.initial,
    this.image,
    this.errorMessage,
    this.isPermissionDenied = false,
  });

  final ScanStatus status;
  final ScannedImage? image;
  final String? errorMessage;

  /// Cho biết lỗi hiện tại là do thiếu quyền truy cập camera hoặc thư viện.
  final bool isPermissionDenied;

  bool get isLoading =>
      status == ScanStatus.loading || status == ScanStatus.cropping;

  bool get hasImage => image != null;

  ScanState copyWith({
    ScanStatus? status,
    ScannedImage? image,
    String? errorMessage,
    bool isPermissionDenied = false,
  }) {
    return ScanState(
      status: status ?? this.status,
      image: image ?? this.image,
      errorMessage: errorMessage,
      isPermissionDenied: isPermissionDenied,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    status,
    image,
    errorMessage,
    isPermissionDenied,
  ];
}

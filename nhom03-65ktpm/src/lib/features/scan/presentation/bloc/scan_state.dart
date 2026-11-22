import 'package:equatable/equatable.dart';

import '../../domain/entities/scanned_image.dart';

enum ScanStatus { initial, loading, imageReady, cropping, success, failure }

class ScanState extends Equatable {
  const ScanState({
    this.status = ScanStatus.initial,
    this.image,
    this.errorMessage,
  });

  final ScanStatus status;
  final ScannedImage? image;
  final String? errorMessage;

  bool get isLoading =>
      status == ScanStatus.loading || status == ScanStatus.cropping;

  bool get hasImage => image != null;

  ScanState copyWith({
    ScanStatus? status,
    ScannedImage? image,
    String? errorMessage,
  }) {
    return ScanState(
      status: status ?? this.status,
      image: image ?? this.image,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => <Object?>[status, image, errorMessage];
}

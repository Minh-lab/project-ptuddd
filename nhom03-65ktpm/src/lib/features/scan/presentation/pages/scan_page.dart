import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/ocr_repository_impl.dart';
import '../../domain/entities/scanned_image.dart';
import '../../domain/repositories/ocr_note_saver.dart';
import '../../domain/repositories/ocr_repository.dart';
import '../../domain/repositories/scan_repository.dart';
import '../../domain/usecases/capture_image_usecase.dart';
import '../../domain/usecases/crop_image_usecase.dart';
import '../../domain/usecases/pick_image_usecase.dart';
import '../bloc/scan_cubit.dart';
import '../bloc/scan_state.dart';
import 'crop_page.dart';
import 'ocr_result_page.dart';

/// Màn hình chính của tính năng Quét vở: Chụp ảnh, chọn ảnh và điều hướng cắt ảnh.
class ScanPage extends StatelessWidget {
  const ScanPage({
    required this.scanRepository,
    this.ocrRepository,
    this.ocrNoteSaver,
    this.initialImage,
    super.key,
  });

  final ScanRepository scanRepository;
  final OcrRepository? ocrRepository;
  final OcrNoteSaver? ocrNoteSaver;
  final ScannedImage? initialImage;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ScanCubit>(
      create: (BuildContext context) => ScanCubit(
        captureImageUseCase: CaptureImageUseCase(scanRepository),
        pickImageUseCase: PickImageUseCase(scanRepository),
        cropImageUseCase: CropImageUseCase(scanRepository),
        initialImage: initialImage,
      ),
      child: _ScanPageView(
        ocrRepository: ocrRepository,
        ocrNoteSaver: ocrNoteSaver,
      ),
    );
  }
}

class _ScanPageView extends StatelessWidget {
  const _ScanPageView({this.ocrRepository, this.ocrNoteSaver});

  final OcrRepository? ocrRepository;
  final OcrNoteSaver? ocrNoteSaver;

  Future<void> _openCropPage(BuildContext context, ScannedImage image) async {
    final croppedBytes = await Navigator.of(context).push<Uint8List>(
      MaterialPageRoute<Uint8List>(builder: (_) => CropPage(image: image)),
    );

    if (croppedBytes != null && context.mounted) {
      await context.read<ScanCubit>().applyCrop(croppedBytes);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quét vở học tập'),
        actions: <Widget>[
          BlocBuilder<ScanCubit, ScanState>(
            builder: (BuildContext context, ScanState state) {
              if (state.hasImage) {
                return IconButton(
                  tooltip: 'Chụp lại từ đầu',
                  icon: const Icon(Icons.refresh),
                  onPressed: () => context.read<ScanCubit>().clearImage(),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: BlocConsumer<ScanCubit, ScanState>(
        listener: (BuildContext context, ScanState state) {
          if (state.status == ScanStatus.failure &&
              state.errorMessage != null) {
            if (state.isPermissionDenied) {
              _showPermissionDeniedDialog(context, state.errorMessage!);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.errorMessage!),
                  backgroundColor: theme.colorScheme.error,
                ),
              );
            }
          }
        },
        builder: (BuildContext context, ScanState state) {
          if (state.isLoading) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Đang xử lý hình ảnh...'),
                ],
              ),
            );
          }

          if (!state.hasImage) {
            return _EmptyScanView(
              onCapture: () => context.read<ScanCubit>().captureImage(),
              onPick: () => context.read<ScanCubit>().pickImage(),
            );
          }

          final image = state.image!;
          return _PreviewScanView(
            image: image,
            onCrop: () => _openCropPage(context, image),
            onPickAnother: () => _showSourceDialog(context),
            onContinueOcr: () => _openOcrPage(context, image),
          );
        },
      ),
    );
  }

  Future<void> _openOcrPage(BuildContext context, ScannedImage image) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => OcrResultPage(
          image: image,
          ocrRepository: ocrRepository ?? OcrRepositoryImpl(),
          noteSaver: ocrNoteSaver,
        ),
      ),
    );
    if (saved == true && context.mounted) {
      Navigator.of(context).pop();
    }
  }

  void _showPermissionDeniedDialog(BuildContext context, String message) {
    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          icon: const Icon(Icons.lock_outline, size: 32),
          title: const Text('Cần cấp quyền truy cập'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Đóng'),
            ),
          ],
        );
      },
    );
  }

  void _showSourceDialog(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext bottomSheetContext) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Chụp ảnh mới bằng Camera'),
                onTap: () {
                  Navigator.of(bottomSheetContext).pop();
                  context.read<ScanCubit>().captureImage();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Chọn ảnh khác từ Thư viện'),
                onTap: () {
                  Navigator.of(bottomSheetContext).pop();
                  context.read<ScanCubit>().pickImage();
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _EmptyScanView extends StatelessWidget {
  const _EmptyScanView({required this.onCapture, required this.onPick});

  final VoidCallback onCapture;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(
                  alpha: 0.4,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.document_scanner_outlined,
                size: 84,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Số hóa trang vở bài học',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Chụp ảnh trực tiếp hoặc chọn ảnh vở từ thư viện để cắt viền và nhận dạng chữ.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 36),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                onPressed: onCapture,
                icon: const Icon(Icons.camera_alt_outlined),
                label: const Text(
                  'Chụp ảnh bằng Camera',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: onPick,
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text(
                  'Chọn ảnh từ thư viện',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewScanView extends StatelessWidget {
  const _PreviewScanView({
    required this.image,
    required this.onCrop,
    required this.onPickAnother,
    required this.onContinueOcr,
  });

  final ScannedImage image;
  final VoidCallback onCrop;
  final VoidCallback onPickAnother;
  final VoidCallback onContinueOcr;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: <Widget>[
          // Trạng thái / Nhãn đã cắt
          Row(
            children: <Widget>[
              Icon(
                image.isCropped ? Icons.crop_free : Icons.image_outlined,
                size: 20,
                color: image.isCropped
                    ? Colors.green
                    : theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                image.isCropped ? 'Trang vở đã cắt chuẩn' : 'Ảnh gốc trang vở',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: image.isCropped ? Colors.green : null,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: onPickAnother,
                icon: const Icon(Icons.swap_horiz, size: 18),
                label: const Text('Đổi ảnh'),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Xem trước ảnh
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                color: Colors.black12,
                child: Image.memory(image.activeBytes, fit: BoxFit.contain),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Nút cắt ảnh & Tiếp tục
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onCrop,
                  icon: const Icon(Icons.crop),
                  label: Text(
                    image.isCropped ? 'Cắt lại' : 'Cắt ảnh / Căn viền',
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: onContinueOcr,
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Tiếp tục OCR'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

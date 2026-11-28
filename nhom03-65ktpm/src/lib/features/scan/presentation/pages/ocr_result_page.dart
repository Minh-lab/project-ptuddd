import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/scanned_image.dart';
import '../../domain/repositories/ocr_note_saver.dart';
import '../../domain/repositories/ocr_repository.dart';
import '../../domain/usecases/recognize_text_usecase.dart';
import '../bloc/ocr_cubit.dart';
import '../bloc/ocr_state.dart';

/// Màn hình so sánh ảnh trang vở và văn bản OCR, cho phép chỉnh sửa và lưu thành ghi chú.
class OcrResultPage extends StatelessWidget {
  const OcrResultPage({
    required this.image,
    required this.ocrRepository,
    this.noteSaver,
    super.key,
  });

  final ScannedImage image;
  final OcrRepository ocrRepository;
  final OcrNoteSaver? noteSaver;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<OcrCubit>(
      create: (_) => OcrCubit(
        recognizeTextUseCase: RecognizeTextUseCase(ocrRepository),
        noteSaver: noteSaver,
      )..recognizeImage(image),
      child: _OcrResultView(image: image),
    );
  }
}

class _OcrResultView extends StatefulWidget {
  const _OcrResultView({required this.image});

  final ScannedImage image;

  @override
  State<_OcrResultView> createState() => _OcrResultViewState();
}

class _OcrResultViewState extends State<_OcrResultView> {
  final TextEditingController _titleController = TextEditingController(
    text: 'Ghi chú quét vở',
  );
  final TextEditingController _textController = TextEditingController();
  bool _showOriginalImage = false;
  bool _isImageExpanded = true;

  @override
  void dispose() {
    _titleController.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _copyText(BuildContext context, String text) async {
    if (text.trim().isEmpty) return;
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã sao chép văn bản vào bộ nhớ tạm'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayBytes = _showOriginalImage
        ? widget.image.originalBytes
        : widget.image.activeBytes;

    return Scaffold(
      appBar: AppBar(
        title: const Text('So sánh & Sửa văn bản'),
        actions: <Widget>[
          if (widget.image.isCropped)
            TextButton.icon(
              onPressed: () =>
                  setState(() => _showOriginalImage = !_showOriginalImage),
              icon: Icon(
                _showOriginalImage ? Icons.crop : Icons.image_outlined,
                size: 18,
              ),
              label: Text(_showOriginalImage ? 'Ảnh đã cắt' : 'Ảnh gốc'),
            ),
          IconButton(
            tooltip: _isImageExpanded ? 'Thu gọn ảnh' : 'Mở rộng ảnh',
            icon: Icon(
              _isImageExpanded ? Icons.expand_less : Icons.expand_more,
            ),
            onPressed: () =>
                setState(() => _isImageExpanded = !_isImageExpanded),
          ),
        ],
      ),
      body: BlocConsumer<OcrCubit, OcrState>(
        listener: (BuildContext context, OcrState state) {
          if (state.status == OcrStatus.success &&
              _textController.text != state.editedText &&
              state.editedText.isNotEmpty &&
              _textController.text.isEmpty) {
            _textController.text = state.editedText;
          }
          if (state.status == OcrStatus.saved) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Đã lưu ghi chú mới kèm ảnh gốc thành công'),
              ),
            );
            Navigator.of(context).pop<bool>(true);
          }
          if (state.status == OcrStatus.failure && state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: theme.colorScheme.error,
              ),
            );
          }
        },
        builder: (BuildContext context, OcrState state) {
          return Column(
            children: <Widget>[
              // Vùng 1: Ảnh trang vở để đối chiếu trực tiếp
              if (_isImageExpanded)
                Container(
                  height: 210,
                  width: double.infinity,
                  margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Stack(
                      children: <Widget>[
                        InteractiveViewer(
                          minScale: 1.0,
                          maxScale: 4.0,
                          child: Center(
                            child: Image.memory(
                              displayBytes,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        Positioned(
                          left: 8,
                          bottom: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _showOriginalImage
                                  ? 'Ảnh gốc (phóng to để đối chiếu)'
                                  : 'Ảnh trang vở (phóng to để đối chiếu)',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Vùng 2: Trạng thái xử lý / Cảnh báo ảnh mờ / Khung sửa văn bản
              Expanded(child: _buildBody(context, state)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, OcrState state) {
    final theme = Theme.of(context);

    if (state.isLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Đang nhận dạng chữ bằng ML Kit...'),
          ],
        ),
      );
    }

    if (state.isEmptyResult) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                Icons.blur_on_outlined,
                size: 56,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Không nhận dạng được chữ trong ảnh',
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Ảnh có thể bị mờ, thiếu sáng hoặc không có văn bản. '
                'Bạn có thể chụp/chọn lại ảnh rõ hơn hoặc tự nhập văn bản.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).pop<bool>(false),
                      icon: const Icon(Icons.camera_alt_outlined),
                      label: const Text('Chụp lại ảnh'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () =>
                          context.read<OcrCubit>().switchToManualEdit(),
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Nhập thủ công'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    if (state.status == OcrStatus.failure && state.result == null) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                Icons.error_outline,
                size: 48,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 12),
              Text(
                state.errorMessage ?? 'Đã xảy ra lỗi khi nhận dạng chữ',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () =>
                    context.read<OcrCubit>().recognizeImage(widget.image),
                icon: const Icon(Icons.refresh),
                label: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    final durationSec = ((state.result?.durationMs ?? 0) / 1000.0)
        .toStringAsFixed(1);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (state.result != null && state.result!.durationMs > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: <Widget>[
                  Icon(
                    Icons.check_circle_outline,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Nhận dạng xong trong ${durationSec}s — bạn có thể sửa chữ bên dưới',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

          TextFormField(
            controller: _titleController,
            enabled: !state.isSaving,
            decoration: const InputDecoration(
              labelText: 'Tiêu đề ghi chú',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 12),

          Expanded(
            child: TextFormField(
              controller: _textController,
              enabled: !state.isSaving,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              onChanged: (String value) =>
                  context.read<OcrCubit>().updateText(value),
              decoration: const InputDecoration(
                labelText: 'Nội dung văn bản (chạm để sửa lỗi OCR)',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(height: 12),

          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: state.editedText.trim().isEmpty
                      ? null
                      : () => _copyText(context, state.editedText),
                  icon: const Icon(Icons.copy_outlined),
                  label: const Text('Sao chép'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: state.canSave
                      ? () => context.read<OcrCubit>().saveAsNote(
                          title: _titleController.text,
                          image: widget.image,
                        )
                      : null,
                  icon: state.isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(
                    state.isSaving ? 'Đang lưu...' : 'Lưu thành ghi chú',
                  ),
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

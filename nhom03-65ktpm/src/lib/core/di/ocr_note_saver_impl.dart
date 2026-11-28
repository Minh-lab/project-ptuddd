import 'package:drift/drift.dart';

import '../../features/notes/domain/entities/note.dart';
import '../../features/notes/domain/repositories/note_repository.dart';
import '../../features/scan/domain/repositories/ocr_note_saver.dart';
import '../database/app_database.dart';
import '../database/note_attachments_dao.dart';

/// Cầu nối lưu kết quả OCR thành ghi chú mới kèm bản đính kèm ảnh gốc trong Drift.
class OcrNoteSaverImpl implements OcrNoteSaver {
  const OcrNoteSaverImpl({
    required this.noteRepository,
    required this.noteAttachmentsDao,
  });

  final NoteRepository noteRepository;
  final NoteAttachmentsDao noteAttachmentsDao;

  @override
  Future<String> saveAsNote({
    required String title,
    required String content,
    required String originalImagePath,
    String? croppedImagePath,
    String? ocrRawText,
  }) async {
    final now = DateTime.now();
    final noteId = 'ocr_${now.microsecondsSinceEpoch}';
    final resolvedTitle = title.trim().isEmpty
        ? 'Ghi chú quét vở'
        : title.trim();

    await noteRepository.createNote(
      Note(
        id: noteId,
        title: resolvedTitle,
        content: content,
        kind: NoteKind.note,
        createdAt: now,
        updatedAt: now,
      ),
    );

    await noteAttachmentsDao.insertAttachment(
      NoteAttachmentsCompanion.insert(
        id: 'att_${now.microsecondsSinceEpoch}',
        noteId: noteId,
        storagePath: originalImagePath,
        croppedPath: Value(croppedImagePath),
        ocrText: Value(ocrRawText ?? content),
        createdAt: Value(now),
      ),
    );

    return noteId;
  }
}

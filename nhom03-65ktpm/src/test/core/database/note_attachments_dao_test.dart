import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_note/core/database/app_database.dart';
import 'package:smart_note/core/database/note_attachments_dao.dart';
import 'package:smart_note/core/database/notes_dao.dart';
import 'package:smart_note/core/di/ocr_note_saver_impl.dart';
import 'package:smart_note/features/notes/data/repositories/note_repository_impl.dart';

void main() {
  late AppDatabase db;
  late NotesDao notesDao;
  late NoteAttachmentsDao attachmentsDao;
  late OcrNoteSaverImpl saver;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    notesDao = NotesDao(db);
    attachmentsDao = NoteAttachmentsDao(db);
    saver = OcrNoteSaverImpl(
      noteRepository: NoteRepositoryImpl(notesDao),
      noteAttachmentsDao: attachmentsDao,
    );
  });

  tearDown(() => db.close());

  test('OcrNoteSaverImpl lưu ghi chú mới kèm bản đính kèm ảnh gốc', () async {
    final noteId = await saver.saveAsNote(
      title: 'Lịch sử Việt Nam',
      content: 'Chiến thắng Bạch Đằng năm 938',
      originalImagePath: '/docs/scans/1/original.jpg',
      croppedImagePath: '/docs/scans/1/cropped.png',
      ocrRawText: 'Chiến thắng Bạch Đằng năm 938',
    );

    final note = await notesDao.findById(noteId);
    expect(note, isNotNull);
    expect(note!.title, equals('Lịch sử Việt Nam'));
    expect(note.content, equals('Chiến thắng Bạch Đằng năm 938'));

    final attachments = await attachmentsDao.getByNoteId(noteId);
    expect(attachments, hasLength(1));
    expect(attachments.first.storagePath, equals('/docs/scans/1/original.jpg'));
    expect(attachments.first.croppedPath, equals('/docs/scans/1/cropped.png'));
    expect(attachments.first.ocrText, equals('Chiến thắng Bạch Đằng năm 938'));
  });
}

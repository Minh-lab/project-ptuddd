import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_note/core/database/app_database.dart';
import 'package:smart_note/core/database/notes_dao.dart';
import 'package:smart_note/core/database/subjects_dao.dart';
import 'package:smart_note/core/error/failure.dart';
import 'package:smart_note/features/subjects/data/repositories/note_classification_repository_impl.dart';
import 'package:smart_note/features/subjects/data/repositories/subject_repository_impl.dart';
import 'package:smart_note/features/subjects/domain/entities/classified_note.dart';
import 'package:smart_note/features/subjects/domain/entities/subject.dart';

void main() {
  late AppDatabase database;
  late NotesDao notesDao;
  late NoteClassificationRepositoryImpl notes;
  late SubjectRepositoryImpl subjects;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    notesDao = NotesDao(database);
    notes = NoteClassificationRepositoryImpl(notesDao);
    subjects = SubjectRepositoryImpl(SubjectsDao(database));
  });

  tearDown(() async {
    await database.close();
  });

  Future<void> addNote(String id, {String tags = ''}) {
    return notesDao.insertNote(
      NotesCompanion.insert(id: id, title: Value(id), tags: Value(tags)),
    );
  }

  Future<ClassifiedNote> noteById(String id) async {
    final all = await notes.watchNotes().first;
    return all.firstWhere((ClassifiedNote n) => n.id == id);
  }

  group('NoteClassificationRepositoryImpl', () {
    test('gán và bỏ gán môn học, tag cho ghi chú', () async {
      await addNote('n1');

      await notes.classifyNote(
        'n1',
        subjectId: 'toan',
        tags: <String>['ôn thi', 'bài tập'],
      );
      var note = await noteById('n1');
      expect(note.subjectId, 'toan');
      expect(note.tags, <String>['ôn thi', 'bài tập']);

      await notes.classifyNote('n1', subjectId: null, tags: <String>[]);
      note = await noteById('n1');
      expect(note.subjectId, isNull);
      expect(note.tags, isEmpty);
    });

    test('phân loại ghi chú không tồn tại báo lỗi', () async {
      expect(
        () => notes.classifyNote('khong-co', subjectId: null, tags: <String>[]),
        throwsA(isA<DatabaseFailure>()),
      );
    });

    test('đổi tên tag trên mọi ghi chú và gộp tag trùng', () async {
      await addNote('n1', tags: 'on thi,bài tập');
      await addNote('n2', tags: 'on thi,ôn thi');
      await addNote('n3', tags: 'khác');

      await notes.renameTag('on thi', 'ôn thi');

      expect((await noteById('n1')).tags, <String>['ôn thi', 'bài tập']);
      expect((await noteById('n2')).tags, <String>['ôn thi']);
      expect((await noteById('n3')).tags, <String>['khác']);
    });

    test('xoá tag khỏi mọi ghi chú', () async {
      await addNote('n1', tags: 'ôn thi,bài tập');
      await addNote('n2', tags: 'ôn thi');

      await notes.deleteTag('ôn thi');

      expect((await noteById('n1')).tags, <String>['bài tập']);
      expect((await noteById('n2')).tags, isEmpty);
    });
  });

  group('SubjectRepositoryImpl', () {
    Subject subject(String id, String name) => Subject(
      id: id,
      name: name,
      color: '#43A047',
      createdAt: DateTime(2026, 11, 1),
      updatedAt: DateTime(2026, 11, 1),
    );

    test('thêm, sửa, xoá môn học', () async {
      await subjects.createSubject(subject('s1', 'Toan'));
      await subjects.updateSubject(subject('s1', 'Toán'));
      expect((await subjects.watchSubjects().first).single.name, 'Toán');

      await subjects.deleteSubject('s1');
      expect(await subjects.watchSubjects().first, isEmpty);
    });

    test('sửa hoặc xoá môn không tồn tại báo lỗi', () async {
      expect(
        () => subjects.updateSubject(subject('khong-co', 'X')),
        throwsA(isA<DatabaseFailure>()),
      );
      expect(
        () => subjects.deleteSubject('khong-co'),
        throwsA(isA<DatabaseFailure>()),
      );
    });
  });
}

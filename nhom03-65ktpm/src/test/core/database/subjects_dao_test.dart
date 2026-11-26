import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_note/core/database/app_database.dart';
import 'package:smart_note/core/database/notes_dao.dart';
import 'package:smart_note/core/database/subjects_dao.dart';

void main() {
  late AppDatabase database;
  late SubjectsDao dao;
  late NotesDao notesDao;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    dao = SubjectsDao(database);
    notesDao = NotesDao(database);
  });

  tearDown(() async {
    await database.close();
  });

  SubjectsCompanion newSubject(String id, String name, DateTime createdAt) {
    return SubjectsCompanion.insert(
      id: id,
      name: name,
      color: const Value('#2F6BFF'),
      createdAt: Value(createdAt),
      updatedAt: Value(createdAt),
    );
  }

  test('thêm và đọc lại môn học theo thứ tự tạo', () async {
    await dao.insertSubject(newSubject('s2', 'Ngữ văn', DateTime(2026, 11, 2)));
    await dao.insertSubject(newSubject('s1', 'Toán', DateTime(2026, 11, 1)));

    final rows = await dao.getAll();

    expect(rows.map((SubjectRow r) => r.name), <String>['Toán', 'Ngữ văn']);
    expect(rows.first.color, '#2F6BFF');
  });

  test('cập nhật tên môn học', () async {
    await dao.insertSubject(newSubject('s1', 'Toan', DateTime(2026, 11, 1)));

    final updated = await dao.updateSubject(
      's1',
      const SubjectsCompanion(name: Value('Toán')),
    );

    expect(updated, isTrue);
    expect((await dao.getAll()).single.name, 'Toán');
  });

  test('xoá mềm môn học và chuyển ghi chú về chưa phân loại', () async {
    await dao.insertSubject(newSubject('s1', 'Toán', DateTime(2026, 11, 1)));
    await notesDao.insertNote(
      NotesCompanion.insert(
        id: 'n1',
        title: const Value('Đạo hàm'),
        subjectId: const Value('s1'),
      ),
    );

    final deleted = await dao.softDeleteSubject('s1');

    expect(deleted, isTrue);
    expect(await dao.getAll(), isEmpty);
    expect((await notesDao.findById('n1'))!.subjectId, isNull);
  });

  test('xoá môn không tồn tại trả về false', () async {
    expect(await dao.softDeleteSubject('khong-co'), isFalse);
  });

  test('watchAll phát lại danh sách khi có môn mới', () async {
    final counts = dao
        .watchAll()
        .map((List<SubjectRow> rows) => rows.length)
        .asBroadcastStream();
    // Chờ lần phát đầu tiên (bảng rỗng) rồi mới thêm môn.
    expect(await counts.first, 0);

    final next = counts.first;
    await dao.insertSubject(newSubject('s1', 'Toán', DateTime(2026, 11, 1)));

    expect(await next, 1);
  });
}

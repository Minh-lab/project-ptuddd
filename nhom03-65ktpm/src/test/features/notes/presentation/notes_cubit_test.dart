import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_note/core/database/app_database.dart';
import 'package:smart_note/core/database/notes_dao.dart';
import 'package:smart_note/features/notes/data/repositories/note_repository_impl.dart';
import 'package:smart_note/features/notes/domain/entities/note.dart';
import 'package:smart_note/features/notes/domain/repositories/note_repository.dart';
import 'package:smart_note/features/notes/presentation/bloc/notes_cubit.dart';

void main() {
  late AppDatabase database;
  late NoteRepository repository;
  late NotesCubit cubit;
  var now = DateTime(2026, 11, 27, 9);

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    repository = NoteRepositoryImpl(NotesDao(database));
    now = DateTime(2026, 11, 27, 9);
    cubit = NotesCubit(repository, clock: () => now);
  });

  tearDown(() async {
    await cubit.close();
    await database.close();
  });

  test('mở app nhiều lần chỉ tạo một nhật ký cho ngày hiện tại', () async {
    await cubit.load();
    await cubit.load();

    final diaries = (await repository.getNotes())
        .where((Note note) => note.isDiary)
        .toList();
    expect(diaries, hasLength(1));
    expect(diaries.single.title, startsWith('Nhật ký '));
  });

  test(
    'các yêu cầu tạo đồng thời cho cùng ngày dùng chung một nhật ký',
    () async {
      final date = DateTime(2026, 11, 27);
      final notes = await Future.wait(<Future<Note>>[
        cubit.ensureDiaryForDate(date),
        cubit.ensureDiaryForDate(date),
      ]);

      expect(notes[0].id, notes[1].id);
      expect(
        (await repository.getNotes()).where((Note note) => note.isDiary),
        hasLength(1),
      );
    },
  );

  test('tạo và cập nhật ghi chú lưu thời gian cập nhật mới', () async {
    final note = await cubit.createNote(title: 'Toán', content: 'Bản nháp');
    final before = note.updatedAt;

    now = now.add(const Duration(minutes: 1));
    await cubit.updateNote(note, content: 'Đã lưu');

    final saved = await repository.findById(note.id);
    expect(saved?.content, 'Đã lưu');
    expect(saved!.updatedAt.isAfter(before), isTrue);
  });
}

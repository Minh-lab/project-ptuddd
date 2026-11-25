import 'package:flutter_test/flutter_test.dart';
import 'package:smart_note/features/notes/domain/entities/note.dart';
import 'package:smart_note/features/notes/domain/usecases/note_search.dart';

void main() {
  const search = NoteSearch();
  final now = DateTime(2026, 11, 25);
  final titleMatch = Note(
    id: 'title',
    title: 'Ghi chú tiếng Việt',
    content: 'Bài học',
    kind: NoteKind.note,
    createdAt: now,
    updatedAt: now,
  );
  final contentMatch = Note(
    id: 'content',
    title: 'Sinh học',
    content: 'Nội dung có từ khóa đặc biệt',
    kind: NoteKind.note,
    createdAt: now,
    updatedAt: now,
  );
  final otherNote = Note(
    id: 'other',
    title: 'Vật lý',
    content: 'Chuyển động',
    kind: NoteKind.note,
    createdAt: now,
    updatedAt: now,
  );
  final notes = <Note>[titleMatch, contentMatch, otherNote];

  test('tìm trong tiêu đề và nội dung không phân biệt dấu/hoa thường', () {
    expect(search(notes, 'ghi chu'), <Note>[titleMatch]);
    expect(search(notes, 'TU KHOA'), <Note>[contentMatch]);
    expect(search(notes, 'VẬT LÝ'), <Note>[otherNote]);
  });

  test(
    'truy vấn rỗng trả toàn bộ và truy vấn không khớp trả danh sách rỗng',
    () {
      expect(search(notes, '  '), orderedEquals(notes));
      expect(search(notes, 'khong co ket qua'), isEmpty);
    },
  );

  test('trả các khoảng tô sáng theo chỉ số chuỗi gốc có dấu', () {
    expect(
      search
          .highlightRanges('Ghi chú ghi CHÚ', 'ghi chu')
          .map((NoteSearchRange range) => '${range.start}:${range.end}'),
      orderedEquals(<String>['0:7', '8:15']),
    );
  });

  test('tô sáng cả dấu kết hợp Unicode trong chuỗi gốc', () {
    expect(
      search
          .highlightRanges('chu\u0301', 'chu')
          .map((NoteSearchRange range) => '${range.start}:${range.end}'),
      orderedEquals(<String>['0:4']),
    );
  });
}

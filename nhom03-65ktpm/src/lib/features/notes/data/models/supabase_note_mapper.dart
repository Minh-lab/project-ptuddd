import '../../domain/entities/note.dart';

class SupabaseNoteMapper {
  const SupabaseNoteMapper._();

  static Note fromRow(Map<String, dynamic> row) {
    final rawTags = row['tags'];
    if (rawTags is! List) {
      throw const FormatException('Supabase trả về tags không hợp lệ.');
    }
    final rawSubjectId = row['subject_id'];
    if (rawSubjectId != null && rawSubjectId is! String) {
      throw const FormatException('Supabase trả về subject_id không hợp lệ.');
    }

    return Note(
      id: _stringField(row, 'id'),
      title: _stringField(row, 'title'),
      content: _stringField(row, 'content'),
      kind: NoteKind.fromStorage(_stringField(row, 'kind')),
      createdAt: DateTime.parse(_stringField(row, 'created_at')),
      updatedAt: DateTime.parse(_stringField(row, 'updated_at')),
      subjectId: rawSubjectId as String?,
      tags: rawTags.whereType<String>().toList(),
    );
  }

  static String _stringField(Map<String, dynamic> row, String name) {
    final value = row[name];
    if (value is String) return value;
    throw FormatException('Supabase thiếu trường "$name".');
  }
}

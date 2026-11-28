import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/entities/classified_note.dart';
import '../../domain/entities/subject.dart';

/// Chuyển đổi giữa model Drift ([SubjectRow], [NoteRow]) và entity của domain.
extension SubjectRowMapper on SubjectRow {
  Subject toEntity() {
    return Subject(
      id: id,
      name: name,
      color: color,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

extension SubjectEntityMapper on Subject {
  /// Dùng cho lệnh insert.
  SubjectsCompanion toCompanion() {
    return SubjectsCompanion.insert(
      id: id,
      name: name,
      color: Value<String?>(color),
      createdAt: Value<DateTime>(createdAt),
      updatedAt: Value<DateTime>(updatedAt),
    );
  }

  /// Dùng cho lệnh update (không đổi `createdAt`).
  SubjectsCompanion toUpdateCompanion() {
    return SubjectsCompanion(
      name: Value<String>(name),
      color: Value<String?>(color),
      updatedAt: Value<DateTime>(updatedAt),
    );
  }
}

extension ClassifiedNoteRowMapper on NoteRow {
  ClassifiedNote toClassifiedNote() {
    return ClassifiedNote(
      id: id,
      title: title,
      subjectId: subjectId,
      tags: parseStoredTags(tags),
    );
  }
}

/// Cột `notes.tags` lưu tag phân tách bằng dấu phẩy.
List<String> parseStoredTags(String stored) {
  if (stored.isEmpty) return const <String>[];
  return stored
      .split(',')
      .map((String t) => t.trim())
      .where((String t) => t.isNotEmpty)
      .toList();
}

String tagsToStorage(List<String> tags) => tags.join(',');

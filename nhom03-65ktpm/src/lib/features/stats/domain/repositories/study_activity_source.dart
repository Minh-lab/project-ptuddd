import '../entities/study_note.dart';

/// Nguồn ghi chú cho thống kê và streak.
///
/// Hiện thực nằm ở `core/di` (bọc `NoteRepository`), nhờ vậy feature này
/// không import feature notes.
abstract interface class StudyActivitySource {
  /// Ghi chú và nhật ký chưa bị xoá của tài khoản hiện tại.
  Stream<List<StudyNote>> watchStudyNotes();
}

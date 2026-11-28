import '../entities/subject.dart';

/// Hợp đồng truy cập môn học; hiện thực (Drift, sau này Supabase) nằm ở `data/`.
abstract interface class SubjectRepository {
  /// Theo dõi các môn chưa bị xoá, theo thứ tự tạo.
  Stream<List<Subject>> watchSubjects();

  Future<void> createSubject(Subject subject);

  Future<void> updateSubject(Subject subject);

  /// Xoá mềm; các ghi chú thuộc môn này trở thành "chưa phân loại".
  Future<void> deleteSubject(String id);
}

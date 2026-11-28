import '../../../../core/database/app_database.dart';
import '../../../../core/database/subjects_dao.dart';
import '../../../../core/error/failure.dart';
import '../../domain/entities/subject.dart';
import '../../domain/repositories/subject_repository.dart';
import '../models/subject_mapper.dart';

/// Hiện thực [SubjectRepository] trên cache cục bộ (Drift).
class SubjectRepositoryImpl implements SubjectRepository {
  SubjectRepositoryImpl(this._dao, {this.onChanged});

  final SubjectsDao _dao;
  final void Function()? onChanged;

  @override
  Stream<List<Subject>> watchSubjects() {
    onChanged?.call();
    return _dao.watchAll().map(
      (List<SubjectRow> rows) =>
          rows.map((SubjectRow row) => row.toEntity()).toList(),
    );
  }

  @override
  Future<void> createSubject(Subject subject) async {
    try {
      await _dao.insertSubject(subject.toCompanion());
      onChanged?.call();
    } on Object catch (error) {
      throw DatabaseFailure('Không tạo được môn học: $error');
    }
  }

  @override
  Future<void> updateSubject(Subject subject) async {
    try {
      final updated = await _dao.updateSubject(
        subject.id,
        subject.toUpdateCompanion(),
      );
      if (!updated) {
        throw const DatabaseFailure('Không tìm thấy môn học để cập nhật');
      }
      onChanged?.call();
    } on Failure {
      rethrow;
    } on Object catch (error) {
      throw DatabaseFailure('Không cập nhật được môn học: $error');
    }
  }

  @override
  Future<void> deleteSubject(String id) async {
    try {
      final deleted = await _dao.softDeleteSubject(id);
      if (!deleted) {
        throw const DatabaseFailure('Không tìm thấy môn học để xoá');
      }
      onChanged?.call();
    } on Failure {
      rethrow;
    } on Object catch (error) {
      throw DatabaseFailure('Không xoá được môn học: $error');
    }
  }
}

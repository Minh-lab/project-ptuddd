// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subjects_dao.dart';

// ignore_for_file: type=lint
mixin _$SubjectsDaoMixin on DatabaseAccessor<AppDatabase> {
  $SubjectsTable get subjects => attachedDatabase.subjects;
  $NotesTable get notes => attachedDatabase.notes;
  SubjectsDaoManager get managers => SubjectsDaoManager(this);
}

class SubjectsDaoManager {
  final _$SubjectsDaoMixin _db;
  SubjectsDaoManager(this._db);
  $$SubjectsTableTableManager get subjects =>
      $$SubjectsTableTableManager(_db.attachedDatabase, _db.subjects);
  $$NotesTableTableManager get notes =>
      $$NotesTableTableManager(_db.attachedDatabase, _db.notes);
}

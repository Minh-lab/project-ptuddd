// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'note_attachments_dao.dart';

// ignore_for_file: type=lint
mixin _$NoteAttachmentsDaoMixin on DatabaseAccessor<AppDatabase> {
  $NoteAttachmentsTable get noteAttachments => attachedDatabase.noteAttachments;
  NoteAttachmentsDaoManager get managers => NoteAttachmentsDaoManager(this);
}

class NoteAttachmentsDaoManager {
  final _$NoteAttachmentsDaoMixin _db;
  NoteAttachmentsDaoManager(this._db);
  $$NoteAttachmentsTableTableManager get noteAttachments =>
      $$NoteAttachmentsTableTableManager(
        _db.attachedDatabase,
        _db.noteAttachments,
      );
}

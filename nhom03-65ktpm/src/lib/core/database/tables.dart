import 'package:drift/drift.dart';

/// Bảng ghi chú dùng chung cho ghi chú thường và nhật ký hằng ngày.
///
/// `kind` phân biệt hai loại (`note` / `diary`); `deletedAt` cho phép xoá mềm
/// để sau này đồng bộ với Supabase mà không mất dữ liệu.
@DataClassName('NoteRow')
class Notes extends Table {
  TextColumn get id => text()();

  TextColumn get title => text().withDefault(const Constant(''))();

  TextColumn get content => text().withDefault(const Constant(''))();

  TextColumn get subjectId => text().nullable()();

  /// Danh sách tag lưu dạng chuỗi phân tách bằng dấu phẩy.
  TextColumn get tags => text().withDefault(const Constant(''))();

  /// `note` hoặc `diary`.
  TextColumn get kind => text().withDefault(const Constant('note'))();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('QuizScoreRow')
class QuizScores extends Table {
  TextColumn get id => text()();
  TextColumn get noteId => text()();
  TextColumn get noteTitle => text().withDefault(const Constant(''))();
  IntColumn get correctAnswers => integer()();
  IntColumn get totalQuestions => integer()();
  DateTimeColumn get completedAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Bảng đính kèm ảnh quét vở và văn bản OCR gắn với từng ghi chú.
@DataClassName('NoteAttachmentRow')
class NoteAttachments extends Table {
  TextColumn get id => text()();

  TextColumn get noteId => text()();

  /// Đường dẫn tệp ảnh gốc trên thiết bị hoặc đường dẫn Storage.
  TextColumn get storagePath => text()();

  /// Đường dẫn tệp ảnh đã cắt (nếu có).
  TextColumn get croppedPath => text().nullable()();

  IntColumn get pageOrder => integer().withDefault(const Constant(0))();

  TextColumn get ocrText => text().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

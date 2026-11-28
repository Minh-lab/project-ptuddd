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

/// Nhắc nhở học tập theo ghi chú (#10).
///
/// Chỉ lưu trên máy vì thông báo do từng máy tự lên lịch; xem
/// `docs/co_so_du_lieu.md` mục 7.
@DataClassName('ReminderRow')
class Reminders extends Table {
  TextColumn get id => text()();

  TextColumn get noteId => text()();

  /// `once`, `daily` hoặc `weekly`.
  TextColumn get repeatRule => text()();

  /// Một lần: ngày giờ báo. Hằng ngày/theo thứ: chỉ dùng giờ và phút.
  DateTimeColumn get remindAt => dateTime()();

  /// Thứ được báo (1 = thứ Hai … 7 = Chủ nhật), phân tách bằng dấu phẩy.
  TextColumn get weekdays => text().withDefault(const Constant(''))();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

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

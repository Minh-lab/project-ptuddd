import 'package:drift/drift.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../features/auth/data/datasources/remote/firebase_auth_data_source.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/notes/data/repositories/note_repository_impl.dart';
import '../../features/notes/domain/repositories/note_repository.dart';
import '../../features/scan/data/repositories/ocr_repository_impl.dart';
import '../../features/scan/data/repositories/scan_repository_impl.dart';
import '../../features/scan/domain/repositories/ocr_note_saver.dart';
import '../../features/scan/domain/repositories/ocr_repository.dart';
import '../../features/scan/domain/repositories/scan_repository.dart';
import '../database/app_database.dart';
import '../database/note_attachments_dao.dart';
import '../database/notes_dao.dart';
import '../database/quiz_scores_dao.dart';
import 'ocr_note_saver_impl.dart';

/// Nơi duy nhất khởi tạo database và repository.
///
/// `main.dart` tạo một instance rồi truyền xuống widget tree; test có thể truyền
/// [executor] là `NativeDatabase.memory()` để chạy trong bộ nhớ và [authRepository]
/// là bản giả để không cần Firebase.
class AppDependencies {
  AppDependencies._({
    required this.database,
    required this.notesDao,
    required this.noteAttachmentsDao,
    required this.noteRepository,
    required this.authRepository,
    required this.scanRepository,
    required this.ocrRepository,
    required this.ocrNoteSaver,
    required this.quizScoresDao,
  });

  factory AppDependencies.create({
    QueryExecutor? executor,
    AuthRepository? authRepository,
    ScanRepository? scanRepository,
    OcrRepository? ocrRepository,
  }) {
    final database = AppDatabase(executor);
    final notesDao = NotesDao(database);
    final noteAttachmentsDao = NoteAttachmentsDao(database);
    final noteRepository = NoteRepositoryImpl(notesDao);
    final quizScoresDao = QuizScoresDao(database);
    return AppDependencies._(
      database: database,
      notesDao: notesDao,
      noteAttachmentsDao: noteAttachmentsDao,
      noteRepository: noteRepository,
      authRepository: authRepository ?? _firebaseAuthRepository(),
      scanRepository: scanRepository ?? ScanRepositoryImpl(),
      ocrRepository: ocrRepository ?? OcrRepositoryImpl(),
      ocrNoteSaver: OcrNoteSaverImpl(
        noteRepository: noteRepository,
        noteAttachmentsDao: noteAttachmentsDao,
      ),
      quizScoresDao: quizScoresDao,
    );
  }

  /// Firebase phải được khởi tạo trước ([FirebaseBootstrap.initialize]) thì mới
  /// lấy được `FirebaseAuth.instance`.
  static AuthRepository _firebaseAuthRepository() {
    return AuthRepositoryImpl(FirebaseAuthDataSource(FirebaseAuth.instance));
  }

  final AppDatabase database;
  final NotesDao notesDao;
  final NoteAttachmentsDao noteAttachmentsDao;
  final NoteRepository noteRepository;
  final AuthRepository authRepository;
  final ScanRepository scanRepository;
  final OcrRepository ocrRepository;
  final OcrNoteSaver ocrNoteSaver;
  final QuizScoresDao quizScoresDao;

  Future<void> dispose() => database.close();
}

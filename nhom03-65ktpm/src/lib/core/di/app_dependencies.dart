import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../features/auth/data/datasources/remote/firebase_auth_data_source.dart';
import '../../features/auth/data/repositories/development_auth_repository.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/notes/data/repositories/development_note_repository.dart';
import '../../features/notes/data/repositories/note_repository_impl.dart';
import '../../features/notes/domain/repositories/note_repository.dart';
import '../database/app_database.dart';
import '../database/notes_dao.dart';

/// Nơi duy nhất khởi tạo database và repository.
///
/// `main.dart` tạo một instance rồi truyền xuống widget tree; test có thể truyền
/// [executor] là `NativeDatabase.memory()` để chạy trong bộ nhớ và [authRepository]
/// là bản giả để không cần Firebase.
class AppDependencies {
  AppDependencies._({
    required this.database,
    required this.notesDao,
    required this.noteRepository,
    required this.authRepository,
    required this.isDevelopmentMode,
  });

  factory AppDependencies.create({
    QueryExecutor? executor,
    AuthRepository? authRepository,
    NoteRepository? noteRepository,
    bool developmentMode = false,
  }) {
    final database = AppDatabase(
      executor ?? (developmentMode ? NativeDatabase.memory() : null),
    );
    final notesDao = NotesDao(database);
    return AppDependencies._(
      database: database,
      notesDao: notesDao,
      noteRepository:
          noteRepository ??
          (developmentMode
              ? DevelopmentNoteRepository()
              : NoteRepositoryImpl(notesDao)),
      authRepository:
          authRepository ??
          (developmentMode
              ? DevelopmentAuthRepository()
              : _firebaseAuthRepository()),
      isDevelopmentMode: developmentMode,
    );
  }

  /// Firebase phải được khởi tạo trước ([FirebaseBootstrap.initialize]) thì mới
  /// lấy được `FirebaseAuth.instance`.
  static AuthRepository _firebaseAuthRepository() {
    return AuthRepositoryImpl(FirebaseAuthDataSource(FirebaseAuth.instance));
  }

  final AppDatabase database;
  final NotesDao notesDao;
  final NoteRepository noteRepository;
  final AuthRepository authRepository;
  final bool isDevelopmentMode;

  Future<void> dispose() => database.close();
}

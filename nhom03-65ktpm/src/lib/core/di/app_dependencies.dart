import 'package:drift/drift.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/data/datasources/remote/firebase_auth_data_source.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/notes/data/repositories/note_repository_impl.dart';
import '../../features/notes/data/datasources/remote/supabase_note_data_source.dart';
import '../../features/notes/data/repositories/supabase_note_repository.dart';
import '../../features/notes/data/repositories/unavailable_note_share_repository.dart';
import '../../features/notes/domain/repositories/note_repository.dart';
import '../../features/notes/domain/repositories/note_share_repository.dart';
import '../database/app_database.dart';
import '../database/notes_dao.dart';
import '../database/quiz_scores_dao.dart';

/// Nơi duy nhất khởi tạo database và repository.
///
/// `main.dart` tạo một instance rồi truyền xuống widget tree; test có thể truyền
/// [executor] là `NativeDatabase.memory()` để chạy trong bộ nhớ và [authRepository]
/// là bản giả để không cần Firebase.
class AppDependencies {
  AppDependencies._({
    required this.database,
    required this.notesDao,
    required this.noteRepositoryForUser,
    required this.noteShareRepository,
    required this.authRepository,
    required this.quizScoresDao,
  });

  factory AppDependencies.create({
    QueryExecutor? executor,
    AuthRepository? authRepository,
    NoteShareRepository? noteShareRepository,
    SupabaseClient? supabaseClient,
    String? Function()? currentUserId,
  }) {
    final database = AppDatabase(executor);
    final notesDao = NotesDao(database);
    final quizScoresDao = QuizScoresDao(database);
    final resolveCurrentUserId =
        currentUserId ?? () => FirebaseAuth.instance.currentUser?.uid;
    final remoteDataSource = supabaseClient == null
        ? null
        : SupabaseNoteDataSource(supabaseClient);
    return AppDependencies._(
      database: database,
      notesDao: notesDao,
      noteRepositoryForUser: (String userId) {
        final localNoteRepository = NoteRepositoryImpl(notesDao, userId);
        if (remoteDataSource == null) return localNoteRepository;
        return SupabaseNoteRepository(
          localNoteRepository,
          notesDao,
          remoteDataSource,
          () => resolveCurrentUserId() == userId ? userId : null,
        );
      },
      noteShareRepository:
          noteShareRepository ?? UnavailableNoteShareRepository(),
      authRepository: authRepository ?? _firebaseAuthRepository(),
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
  final NoteRepository Function(String userId) noteRepositoryForUser;
  final NoteShareRepository noteShareRepository;
  final AuthRepository authRepository;
  final QuizScoresDao quizScoresDao;

  Future<void> dispose() => database.close();
}

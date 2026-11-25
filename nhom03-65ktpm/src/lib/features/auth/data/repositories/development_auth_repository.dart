import 'dart:async';

import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';

/// Phiên giả chỉ dùng trong Development Mode, không gọi Firebase.
class DevelopmentAuthRepository implements AuthRepository {
  DevelopmentAuthRepository()
    : _currentUser = const AppUser(
        id: 'smartnote-development-user',
        email: 'developer@smartnote.local',
        displayName: 'Development User',
      );

  final StreamController<AppUser?> _controller =
      StreamController<AppUser?>.broadcast();

  AppUser? _currentUser;

  @override
  AppUser? get currentUser => _currentUser;

  @override
  Stream<AppUser?> authStateChanges() async* {
    yield _currentUser;
    yield* _controller.stream;
  }

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    return _setDevelopmentUser(email: email);
  }

  @override
  Future<AppUser> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    return _setDevelopmentUser(email: email, displayName: displayName);
  }

  @override
  Future<void> signOut() async {
    _currentUser = null;
    _controller.add(null);
  }

  AppUser _setDevelopmentUser({required String email, String? displayName}) {
    final user = AppUser(
      id: 'smartnote-development-user',
      email: email.trim(),
      displayName: displayName,
    );
    _currentUser = user;
    _controller.add(user);
    return user;
  }

  Future<void> dispose() => _controller.close();
}

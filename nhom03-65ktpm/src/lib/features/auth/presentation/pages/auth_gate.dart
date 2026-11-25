import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/app_dependencies.dart';
import '../../../notes/presentation/bloc/notes_cubit.dart';
import '../../../notes/presentation/pages/notes_page.dart';
import '../bloc/auth_cubit.dart';
import '../bloc/auth_state.dart';
import '../widgets/logout_button.dart';
import 'login_page.dart';

/// Cổng điều hướng dựa trên phiên đăng nhập:
///
/// - `unknown` → màn chờ (Firebase đang khôi phục phiên),
/// - `authenticated` → màn hình chính,
/// - `unauthenticated` → màn đăng nhập.
///
/// Nhờ vậy người dùng đã đăng nhập được vào thẳng app, còn người chưa đăng
/// nhập không mở được màn hình chính.
class AuthGate extends StatelessWidget {
  const AuthGate({required this.dependencies, super.key});

  final AppDependencies dependencies;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (BuildContext context, AuthState state) {
        if (state.isUnknown) {
          return const _SplashPage();
        }
        if (state.isAuthenticated) {
          return BlocProvider<NotesCubit>(
            create: (_) => NotesCubit(dependencies.noteRepository)..load(),
            child: NotesPage(
              actions: <Widget>[
                if (dependencies.isDevelopmentMode)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Center(
                      child: Text(
                        'DEV · MOCK',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                const LogoutButton(),
              ],
            ),
          );
        }
        return const LoginPage();
      },
    );
  }
}

class _SplashPage extends StatelessWidget {
  const _SplashPage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('SmartNote'),
          ],
        ),
      ),
    );
  }
}

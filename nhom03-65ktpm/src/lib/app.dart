import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/di/app_dependencies.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/bloc/auth_cubit.dart';
import 'features/auth/presentation/pages/auth_gate.dart';
import 'features/notes/presentation/pages/shared_note_page.dart';

/// Widget gốc của SmartNote.
class SmartNoteApp extends StatefulWidget {
  const SmartNoteApp({
    required this.dependencies,
    this.initialLink,
    this.linkStream,
    super.key,
  });

  final AppDependencies dependencies;
  final Uri? initialLink;
  final Stream<Uri>? linkStream;

  @override
  State<SmartNoteApp> createState() => _SmartNoteAppState();
}

class _SmartNoteAppState extends State<SmartNoteApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  StreamSubscription<Uri>? _linkSubscription;
  String? _lastOpenedShareId;

  @override
  void initState() {
    super.initState();
    _linkSubscription = widget.linkStream?.listen(
      _handleLink,
      onError: (Object error, StackTrace stackTrace) {
        FlutterError.reportError(
          FlutterErrorDetails(
            exception: error,
            stack: stackTrace,
            library: 'SmartNote app links',
          ),
        );
      },
    );
    final initialLink = widget.initialLink;
    if (initialLink != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleLink(initialLink);
      });
    }
  }

  void _handleLink(Uri uri) {
    final shareId = _shareIdFromUri(uri);
    if (shareId == null || shareId == _lastOpenedShareId) return;
    _lastOpenedShareId = shareId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final navigator = _navigatorKey.currentState;
      if (navigator == null) {
        _lastOpenedShareId = null;
        return;
      }
      unawaited(
        navigator
            .push<void>(
              MaterialPageRoute<void>(
                builder: (_) => SharedNoteGate(
                  dependencies: widget.dependencies,
                  shareId: shareId,
                ),
              ),
            )
            .whenComplete(() {
              if (_lastOpenedShareId == shareId) {
                _lastOpenedShareId = null;
              }
            }),
      );
    });
  }

  String? _shareIdFromUri(Uri uri) {
    if (uri.scheme == 'smartnote' &&
        uri.host == 'share' &&
        uri.pathSegments.length == 1) {
      return uri.pathSegments.single;
    }
    return uri.queryParameters['share'];
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // AuthCubit được provide **trên** MaterialApp để mọi route (kể cả route
    // được push sau này như màn đăng ký) đều đọc được; nếu đặt bên trong
    // `home:` thì route mới sẽ không thấy provider.
    return BlocProvider<AuthCubit>(
      create: (BuildContext context) =>
          AuthCubit(widget.dependencies.authRepository)..start(),
      child: MaterialApp(
        navigatorKey: _navigatorKey,
        title: 'SmartNote',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        home: AuthGate(dependencies: widget.dependencies),
      ),
    );
  }
}

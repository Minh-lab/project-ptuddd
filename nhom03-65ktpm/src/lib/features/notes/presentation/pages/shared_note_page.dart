import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/app_dependencies.dart';
import '../../../../core/error/failure.dart';
import '../../../auth/presentation/bloc/auth_cubit.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../../domain/entities/note.dart';
import '../../domain/repositories/note_share_repository.dart';

class SharedNoteGate extends StatelessWidget {
  const SharedNoteGate({
    required this.dependencies,
    required this.shareId,
    super.key,
  });

  final AppDependencies dependencies;
  final String shareId;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        if (state.isUnknown) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final user = state.user;
        if (user == null) return const LoginPage();
        return SharedNotePage(
          repository: dependencies.noteShareRepository,
          shareId: shareId,
          recipientId: user.id,
        );
      },
    );
  }
}

class SharedNotePage extends StatefulWidget {
  const SharedNotePage({
    required this.repository,
    required this.shareId,
    required this.recipientId,
    super.key,
  });

  final NoteShareRepository repository;
  final String shareId;
  final String recipientId;

  @override
  State<SharedNotePage> createState() => _SharedNotePageState();
}

class _SharedNotePageState extends State<SharedNotePage> {
  late final Future<Note> _noteFuture;

  @override
  void initState() {
    super.initState();
    _noteFuture = widget.repository.openSharedNote(
      shareId: widget.shareId,
      recipientId: widget.recipientId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ghi chú được chia sẻ')),
      body: FutureBuilder<Note>(
        future: _noteFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            final error = snapshot.error;
            final message = error is Failure ? error.message : '$error';
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return _ReadOnlyNote(note: snapshot.data!);
        },
      ),
    );
  }
}

class _ReadOnlyNote extends StatelessWidget {
  const _ReadOnlyNote({required this.note});

  final Note note;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(24),
      children: <Widget>[
        Text(note.displayTitle, style: theme.textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(
          note.isDiary ? 'Nhật ký' : 'Ghi chú',
          style: theme.textTheme.labelLarge,
        ),
        if (note.tags.isNotEmpty) ...<Widget>[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: note.tags.map((tag) => Chip(label: Text(tag))).toList(),
          ),
        ],
        const Divider(height: 32),
        SelectableText(
          note.content,
          style: theme.textTheme.bodyLarge?.copyWith(height: 1.6),
        ),
      ],
    );
  }
}

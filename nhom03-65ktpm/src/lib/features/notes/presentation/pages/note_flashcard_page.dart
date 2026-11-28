import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../domain/entities/note.dart';

class NoteFlashcardPage extends StatefulWidget {
  const NoteFlashcardPage({required this.note, super.key});

  final Note note;

  @override
  State<NoteFlashcardPage> createState() => _NoteFlashcardPageState();
}

class _NoteFlashcardPageState extends State<NoteFlashcardPage> {
  bool _showContent = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppScaffold(
      title: 'Ôn tập / Flashcard',
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _showContent
                        ? 'Nội dung'
                        : 'Ghi nhớ nội dung của ghi chú này',
                    style: theme.textTheme.labelLarge,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SelectableText(
                    _showContent
                        ? widget.note.content
                        : widget.note.displayTitle,
                    style: _showContent
                        ? theme.textTheme.bodyLarge
                        : theme.textTheme.headlineSmall,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppPrimaryButton(
            label: _showContent ? 'Hiện tiêu đề' : 'Lật để xem nội dung',
            onPressed: () => setState(() => _showContent = !_showContent),
          ),
        ],
      ),
    );
  }
}

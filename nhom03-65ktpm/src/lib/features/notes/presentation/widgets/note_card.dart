import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/tag_chip.dart';
import '../../domain/entities/note.dart';

class NoteCard extends StatelessWidget {
  const NoteCard({
    required this.note,
    this.onTap,
    this.onLongPress,
    this.selected = false,
    this.compact = false,
    this.hasQuiz = false,
    super.key,
  });

  final Note note;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool selected;
  final bool compact;
  final bool hasQuiz;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;
    final tags = note.tags.where((tag) => tag.trim().isNotEmpty).toList();
    final label = tags.isNotEmpty
        ? tags.first
        : note.isDiary
        ? NotesTopic.diary.label
        : NotesTopic.other.label;
    final topic = NotesTopic.fromLabel(label);
    final orange = dark && topic == NotesTopic.physics;
    final cobalt = !dark && topic == NotesTopic.math;
    final titleColor = switch ((orange, cobalt)) {
      (true, _) => NotesColors.physicsInk,
      (_, true) => NotesColors.white,
      _ => scheme.onSurface,
    };
    final labelColor = orange ? titleColor : topic.labelColor(dark);
    final preview = note.content.trim().replaceAll(RegExp(r'\s+'), ' ');
    final previewColor = switch ((dark, orange, cobalt)) {
      (true, false, _) => NotesColors.cardText,
      (_, true, _) => titleColor,
      (_, _, true) => NotesColors.blue50,
      _ => NotesColors.slate700,
    };
    final dateColor = dark && !orange ? NotesColors.cardDate : previewColor;

    return Card.filled(
      margin: EdgeInsets.zero,
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      color: topic.card(dark),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(NotesLayout.cardRadius),
        side: selected
            ? BorderSide(color: labelColor, width: 2)
            : BorderSide.none,
      ),
      child: Ink(
        decoration: orange
            ? const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: NotesColors.physicsGradient,
                ),
              )
            : null,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          child: Padding(
            padding: const EdgeInsets.all(NotesLayout.cardPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: compact ? MainAxisSize.max : MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        compact
                            ? label
                            : (note.isDiary
                                  ? NotesTopic.diary.label
                                  : NotesTopic.other.label),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: labelColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Icon(
                      selected ? Icons.check_circle : topic.icon,
                      size: 18,
                      color: labelColor,
                    ),
                  ],
                ),
                const SizedBox(height: NotesLayout.cardTitleTop),
                Text(
                  note.displayTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: titleColor,
                  ),
                ),
                if (preview.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    preview,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: previewColor,
                    ),
                  ),
                ],
                if (compact)
                  const Spacer()
                else
                  const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _updatedAt,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: dateColor,
                        ),
                      ),
                    ),
                    if (hasQuiz)
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: dark
                              ? NotesColors.quizBadge
                              : NotesColors.blue50,
                          borderRadius: BorderRadius.circular(
                            NotesLayout.badgeRadius,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: NotesLayout.badgePadding,
                          ),
                          child: Text(
                            'AI Quiz',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: dark
                                  ? NotesColors.text
                                  : NotesColors.blue700,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                if (!compact && tags.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.xs,
                    children: tags
                        .take(3)
                        .map((tag) => TagChip(label: tag))
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String get _updatedAt {
    final date = note.updatedAt.toLocal();
    String two(int value) => value.toString().padLeft(2, '0');
    final day = '${two(date.day)}/${two(date.month)}';
    return compact ? day : '$day ${two(date.hour)}:${two(date.minute)}';
  }
}

import 'package:flutter/material.dart';

import '../../domain/entities/note.dart';

/// Một dòng ghi chú trong danh sách.
class NoteTile extends StatelessWidget {
  const NoteTile({
    required this.note,
    this.selected = false,
    this.selectionMode = false,
    this.onTap,
    this.onLongPress,
    super.key,
  });

  final Note note;
  final bool selected;
  final bool selectionMode;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final preview = note.content.trim().replaceAll('\n', ' ');

    return ListTile(
      selected: selected,
      onTap: onTap,
      onLongPress: onLongPress,
      leading: Icon(
        selected
            ? Icons.check_circle
            : note.isDiary
            ? Icons.event_note_outlined
            : Icons.sticky_note_2_outlined,
      ),
      title: Text(
        note.displayTitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.titleMedium,
      ),
      subtitle: preview.isEmpty
          ? Text('Chưa có nội dung', style: theme.textTheme.bodySmall)
          : Text(preview, maxLines: 2, overflow: TextOverflow.ellipsis),
      trailing: Text(
        _formatUpdatedAt(note.updatedAt),
        style: theme.textTheme.labelSmall,
      ),
    );
  }

  String _formatUpdatedAt(DateTime value) {
    final local = value.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(local.day)}/${two(local.month)} ${two(local.hour)}:${two(local.minute)}';
  }
}

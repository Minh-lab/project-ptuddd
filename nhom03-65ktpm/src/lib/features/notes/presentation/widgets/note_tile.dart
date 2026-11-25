import 'package:flutter/material.dart';

import '../../domain/entities/note.dart';
import '../../domain/services/note_search.dart';

/// Một dòng ghi chú trong danh sách.
class NoteTile extends StatelessWidget {
  const NoteTile({
    required this.note,
    this.searchQuery = '',
    this.selected = false,
    this.selectionMode = false,
    this.onTap,
    this.onLongPress,
    this.onShare,
    super.key,
  });

  final Note note;
  final String searchQuery;
  final bool selected;
  final bool selectionMode;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onShare;

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
      title: Text.rich(
        _highlightedSpan(note.displayTitle, searchQuery, theme.colorScheme),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.titleMedium,
      ),
      subtitle: preview.isEmpty
          ? Text('Chưa có nội dung', style: theme.textTheme.bodySmall)
          : Text.rich(
              _highlightedSpan(preview, searchQuery, theme.colorScheme),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium,
            ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (onShare != null)
            IconButton(
              tooltip: 'Chia sẻ ghi chú',
              icon: const Icon(Icons.share_outlined),
              onPressed: onShare,
            ),
          Text(
            _formatUpdatedAt(note.updatedAt),
            style: theme.textTheme.labelSmall,
          ),
        ],
      ),
    );
  }

  TextSpan _highlightedSpan(
    String text,
    String query,
    ColorScheme colorScheme,
  ) {
    final starts = NoteSearch.matchStarts(text, query);
    if (starts.isEmpty) return TextSpan(text: text);

    final queryLength = NoteSearch.normalize(query.trim()).length;
    final children = <InlineSpan>[];
    var cursor = 0;
    for (final start in starts) {
      if (start > cursor) {
        children.add(TextSpan(text: text.substring(cursor, start)));
      }
      children.add(
        TextSpan(
          text: text.substring(start, start + queryLength),
          style: TextStyle(
            backgroundColor: colorScheme.secondaryContainer,
            color: colorScheme.onSecondaryContainer,
          ),
        ),
      );
      cursor = start + queryLength;
    }
    if (cursor < text.length) {
      children.add(TextSpan(text: text.substring(cursor)));
    }
    return TextSpan(children: children);
  }

  String _formatUpdatedAt(DateTime value) {
    final local = value.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(local.day)}/${two(local.month)} ${two(local.hour)}:${two(local.minute)}';
  }
}

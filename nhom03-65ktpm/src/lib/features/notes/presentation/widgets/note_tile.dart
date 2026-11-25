import 'package:flutter/material.dart';

import '../../domain/entities/note.dart';
import '../../domain/usecases/note_search.dart';

/// Một dòng ghi chú trong danh sách.
class NoteTile extends StatelessWidget {
  const NoteTile({required this.note, this.searchQuery = '', super.key});

  final Note note;
  final String searchQuery;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final preview = note.content.trim().replaceAll('\n', ' ');

    return ListTile(
      leading: Icon(
        note.isDiary ? Icons.event_note_outlined : Icons.sticky_note_2_outlined,
      ),
      title: _highlightedText(
        context,
        note.displayTitle,
        theme.textTheme.titleMedium,
        maxLines: 1,
      ),
      subtitle: preview.isEmpty
          ? Text('Chưa có nội dung', style: theme.textTheme.bodySmall)
          : _highlightedText(
              context,
              preview,
              theme.textTheme.bodySmall,
              maxLines: 2,
            ),
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

  Widget _highlightedText(
    BuildContext context,
    String value,
    TextStyle? style, {
    required int maxLines,
  }) {
    final ranges = const NoteSearch().highlightRanges(value, searchQuery);
    if (ranges.isEmpty) {
      return Text(
        value,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
        style: style,
      );
    }

    final colors = Theme.of(context).colorScheme;
    final spans = <InlineSpan>[];
    var offset = 0;
    for (final range in ranges) {
      if (range.start > offset) {
        spans.add(TextSpan(text: value.substring(offset, range.start)));
      }
      spans.add(
        TextSpan(
          text: value.substring(range.start, range.end),
          style: TextStyle(
            backgroundColor: colors.secondaryContainer,
            color: colors.onSecondaryContainer,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
      offset = range.end;
    }
    if (offset < value.length) {
      spans.add(TextSpan(text: value.substring(offset)));
    }

    return Text.rich(
      TextSpan(children: spans),
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      style: style,
    );
  }
}

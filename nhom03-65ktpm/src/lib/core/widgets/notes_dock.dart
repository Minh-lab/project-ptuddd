import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class NotesDock extends StatelessWidget {
  const NotesDock({
    required this.selectedIndex,
    required this.onSelected,
    super.key,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  static const _tabs = [
    ('Ghi chú', Icons.description, Icons.description_outlined),
    ('Nhật ký', Icons.menu_book, Icons.menu_book_outlined),
    ('Thống kê', Icons.show_chart, Icons.insights_outlined),
    ('Cài đặt', Icons.tune, Icons.tune),
  ];

  Widget _tab(BuildContext context, int index) {
    final (label, active, inactive) = _tabs[index];
    final theme = Theme.of(context);
    final selected = selectedIndex == index;
    final foreground = selected
        ? NotesColors.accent(theme.brightness)
        : theme.colorScheme.onSurfaceVariant;
    return Expanded(
      child: Semantics(
        selected: selected,
        button: true,
        child: InkWell(
          onTap: () => onSelected(index),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(selected ? active : inactive, size: 24, color: foreground),
              const SizedBox(height: AppSpacing.xs),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: foreground,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BottomAppBar(
      color: NotesColors.navigation(theme.brightness),
      surfaceTintColor: theme.colorScheme.surface.withValues(alpha: 0),
      elevation: 0,
      height: NotesLayout.navigationHeight,
      padding: EdgeInsets.zero,
      shape: const CircularNotchedRectangle(),
      notchMargin: 0,
      clipBehavior: Clip.antiAlias,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: theme.brightness == Brightness.dark
                  ? NotesColors.navBorder
                  : theme.colorScheme.outlineVariant,
            ),
          ),
        ),
        child: Row(
          children: [
            _tab(context, 0),
            _tab(context, 1),
            const SizedBox(width: NotesLayout.navigationGap),
            _tab(context, 2),
            _tab(context, 3),
          ],
        ),
      ),
    );
  }
}

class NotesScanButton extends StatelessWidget {
  const NotesScanButton({required this.onPressed, super.key});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(NotesLayout.scanRing),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        shape: BoxShape.circle,
        border: Border.all(
          color: theme.brightness == Brightness.dark
              ? NotesColors.navBorder
              : theme.colorScheme.outlineVariant,
        ),
      ),
      child: SizedBox.square(
        dimension: NotesLayout.scanSize,
        child: FloatingActionButton(
          tooltip: 'Quét vở',
          onPressed: onPressed,
          elevation: 3,
          backgroundColor: NotesColors.accent(theme.brightness),
          foregroundColor: theme.colorScheme.onPrimary,
          shape: const CircleBorder(),
          child: const Icon(Icons.document_scanner_outlined, size: 26),
        ),
      ),
    );
  }
}

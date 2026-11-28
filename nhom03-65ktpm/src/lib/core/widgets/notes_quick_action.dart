import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class NotesQuickAction extends StatelessWidget {
  const NotesQuickAction({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
    super.key,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;
    final radius = BorderRadius.circular(NotesLayout.actionRadius);
    return Material(
      color: dark ? NotesColors.action : scheme.surface,
      elevation: dark ? 0 : 1,
      shadowColor: scheme.shadow.withValues(alpha: .14),
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(
          color: dark ? NotesColors.actionBorder : scheme.outlineVariant,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: NotesLayout.actionHeight,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: NotesLayout.chipPadding,
              vertical: AppSpacing.xs,
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: scheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/streak_summary.dart';
import '../../domain/entities/week_stats.dart';
import 'week_strip.dart';

/// Thẻ chuỗi ngày học: số ngày liên tiếp, kỷ lục, trạng thái hôm nay và dải
/// 7 ngày của tuần này.
class StreakCard extends StatelessWidget {
  const StreakCard({
    required this.streak,
    required this.today,
    this.thisWeek,
    super.key,
  });

  final StreakSummary streak;
  final DateTime today;
  final WeekStats? thisWeek;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Card(
      key: const ValueKey<String>('streak-card'),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Icon(
                  Icons.local_fire_department,
                  size: 40,
                  color: streak.current > 0
                      ? scheme.primary
                      : scheme.onSurfaceVariant,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Semantics(
                    label: 'Chuỗi ${streak.current} ngày học liên tiếp',
                    excludeSemantics: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          '${streak.current}',
                          key: const ValueKey<String>('streak-current'),
                          style: theme.textTheme.displayMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: scheme.onSurface,
                          ),
                        ),
                        Text(
                          'ngày học liên tiếp',
                          style: theme.textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    Text(
                      'Kỷ lục',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      '${streak.longest} ngày',
                      key: const ValueKey<String>('streak-longest'),
                      style: theme.textTheme.titleMedium,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _StatusLine(streak: streak),
            if (thisWeek != null) ...<Widget>[
              const SizedBox(height: AppSpacing.lg),
              WeekStrip(week: thisWeek!, today: today),
            ],
          ],
        ),
      ),
    );
  }
}

/// Trạng thái hôm nay: luôn có biểu tượng + chữ, không chỉ dựa vào màu.
class _StatusLine extends StatelessWidget {
  const _StatusLine({required this.streak});

  final StreakSummary streak;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantic = AppSemanticColors.of(context);
    final (IconData icon, Color color, String message) = streak.studiedToday
        ? (
            Icons.check_circle,
            semantic.success,
            'Hôm nay bạn đã học rồi. Giữ vững nhé!',
          )
        : streak.atRisk
        ? (
            Icons.warning_amber_rounded,
            semantic.warning,
            'Viết một ghi chú hôm nay để giữ chuỗi ${streak.current} ngày.',
          )
        : (
            Icons.edit_note,
            theme.colorScheme.onSurfaceVariant,
            'Viết một ghi chú hôm nay để bắt đầu chuỗi mới.',
          );
    return Row(
      key: const ValueKey<String>('streak-status'),
      children: <Widget>[
        Icon(icon, color: color, size: 20),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Text(message, style: theme.textTheme.bodyMedium)),
      ],
    );
  }
}

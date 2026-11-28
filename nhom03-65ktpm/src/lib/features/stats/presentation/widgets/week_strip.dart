import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/week_stats.dart';
import 'stats_labels.dart';

/// Dải 7 ngày của tuần: ngày có học được tô màu kèm dấu tích.
class WeekStrip extends StatelessWidget {
  const WeekStrip({required this.week, required this.today, super.key});

  final WeekStats week;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        for (var i = 0; i < 7; i++)
          _DayDot(
            index: i,
            day: DateTime(
              week.start.year,
              week.start.month,
              week.start.day + i,
            ),
            studied: week.dailyCounts[i] > 0,
            today: today,
          ),
      ],
    );
  }
}

class _DayDot extends StatelessWidget {
  const _DayDot({
    required this.index,
    required this.day,
    required this.studied,
    required this.today,
  });

  final int index;
  final DateTime day;
  final bool studied;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isToday = day == today;
    final isFuture = day.isAfter(today);
    final state = studied ? 'có học' : (isFuture ? 'chưa tới' : 'chưa học');
    return Semantics(
      container: true,
      label:
          '${StatsLabels.weekdayLong[index]} ${StatsLabels.dayMonth(day)}: '
          '$state',
      excludeSemantics: true,
      child: Column(
        key: ValueKey<String>('week-day-$index'),
        children: <Widget>[
          Text(
            StatsLabels.weekdayShort[index],
            style: theme.textTheme.labelSmall?.copyWith(
              color: isToday ? scheme.onSurface : scheme.onSurfaceVariant,
              fontWeight: isToday ? FontWeight.w700 : null,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: studied ? scheme.primary : null,
              border: studied
                  ? null
                  : Border.all(
                      color: isFuture ? scheme.outlineVariant : scheme.outline,
                      width: isToday ? 2 : 1,
                    ),
            ),
            child: studied
                ? Icon(Icons.check, size: 18, color: scheme.onPrimary)
                : null,
          ),
        ],
      ),
    );
  }
}

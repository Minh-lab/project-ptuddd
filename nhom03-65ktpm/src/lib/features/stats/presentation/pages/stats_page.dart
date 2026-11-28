import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../domain/entities/week_stats.dart';
import '../bloc/stats_cubit.dart';
import '../bloc/stats_state.dart';
import '../widgets/chart_card.dart';
import '../widgets/column_chart.dart';
import '../widgets/stats_labels.dart';
import '../widgets/streak_card.dart';

/// Màn "Thống kê": tổng quan thói quen học, streak và biểu đồ theo tuần (#17).
class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Mở lại app sau nửa đêm thì "hôm nay" đã đổi, cần tính lại streak.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<StatsCubit>().refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thống kê')),
      body: BlocBuilder<StatsCubit, StatsState>(
        builder: (BuildContext context, StatsState state) {
          if (state.isLoading) return const LoadingView();
          if (state.status == StatsStatus.failure) {
            return ErrorView(
              message: state.errorMessage ?? 'Không tải được thống kê.',
              onRetry: () => context.read<StatsCubit>().load(),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: <Widget>[
              StreakCard(
                streak: state.streak,
                today: state.today,
                thisWeek: state.thisWeek,
              ),
              const SizedBox(height: AppSpacing.lg),
              _OverviewRow(state: state),
              const SizedBox(height: AppSpacing.lg),
              if (state.selectedWeek != null)
                _WeeklyChart(state: state, week: state.selectedWeek!),
              const SizedBox(height: AppSpacing.lg),
              _TrendChart(state: state),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Mỗi ngày có ít nhất một ghi chú hoặc nhật ký mới được tính '
                'là một ngày học.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _OverviewRow extends StatelessWidget {
  const _OverviewRow({required this.state});

  final StatsState state;

  @override
  Widget build(BuildContext context) {
    // Ba ô cao bằng nhau dù nhãn dài xuống dòng.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _StatTile(
            key: const ValueKey<String>('stat-total-notes'),
            value: state.totalNotes,
            label: 'Tổng ghi chú',
          ),
          const SizedBox(width: AppSpacing.md),
          _StatTile(
            key: const ValueKey<String>('stat-diary'),
            value: state.diaryCount,
            label: 'Nhật ký',
          ),
          const SizedBox(width: AppSpacing.md),
          _StatTile(
            key: const ValueKey<String>('stat-month-days'),
            value: state.activeDaysThisMonth,
            label: 'Ngày học tháng này',
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.value, required this.label, super.key});

  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Semantics(
            label: '$label: $value',
            excludeSemantics: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('$value', style: theme.textTheme.headlineSmall),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  label,
                  maxLines: 2,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
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

class _WeeklyChart extends StatelessWidget {
  const _WeeklyChart({required this.state, required this.week});

  final StatsState state;
  final WeekStats week;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cubit = context.read<StatsCubit>();
    final range = StatsLabels.weekRange(week.start, week.end);
    return ChartCard(
      key: const ValueKey<String>('weekly-chart'),
      title: 'Ghi chú theo tuần',
      subtitle: state.weekOffset == 0 ? 'Tuần này · $range' : range,
      headerActions: <Widget>[
        IconButton(
          key: const ValueKey<String>('previous-week'),
          tooltip: 'Tuần trước',
          icon: const Icon(Icons.chevron_left),
          onPressed: cubit.previousWeek,
        ),
        IconButton(
          key: const ValueKey<String>('next-week'),
          tooltip: 'Tuần sau',
          icon: const Icon(Icons.chevron_right),
          onPressed: state.canGoNextWeek ? cubit.nextWeek : null,
        ),
      ],
      headline: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: <Widget>[
          Text(
            StatsLabels.notes(week.total),
            key: const ValueKey<String>('week-total'),
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Text(
              StatsLabels.versusPrevious(week.total, state.previousWeekTotal),
              key: const ValueKey<String>('week-delta'),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
      columns: <ChartColumn>[
        for (var i = 0; i < 7; i++)
          _dayColumn(
            i,
            DateTime(week.start.year, week.start.month, week.start.day + i),
            week.dailyCounts[i],
          ),
      ],
    );
  }

  ChartColumn _dayColumn(int index, DateTime day, int count) {
    return ChartColumn(
      label: StatsLabels.weekdayShort[index],
      value: count,
      description:
          '${StatsLabels.weekdayLong[index]} ${StatsLabels.dayMonth(day)}: '
          '${StatsLabels.notes(count)}',
      emphasized: day == state.today,
    );
  }
}

class _TrendChart extends StatelessWidget {
  const _TrendChart({required this.state});

  final StatsState state;

  @override
  Widget build(BuildContext context) {
    final weeks = state.recentWeeks;
    return ChartCard(
      key: const ValueKey<String>('trend-chart'),
      title: '${weeks.length} tuần gần nhất',
      subtitle: 'Số ghi chú mới mỗi tuần',
      columns: <ChartColumn>[
        for (var i = 0; i < weeks.length; i++)
          ChartColumn(
            label: StatsLabels.dayMonth(weeks[i].start),
            value: weeks[i].total,
            description:
                'Tuần ${StatsLabels.weekRange(weeks[i].start, weeks[i].end)}: '
                '${StatsLabels.notes(weeks[i].total)}',
            emphasized: i == weeks.length - 1,
          ),
      ],
    );
  }
}

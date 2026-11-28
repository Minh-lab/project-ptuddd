import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/app_dependencies.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../domain/entities/note.dart';
import '../bloc/notes_cubit.dart';
import '../bloc/notes_state.dart';
import 'note_editor_page.dart';

class DiaryPage extends StatefulWidget {
  const DiaryPage({required this.dependencies, super.key});

  final AppDependencies dependencies;

  @override
  State<DiaryPage> createState() => _DiaryPageState();
}

class _DiaryPageState extends State<DiaryPage> {
  DateTime _weekStart = _startOfWeek(DateTime.now());

  static DateTime _startOfWeek(DateTime date) {
    final day = date.toLocal();
    return DateTime(day.year, day.month, day.day - day.weekday + 1);
  }

  String _date(DateTime value) {
    final date = value.toLocal();
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _weekday(int weekday) => switch (weekday) {
    DateTime.monday => 'Thứ hai',
    DateTime.tuesday => 'Thứ ba',
    DateTime.wednesday => 'Thứ tư',
    DateTime.thursday => 'Thứ năm',
    DateTime.friday => 'Thứ sáu',
    DateTime.saturday => 'Thứ bảy',
    _ => 'Chủ nhật',
  };

  Future<void> _pickDate() async {
    final today = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _weekStart,
      firstDate: DateTime(2000),
      lastDate: DateTime(today.year, today.month, today.day),
    );
    if (selected == null || !mounted) return;
    setState(() => _weekStart = _startOfWeek(selected));
  }

  void _openDiary(Note note) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => NoteEditorPage(
          cubit: context.read<NotesCubit>(),
          note: note,
          summaryRepository: widget.dependencies.summaryRepository,
          isSummaryDemo: widget.dependencies.aiClient.isDemo,
        ),
      ),
    );
  }

  Future<void> _openOrCreateDiary(DateTime date) async {
    try {
      final note = await context.read<NotesCubit>().ensureDiaryForDate(date);
      if (mounted) _openDiary(note);
    } on Object catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không mở được nhật ký: $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final today = _startOfWeek(DateTime.now());
    final weekEnd = _weekStart.add(const Duration(days: 7));
    final nextWeekEnabled = _weekStart.isBefore(today);
    return AppScaffold(
      title: 'Nhật ký',
      subtitle: 'Ghi lại từng ngày, xem lại theo tuần.',
      toolbar: Row(
        children: <Widget>[
          IconButton(
            tooltip: 'Tuần trước',
            onPressed: () => setState(
              () => _weekStart = _weekStart.subtract(const Duration(days: 7)),
            ),
            icon: const Icon(Icons.chevron_left),
          ),
          Expanded(
            child: Text(
              '${_date(_weekStart)} – ${_date(weekEnd.subtract(const Duration(days: 1)))}',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          IconButton(
            tooltip: 'Chọn ngày',
            onPressed: _pickDate,
            icon: const Icon(Icons.calendar_month_outlined),
          ),
          IconButton(
            tooltip: 'Tuần sau',
            onPressed: nextWeekEnabled
                ? () => setState(
                    () => _weekStart = _weekStart.add(const Duration(days: 7)),
                  )
                : null,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
      body: BlocBuilder<NotesCubit, NotesState>(
        builder: (BuildContext context, NotesState state) {
          if (state.isLoading) return const LoadingView();
          if (state.status == NotesStatus.failure) {
            return ErrorView(
              message: state.errorMessage ?? 'Không đọc được nhật ký của bạn.',
              onRetry: context.read<NotesCubit>().load,
            );
          }

          final diaries =
              state.notes.where((Note note) {
                final createdAt = note.createdAt.toLocal();
                return note.isDiary &&
                    !createdAt.isBefore(_weekStart) &&
                    createdAt.isBefore(weekEnd);
              }).toList()..sort(
                (Note left, Note right) =>
                    right.createdAt.compareTo(left.createdAt),
              );
          final diariesByDay = <DateTime, Note>{
            for (final diary in diaries)
              DateTime(
                diary.createdAt.toLocal().year,
                diary.createdAt.toLocal().month,
                diary.createdAt.toLocal().day,
              ): diary,
          };
          final words = diaries.fold<int>(
            0,
            (int total, Note note) =>
                total +
                note.content
                    .trim()
                    .split(RegExp(r'\s+'))
                    .where((String word) => word.isNotEmpty)
                    .length,
          );
          final todayDate = DateTime.now();
          final todayStart = DateTime(
            todayDate.year,
            todayDate.month,
            todayDate.day,
          );

          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.xl,
            ),
            children: <Widget>[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Row(
                    children: <Widget>[
                      const Icon(Icons.auto_stories_outlined),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          '${diaries.length}/7 ngày có nhật ký · $words từ',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              for (var index = 0; index < 7; index++)
                _DiaryDayTile(
                  date: _weekStart.add(Duration(days: index)),
                  weekday: _weekday(
                    _weekStart.add(Duration(days: index)).weekday,
                  ),
                  note: diariesByDay[_weekStart.add(Duration(days: index))],
                  canCreate: !_weekStart
                      .add(Duration(days: index))
                      .isAfter(todayStart),
                  onTap: (DateTime date, Note? note) {
                    if (note != null) {
                      _openDiary(note);
                    } else {
                      _openOrCreateDiary(date);
                    }
                  },
                ),
            ],
          );
        },
      ),
    );
  }
}

class _DiaryDayTile extends StatelessWidget {
  const _DiaryDayTile({
    required this.date,
    required this.weekday,
    required this.note,
    required this.canCreate,
    required this.onTap,
  });

  final DateTime date;
  final String weekday;
  final Note? note;
  final bool canCreate;
  final void Function(DateTime date, Note? note) onTap;

  @override
  Widget build(BuildContext context) {
    final hasEntry = note != null;
    final isToday = DateUtils.isSameDay(date, DateTime.now());
    return Card(
      child: ListTile(
        enabled: hasEntry || canCreate,
        leading: CircleAvatar(child: Text('${date.day}')),
        title: Text(
          '$weekday · ${date.day.toString().padLeft(2, '0')}/'
          '${date.month.toString().padLeft(2, '0')}',
        ),
        subtitle: Text(
          hasEntry
              ? note!.content.trim().isEmpty
                    ? 'Chạm để viết nhật ký'
                    : note!.content.trim().replaceAll(RegExp(r'\s+'), ' ')
              : isToday
              ? 'Chạm để viết nhật ký hôm nay'
              : 'Chưa có nhật ký',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Icon(hasEntry ? Icons.edit_outlined : Icons.add, size: 20),
        onTap: hasEntry || canCreate ? () => onTap(date, note) : null,
      ),
    );
  }
}

import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failure.dart';
import '../../domain/entities/study_note.dart';
import '../../domain/repositories/study_activity_source.dart';
import '../../domain/usecases/study_calendar.dart';
import 'stats_state.dart';

/// Tính streak và thống kê tuần từ danh sách ghi chú (#17).
class StatsCubit extends Cubit<StatsState> {
  StatsCubit(this._source, {this.clock = DateTime.now})
    : super(StatsState(today: StudyCalendar.dayOf(clock())));

  final StudyActivitySource _source;

  /// Đồng hồ hiện tại; test truyền giờ cố định.
  final DateTime Function() clock;

  StreamSubscription<List<StudyNote>>? _subscription;
  List<StudyNote> _notes = const <StudyNote>[];

  Future<void> load() async {
    await _subscription?.cancel();
    _subscription = _source.watchStudyNotes().listen(
      (List<StudyNote> notes) {
        _notes = notes;
        _recompute();
      },
      onError: (Object error) {
        if (isClosed) return;
        emit(
          state.copyWith(
            status: StatsStatus.failure,
            errorMessage: error is Failure
                ? error.message
                : 'Không tải được thống kê.',
          ),
        );
      },
    );
  }

  /// Tính lại theo giờ hiện tại (ví dụ app mở lại sau nửa đêm).
  void refresh() => _recompute();

  void previousWeek() => _recompute(weekOffset: state.weekOffset - 1);

  void nextWeek() {
    if (state.canGoNextWeek) _recompute(weekOffset: state.weekOffset + 1);
  }

  void _recompute({int? weekOffset}) {
    if (isClosed) return;
    final now = clock();
    final offset = weekOffset ?? state.weekOffset;
    final times = _notes.map((StudyNote note) => note.createdAt).toList();
    final thisWeekStart = StudyCalendar.weekStart(now);
    final selectedStart = StudyCalendar.addDays(thisWeekStart, 7 * offset);
    emit(
      state.copyWith(
        status: StatsStatus.success,
        today: StudyCalendar.dayOf(now),
        streak: StudyCalendar.streak(times, now),
        thisWeek: StudyCalendar.week(times, thisWeekStart),
        selectedWeek: StudyCalendar.week(times, selectedStart),
        previousWeekTotal: StudyCalendar.week(
          times,
          StudyCalendar.addDays(selectedStart, -7),
        ).total,
        recentWeeks: StudyCalendar.recentWeeks(times, now),
        weekOffset: offset,
        totalNotes: _notes.length,
        diaryCount: _notes.where((StudyNote note) => note.isDiary).length,
        activeDaysThisMonth: StudyCalendar.activeDaysInMonth(times, now),
      ),
    );
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}

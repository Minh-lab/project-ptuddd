import 'package:equatable/equatable.dart';

import '../../domain/entities/streak_summary.dart';
import '../../domain/entities/week_stats.dart';

enum StatsStatus { loading, success, failure }

/// Mọi số liệu đã tính sẵn để màn hình chỉ việc hiển thị.
class StatsState extends Equatable {
  const StatsState({
    required this.today,
    this.status = StatsStatus.loading,
    this.streak = StreakSummary.empty,
    this.thisWeek,
    this.selectedWeek,
    this.previousWeekTotal = 0,
    this.recentWeeks = const <WeekStats>[],
    this.weekOffset = 0,
    this.totalNotes = 0,
    this.diaryCount = 0,
    this.activeDaysThisMonth = 0,
    this.errorMessage,
  });

  final StatsStatus status;

  /// Ngày hiện tại (đã bỏ giờ phút) lúc tính số liệu.
  final DateTime today;
  final StreakSummary streak;

  /// Tuần hiện tại — dùng cho dải 7 ngày.
  final WeekStats? thisWeek;

  /// Tuần đang xem trên biểu đồ.
  final WeekStats? selectedWeek;

  /// Tổng ghi chú của tuần liền trước tuần đang xem.
  final int previousWeekTotal;

  /// 8 tuần gần nhất, cũ trước mới sau.
  final List<WeekStats> recentWeeks;

  /// 0 là tuần này, -1 là tuần trước…
  final int weekOffset;

  final int totalNotes;
  final int diaryCount;
  final int activeDaysThisMonth;
  final String? errorMessage;

  bool get isLoading => status == StatsStatus.loading;
  bool get canGoNextWeek => weekOffset < 0;

  StatsState copyWith({
    StatsStatus? status,
    DateTime? today,
    StreakSummary? streak,
    WeekStats? thisWeek,
    WeekStats? selectedWeek,
    int? previousWeekTotal,
    List<WeekStats>? recentWeeks,
    int? weekOffset,
    int? totalNotes,
    int? diaryCount,
    int? activeDaysThisMonth,
    String? errorMessage,
  }) {
    return StatsState(
      status: status ?? this.status,
      today: today ?? this.today,
      streak: streak ?? this.streak,
      thisWeek: thisWeek ?? this.thisWeek,
      selectedWeek: selectedWeek ?? this.selectedWeek,
      previousWeekTotal: previousWeekTotal ?? this.previousWeekTotal,
      recentWeeks: recentWeeks ?? this.recentWeeks,
      weekOffset: weekOffset ?? this.weekOffset,
      totalNotes: totalNotes ?? this.totalNotes,
      diaryCount: diaryCount ?? this.diaryCount,
      activeDaysThisMonth: activeDaysThisMonth ?? this.activeDaysThisMonth,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    status,
    today,
    streak,
    thisWeek,
    selectedWeek,
    previousWeekTotal,
    recentWeeks,
    weekOffset,
    totalNotes,
    diaryCount,
    activeDaysThisMonth,
    errorMessage,
  ];
}

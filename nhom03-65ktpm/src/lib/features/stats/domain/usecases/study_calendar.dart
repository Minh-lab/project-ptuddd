import '../entities/streak_summary.dart';
import '../entities/week_stats.dart';

/// Quy tắc tính streak và thống kê tuần (Dart thuần, theo giờ của máy).
///
/// Một **ngày học** là ngày có ít nhất một ghi chú hoặc nhật ký được tạo.
/// Chỉ dùng thời điểm tạo vì `updatedAt` bị ghi đè mỗi lần sửa: nếu tính cả
/// ngày sửa thì sửa lại ghi chú cũ sẽ làm mất ngày học trước đó và streak bị
/// giảm ngược.
class StudyCalendar {
  const StudyCalendar._();

  /// Bỏ giờ phút, chỉ giữ ngày.
  static DateTime dayOf(DateTime time) =>
      DateTime(time.year, time.month, time.day);

  /// Cộng ngày theo lịch (dựng lại từ ngày/tháng/năm nên không lệch giờ).
  static DateTime addDays(DateTime day, int days) =>
      DateTime(day.year, day.month, day.day + days);

  /// 0 giờ thứ Hai của tuần chứa [time].
  static DateTime weekStart(DateTime time) {
    final day = dayOf(time);
    return addDays(day, -(day.weekday - DateTime.monday));
  }

  /// Các ngày học, bỏ những ngày sau [today] (đồng hồ máy bị lệch).
  static Set<DateTime> activeDays(Iterable<DateTime> times, DateTime today) {
    final last = dayOf(today);
    return <DateTime>{
      for (final time in times)
        if (!dayOf(time).isAfter(last)) dayOf(time),
    };
  }

  /// Streak hiện tại và dài nhất tính tới [now].
  ///
  /// - Hôm nay có học: đếm lùi từ hôm nay.
  /// - Hôm nay chưa học nhưng hôm qua có: chuỗi vẫn còn, đếm lùi từ hôm qua.
  /// - Hôm qua cũng không học: chuỗi về 0.
  static StreakSummary streak(Iterable<DateTime> times, DateTime now) {
    final today = dayOf(now);
    final days = activeDays(times, today);
    if (days.isEmpty) return StreakSummary.empty;

    final studiedToday = days.contains(today);
    final yesterday = addDays(today, -1);
    final anchor = studiedToday
        ? today
        : (days.contains(yesterday) ? yesterday : null);

    var current = 0;
    if (anchor != null) {
      var day = anchor;
      while (days.contains(day)) {
        current++;
        day = addDays(day, -1);
      }
    }

    final sorted = days.toList()..sort();
    var longest = 1;
    var run = 1;
    for (var i = 1; i < sorted.length; i++) {
      run = addDays(sorted[i - 1], 1) == sorted[i] ? run + 1 : 1;
      if (run > longest) longest = run;
    }

    return StreakSummary(
      current: current,
      longest: longest,
      studiedToday: studiedToday,
      lastStudyDay: sorted.last,
    );
  }

  /// Số ghi chú từng ngày của tuần bắt đầu từ [weekStart] (thứ Hai).
  static WeekStats week(Iterable<DateTime> times, DateTime weekStart) {
    final start = StudyCalendar.weekStart(weekStart);
    final counts = List<int>.filled(7, 0);
    for (final time in times) {
      final day = dayOf(time);
      final index = _daysBetween(start, day);
      if (index >= 0 && index < 7) counts[index]++;
    }
    return WeekStats(start: start, dailyCounts: counts);
  }

  /// [count] tuần gần nhất, cũ trước mới sau, tuần cuối là tuần chứa [now].
  static List<WeekStats> recentWeeks(
    Iterable<DateTime> times,
    DateTime now, {
    int count = 8,
  }) {
    final thisWeek = weekStart(now);
    return <WeekStats>[
      for (var i = count - 1; i >= 0; i--)
        week(times, addDays(thisWeek, -7 * i)),
    ];
  }

  /// Số ngày học trong tháng chứa [now], tính tới hôm nay.
  static int activeDaysInMonth(Iterable<DateTime> times, DateTime now) {
    return activeDays(times, now)
        .where((DateTime day) => day.year == now.year && day.month == now.month)
        .length;
  }

  /// Số ngày lịch từ [from] tới [to] (cả hai đã bỏ giờ phút).
  static int _daysBetween(DateTime from, DateTime to) {
    // Dùng giờ UTC để chênh lệch luôn là bội số của 24 giờ.
    final a = DateTime.utc(from.year, from.month, from.day);
    final b = DateTime.utc(to.year, to.month, to.day);
    return b.difference(a).inDays;
  }
}

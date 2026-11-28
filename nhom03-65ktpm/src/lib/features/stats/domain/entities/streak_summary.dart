import 'package:equatable/equatable.dart';

/// Chuỗi ngày học liên tiếp (streak) tại một thời điểm.
class StreakSummary extends Equatable {
  const StreakSummary({
    required this.current,
    required this.longest,
    required this.studiedToday,
    this.lastStudyDay,
  });

  static const StreakSummary empty = StreakSummary(
    current: 0,
    longest: 0,
    studiedToday: false,
  );

  /// Số ngày liên tiếp tính tới hôm nay (hoặc hôm qua nếu hôm nay chưa học).
  final int current;

  /// Chuỗi dài nhất từng đạt.
  final int longest;

  final bool studiedToday;

  /// Ngày học gần nhất (đã bỏ giờ phút), `null` nếu chưa học ngày nào.
  final DateTime? lastStudyDay;

  /// Hôm nay chưa học nhưng chuỗi vẫn còn: hết hôm nay mà chưa học là mất.
  bool get atRisk => !studiedToday && current > 0;

  @override
  List<Object?> get props => <Object?>[
    current,
    longest,
    studiedToday,
    lastStudyDay,
  ];
}

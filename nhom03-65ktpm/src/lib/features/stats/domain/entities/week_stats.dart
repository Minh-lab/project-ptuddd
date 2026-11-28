import 'package:equatable/equatable.dart';

/// Số ghi chú mới trong một tuần (thứ Hai → Chủ nhật).
class WeekStats extends Equatable {
  const WeekStats({required this.start, required this.dailyCounts})
    : assert(dailyCounts.length == 7, 'Một tuần có 7 ngày');

  /// 0 giờ thứ Hai đầu tuần (giờ máy).
  final DateTime start;

  /// Số ghi chú mỗi ngày, phần tử 0 là thứ Hai.
  final List<int> dailyCounts;

  /// Chủ nhật cuối tuần.
  DateTime get end => DateTime(start.year, start.month, start.day + 6);

  int get total => dailyCounts.fold(0, (int sum, int count) => sum + count);

  /// Số ngày trong tuần có ít nhất một ghi chú.
  int get activeDays => dailyCounts.where((int count) => count > 0).length;

  @override
  List<Object?> get props => <Object?>[start, dailyCounts];
}

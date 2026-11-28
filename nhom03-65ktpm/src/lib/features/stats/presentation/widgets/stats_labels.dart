/// Chuỗi hiển thị cho màn thống kê (chỉ định dạng, không chứa logic).
class StatsLabels {
  const StatsLabels._();

  static const List<String> weekdayShort = <String>[
    'T2',
    'T3',
    'T4',
    'T5',
    'T6',
    'T7',
    'CN',
  ];

  static const List<String> weekdayLong = <String>[
    'Thứ Hai',
    'Thứ Ba',
    'Thứ Tư',
    'Thứ Năm',
    'Thứ Sáu',
    'Thứ Bảy',
    'Chủ nhật',
  ];

  static String dayMonth(DateTime day) => '${_two(day.day)}/${_two(day.month)}';

  static String date(DateTime day) => '${dayMonth(day)}/${day.year}';

  /// Ví dụ: "23/11 – 29/11/2026".
  static String weekRange(DateTime start, DateTime end) =>
      '${dayMonth(start)} – ${date(end)}';

  static String notes(int count) => '$count ghi chú';

  /// So sánh với tuần trước, ví dụ "+2 so với tuần trước".
  static String versusPrevious(int current, int previous) {
    final diff = current - previous;
    if (diff == 0) return 'Bằng tuần trước';
    return '${diff > 0 ? '+' : '−'}${diff.abs()} so với tuần trước';
  }

  static String _two(int value) => value.toString().padLeft(2, '0');
}

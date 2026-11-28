import 'package:flutter_test/flutter_test.dart';
import 'package:smart_note/features/stats/domain/entities/streak_summary.dart';
import 'package:smart_note/features/stats/domain/usecases/study_calendar.dart';

/// Thứ Bảy 28/11/2026, 21:00.
final DateTime _now = DateTime(2026, 11, 28, 21);

/// Ghi chú tạo lúc 9 giờ sáng của ngày [day] tháng 11/2026.
DateTime _nov(int day, [int hour = 9]) => DateTime(2026, 11, day, hour);

void main() {
  group('Streak', () {
    test('chưa có ghi chú nào thì streak bằng 0', () {
      expect(StudyCalendar.streak(<DateTime>[], _now), StreakSummary.empty);
    });

    test('hôm nay có ghi chú đầu tiên thì streak là 1', () {
      final streak = StudyCalendar.streak(<DateTime>[_nov(28)], _now);

      expect(streak.current, 1);
      expect(streak.longest, 1);
      expect(streak.studiedToday, isTrue);
      expect(streak.atRisk, isFalse);
      expect(streak.lastStudyDay, DateTime(2026, 11, 28));
    });

    test('nhiều ghi chú trong cùng một ngày chỉ tính một ngày', () {
      final streak = StudyCalendar.streak(<DateTime>[
        _nov(28, 7),
        _nov(28, 12),
        _nov(28, 20),
      ], _now);

      expect(streak.current, 1);
    });

    test('tăng thêm 1 khi học thêm một ngày liền kề', () {
      final days = <DateTime>[_nov(25), _nov(26), _nov(27)];
      // Tối 27/11: chuỗi 3 ngày.
      expect(StudyCalendar.streak(days, _nov(27, 22)).current, 3);
      // Sang 28/11 viết thêm một ghi chú: chuỗi lên 4.
      expect(
        StudyCalendar.streak(<DateTime>[...days, _nov(28)], _now).current,
        4,
      );
    });

    test('hôm nay chưa học thì vẫn giữ chuỗi tới hôm qua và báo sắp mất', () {
      final streak = StudyCalendar.streak(<DateTime>[
        _nov(25),
        _nov(26),
        _nov(27),
      ], _now);

      expect(streak.current, 3);
      expect(streak.studiedToday, isFalse);
      expect(streak.atRisk, isTrue);
    });

    test('bỏ một ngày thì chuỗi về 0 nhưng vẫn giữ kỷ lục', () {
      // Học 23–26/11, nghỉ 27/11, hôm nay 28/11 chưa học.
      final streak = StudyCalendar.streak(<DateTime>[
        _nov(23),
        _nov(24),
        _nov(25),
        _nov(26),
      ], _now);

      expect(streak.current, 0);
      expect(streak.longest, 4);
      expect(streak.atRisk, isFalse);
    });

    test('học lại sau khi đứt chuỗi thì bắt đầu đếm lại từ 1', () {
      final streak = StudyCalendar.streak(<DateTime>[
        _nov(23),
        _nov(24),
        _nov(25),
        _nov(28),
      ], _now);

      expect(streak.current, 1);
      expect(streak.longest, 3);
    });

    test('chuỗi nối qua ranh giới tháng và năm', () {
      final crossMonth = StudyCalendar.streak(<DateTime>[
        DateTime(2026, 11, 30, 23, 59),
        DateTime(2026, 12, 1, 0, 1),
      ], DateTime(2026, 12, 1, 8));
      expect(crossMonth.current, 2);

      final crossYear = StudyCalendar.streak(<DateTime>[
        DateTime(2026, 12, 31, 20),
        DateTime(2027, 1, 1, 9),
      ], DateTime(2027, 1, 1, 10));
      expect(crossYear.current, 2);
    });

    test('ghi chú 23:59 và 00:01 thuộc hai ngày khác nhau', () {
      final streak = StudyCalendar.streak(<DateTime>[
        DateTime(2026, 11, 27, 23, 59),
        DateTime(2026, 11, 28, 0, 1),
      ], _now);

      expect(streak.current, 2);
    });

    test('bỏ qua ghi chú có ngày trong tương lai (đồng hồ máy lệch)', () {
      final streak = StudyCalendar.streak(<DateTime>[_nov(27), _nov(30)], _now);

      expect(streak.current, 1);
      expect(streak.studiedToday, isFalse);
      expect(streak.lastStudyDay, DateTime(2026, 11, 27));
    });

    test('kỷ lục là chuỗi dài nhất dù không phải chuỗi gần đây', () {
      final streak = StudyCalendar.streak(<DateTime>[
        for (var day = 1; day <= 6; day++) _nov(day),
        _nov(10),
        _nov(27),
        _nov(28),
      ], _now);

      expect(streak.current, 2);
      expect(streak.longest, 6);
    });

    test('thứ tự ghi chú đầu vào không ảnh hưởng kết quả', () {
      final days = <DateTime>[_nov(28), _nov(26), _nov(27), _nov(20)];
      expect(
        StudyCalendar.streak(days, _now),
        StudyCalendar.streak(days.reversed.toList(), _now),
      );
      expect(StudyCalendar.streak(days, _now).current, 3);
    });
  });

  group('Thống kê tuần', () {
    test('tuần bắt đầu từ thứ Hai', () {
      expect(StudyCalendar.weekStart(_now), DateTime(2026, 11, 23));
      // Chủ nhật vẫn thuộc tuần bắt đầu từ thứ Hai trước đó.
      expect(
        StudyCalendar.weekStart(DateTime(2026, 11, 29, 23)),
        DateTime(2026, 11, 23),
      );
      expect(
        StudyCalendar.weekStart(DateTime(2026, 11, 30)),
        DateTime(2026, 11, 30),
      );
    });

    test('đếm ghi chú từng ngày trong tuần, bỏ ngày ngoài tuần', () {
      final week = StudyCalendar.week(<DateTime>[
        _nov(22), // Chủ nhật tuần trước
        _nov(23, 8),
        _nov(23, 20),
        _nov(25),
        _nov(29, 23), // Chủ nhật tuần này
        _nov(30), // thứ Hai tuần sau
      ], _now);

      expect(week.start, DateTime(2026, 11, 23));
      expect(week.end, DateTime(2026, 11, 29));
      expect(week.dailyCounts, <int>[2, 0, 1, 0, 0, 0, 1]);
      expect(week.total, 4);
      expect(week.activeDays, 3);
    });

    test('8 tuần gần nhất xếp cũ trước mới sau', () {
      final weeks = StudyCalendar.recentWeeks(<DateTime>[
        _nov(2),
        _nov(25),
        _nov(26),
      ], _now);

      expect(weeks, hasLength(8));
      expect(weeks.first.start, DateTime(2026, 10, 5));
      expect(weeks.last.start, DateTime(2026, 11, 23));
      expect(weeks.last.total, 2);
      expect(weeks[weeks.length - 4].total, 1); // tuần 2/11
    });

    test('số ngày học trong tháng', () {
      expect(
        StudyCalendar.activeDaysInMonth(<DateTime>[
          DateTime(2026, 10, 31),
          _nov(1),
          _nov(1, 18),
          _nov(28),
        ], _now),
        2,
      );
    });
  });
}

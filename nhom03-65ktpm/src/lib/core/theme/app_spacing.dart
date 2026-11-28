import 'package:flutter/material.dart';

/// Thang khoảng cách dùng chung — theo `docs/ui_ux.md` mục 3.
///
/// Chỉ dùng các giá trị này trong `EdgeInsets`/`SizedBox`; không đặt số lẻ
/// (10, 14, 18, 20…) trong widget.
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;
}

/// Bán kính bo góc dùng chung — theo `docs/ui_ux.md` mục 3.
abstract final class AppRadius {
  /// Ô nhập liệu, chip, ảnh nhỏ.
  static const double input = 14;

  /// Card, khối nội dung (mockup notes dùng 12–16; chọn 16 cho đồng bộ với ô nhập).
  static const double card = 16;

  /// Nút hành động chính.
  static const double button = 16;

  /// Dialog, bottom sheet.
  static const double sheet = 28;

  /// Logo/khối biểu tượng.
  static const double mark = 22;
}

/// Bóng đổ dùng chung — tham chiếu `13_design_system.png` và
/// `02_notes_google_keep_inspired.png` (card trắng/pastel nổi nhẹ trên nền
/// xanh rất nhạt).
abstract final class AppShadows {
  /// Card, ô tìm kiếm.
  static List<BoxShadow> soft(Color color) => <BoxShadow>[
    BoxShadow(
      color: color.withValues(alpha: 0.06),
      blurRadius: 16,
      offset: const Offset(0, 6),
    ),
  ];

  /// Nút hành động chính (bóng màu theo `primary`).
  static List<BoxShadow> primary(Color color) => <BoxShadow>[
    BoxShadow(
      color: color.withValues(alpha: 0.28),
      blurRadius: 18,
      offset: const Offset(0, 8),
    ),
  ];

  /// Khối hero thương hiệu.
  static List<BoxShadow> hero(Color color) => <BoxShadow>[
    BoxShadow(
      color: color.withValues(alpha: 0.24),
      blurRadius: 24,
      offset: const Offset(0, 12),
    ),
  ];
}

/// Kích thước cố định khác.
abstract final class AppSizes {
  /// Chiều cao nút chính (giữ touch target ≥ 48dp).
  static const double buttonHeight = 54;

  /// Chiều rộng tối đa của khối form trên tablet/web.
  static const double formMaxWidth = 440;

  /// Chiều cao hero thương hiệu ở màn đăng nhập.
  static const double authHeroHeight = 150;
}

/// Kích thước của màn Ghi chú và thanh điều hướng dưới.
abstract final class NotesLayout {
  static const double gutter = 16;
  static const double gap = 12;
  static const double cardPadding = 14;
  static const double cardRadius = 18;
  static const double searchRadius = 24;
  static const double searchHeight = 48;
  static const double createSize = 44;
  static const double avatarSize = 40;
  static const double actionHeight = 52;
  static const double actionRadius = 16;
  static const double actionGap = 10;
  static const double actionTop = 14;
  static const double headerBottom = 14;
  static const double cardTitleTop = 6;
  static const double topicTop = 18;
  static const double chipPadding = 14;
  static const double chipVerticalPadding = 7;
  static const double badgeRadius = 6;
  static const double badgePadding = 3;
  static const double navigationHeight = 68;
  static const double navigationGap = 68;
  static const double scanSize = 60;
  static const double scanRing = 4;
  static const double bottomPadding = 100;
  static const double gridAspectRatio = .85;
  static const double minTileHeight = 192;
}

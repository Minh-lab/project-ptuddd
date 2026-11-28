import 'package:flutter/material.dart';

/// Màu ngữ nghĩa dùng ngoài bảng role của Material 3 (thành công, cảnh báo).
///
/// M3 không có role `success`/`warning`, nên nhóm khai báo tại đây — **không**
/// dùng mã màu trực tiếp trong widget. Đọc bằng `AppSemanticColors.of(context)`.
@immutable
class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  const AppSemanticColors({
    required this.success,
    required this.onSuccess,
    required this.successContainer,
    required this.warning,
    required this.onWarning,
    required this.warningContainer,
  });

  /// Bảng màu sáng: xanh lá dịu + hổ phách đủ tương phản với chữ trắng.
  static const AppSemanticColors light = AppSemanticColors(
    success: Color(0xFF12855F),
    onSuccess: Color(0xFFFFFFFF),
    successContainer: Color(0xFFDCF6EC),
    warning: Color(0xFF9A5B00),
    onWarning: Color(0xFFFFFFFF),
    warningContainer: Color(0xFFFFF1D6),
  );

  /// Bảng màu tối: sáng hơn để đạt tương phản trên nền tối.
  static const AppSemanticColors dark = AppSemanticColors(
    success: Color(0xFF4FD1B0),
    onSuccess: Color(0xFF04291F),
    successContainer: Color(0xFF123B2F),
    warning: Color(0xFFFFC94D),
    onWarning: Color(0xFF3A2500),
    warningContainer: Color(0xFF3B3213),
  );

  final Color success;
  final Color onSuccess;
  final Color successContainer;
  final Color warning;
  final Color onWarning;
  final Color warningContainer;

  static AppSemanticColors of(BuildContext context) {
    return Theme.of(context).extension<AppSemanticColors>() ?? light;
  }

  @override
  AppSemanticColors copyWith({
    Color? success,
    Color? onSuccess,
    Color? successContainer,
    Color? warning,
    Color? onWarning,
    Color? warningContainer,
  }) {
    return AppSemanticColors(
      success: success ?? this.success,
      onSuccess: onSuccess ?? this.onSuccess,
      successContainer: successContainer ?? this.successContainer,
      warning: warning ?? this.warning,
      onWarning: onWarning ?? this.onWarning,
      warningContainer: warningContainer ?? this.warningContainer,
    );
  }

  @override
  AppSemanticColors lerp(ThemeExtension<AppSemanticColors>? other, double t) {
    if (other is! AppSemanticColors) {
      return this;
    }
    return AppSemanticColors(
      success: Color.lerp(success, other.success, t)!,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t)!,
      successContainer: Color.lerp(
        successContainer,
        other.successContainer,
        t,
      )!,
      warning: Color.lerp(warning, other.warning, t)!,
      onWarning: Color.lerp(onWarning, other.onWarning, t)!,
      warningContainer: Color.lerp(
        warningContainer,
        other.warningContainer,
        t,
      )!,
    );
  }
}

/// Một tông màu pastel dùng cho thẻ ghi chú / nhãn môn học.
///
/// Tham chiếu mockup `02_notes_google_keep_inspired.png`: thẻ nền pastel,
/// tiêu đề đậm, nhãn môn học cùng tông nhưng đậm hơn.
@immutable
class AppNoteTone {
  const AppNoteTone({
    required this.container,
    required this.onContainer,
    required this.accent,
  });

  /// Nền thẻ.
  final Color container;

  /// Chữ trên nền thẻ.
  final Color onContainer;

  /// Nhãn/điểm nhấn (đậm hơn [container]).
  final Color accent;
}

/// Bộ 5 tông pastel của design system (mint, sky, lilac, peach, lemon).
///
/// Widget không tự chọn mã màu: lấy theo chỉ số ổn định của ghi chú qua
/// `AppNoteTones.of(context).toneAt(index)`.
@immutable
class AppNoteTones extends ThemeExtension<AppNoteTones> {
  const AppNoteTones({required this.tones});

  static const AppNoteTones light = AppNoteTones(
    tones: <AppNoteTone>[
      AppNoteTone(
        container: Color(0xFFE3F8EE),
        onContainer: Color(0xFF0B4A37),
        accent: Color(0xFF12855F),
      ),
      AppNoteTone(
        container: Color(0xFFE6EFFF),
        onContainer: Color(0xFF173A7A),
        accent: Color(0xFF2F6BFF),
      ),
      AppNoteTone(
        container: Color(0xFFEFE9FF),
        onContainer: Color(0xFF3B2670),
        accent: Color(0xFF7C5CFF),
      ),
      AppNoteTone(
        container: Color(0xFFFFEDE6),
        onContainer: Color(0xFF7A2E12),
        accent: Color(0xFFF2764A),
      ),
      AppNoteTone(
        container: Color(0xFFFFF6DB),
        onContainer: Color(0xFF6B4E00),
        accent: Color(0xFFC99700),
      ),
    ],
  );

  static const AppNoteTones dark = AppNoteTones(
    tones: <AppNoteTone>[
      AppNoteTone(
        container: Color(0xFF123B2F),
        onContainer: Color(0xFFA8EFD4),
        accent: Color(0xFF4FD1B0),
      ),
      AppNoteTone(
        container: Color(0xFF16294D),
        onContainer: Color(0xFFC7DBFF),
        accent: Color(0xFF7FA5FF),
      ),
      AppNoteTone(
        container: Color(0xFF26204A),
        onContainer: Color(0xFFDCD2FF),
        accent: Color(0xFFB39CFF),
      ),
      AppNoteTone(
        container: Color(0xFF3E2419),
        onContainer: Color(0xFFFFD6C4),
        accent: Color(0xFFFF9C73),
      ),
      AppNoteTone(
        container: Color(0xFF3B3213),
        onContainer: Color(0xFFFFE9A8),
        accent: Color(0xFFFFC94D),
      ),
    ],
  );

  final List<AppNoteTone> tones;

  static AppNoteTones of(BuildContext context) {
    return Theme.of(context).extension<AppNoteTones>() ?? light;
  }

  /// Chọn tông ổn định theo [index] (không đổi giữa các lần build).
  AppNoteTone toneAt(int index) => tones[index.abs() % tones.length];

  @override
  AppNoteTones copyWith({List<AppNoteTone>? tones}) {
    return AppNoteTones(tones: tones ?? this.tones);
  }

  @override
  AppNoteTones lerp(ThemeExtension<AppNoteTones>? other, double t) {
    if (other is! AppNoteTones || other.tones.length != tones.length) {
      return this;
    }
    return AppNoteTones(
      tones: <AppNoteTone>[
        for (int i = 0; i < tones.length; i++)
          AppNoteTone(
            container: Color.lerp(
              tones[i].container,
              other.tones[i].container,
              t,
            )!,
            onContainer: Color.lerp(
              tones[i].onContainer,
              other.tones[i].onContainer,
              t,
            )!,
            accent: Color.lerp(tones[i].accent, other.tones[i].accent, t)!,
          ),
      ],
    );
  }
}

/// Màu riêng của thư viện ghi chú và dock theo đặc tả thiết kế.
abstract final class NotesColors {
  static const cobalt = Color(0xFF2563EB);
  static const white = Color(0xFFFFFFFF);
  static const slate100 = Color(0xFFF1F5F9);
  static const slate200 = Color(0xFFE2E8F0);
  static const slate600 = Color(0xFF475569);
  static const slate500 = Color(0xFF64748B);
  static const slate700 = Color(0xFF334155);
  static const slate900 = Color(0xFF0F172A);
  static const blue50 = Color(0xFFEFF6FF);
  static const blue200 = Color(0xFFBFDBFE);
  static const blue700 = Color(0xFF1D4ED8);

  static Color accent(Brightness brightness) =>
      brightness == Brightness.dark ? purpleBright : cobalt;

  static Color chipText(Brightness brightness) =>
      brightness == Brightness.dark ? text : slate700;

  static Color selectedChip(Brightness brightness) =>
      brightness == Brightness.dark ? purple : slate900;

  static const background = Color(0xFF0F0F17);
  static const surface = Color(0xFF1B1B28);
  static const nav = Color(0xFF161622);
  static const border = Color(0xFF2B2B3D);
  static const navBorder = Color(0xFF2A2A3D);
  static const purple = Color(0xFF6D28D9);
  static const purpleBright = Color(0xFF7C3AED);
  static const text = Color(0xFFF3F4F6);
  static const muted = Color(0xFF9CA3AF);
  static const cardText = Color(0xFFE5E7EB);
  static const cardDate = Color(0xFFD1D5DB);
  static const action = Color(0xFF1E1B2E);
  static const actionBorder = Color(0xFF322C4A);
  static const actionIcons = [
    Color(0xFFC4B5FD),
    Color(0xFFA7F3D0),
    Color(0xFFFDE68A),
  ];
  static const lightActionIcons = [cobalt, slate600, cobalt];
  static const physicsGradient = [Color(0xFFE08600), Color(0xFFD97706)];
  static const physicsInk = Color(0xFF261705);
  static const quizBadge = Color(0x47000000);

  static Color navigation(Brightness brightness) =>
      brightness == Brightness.dark ? nav : white;
}

/// Dùng chung cách ghép nhãn chủ đề với màu và biểu tượng cho bộ lọc và thẻ.
enum NotesTopic {
  math(
    'Toán',
    Icons.functions,
    0xFF3B265E,
    0xFF2B213F,
    0xFFC4B5FD,
    0xFF2563EB,
    0xFFBFDBFE,
  ),
  physics(
    'Vật lý',
    Icons.bolt,
    0xFFD97706,
    0xFF5C3B14,
    0xFFFDE68A,
    0xFFFED7AA,
    0xFFC2410C,
  ),
  english(
    'Tiếng Anh',
    Icons.translate,
    0xFF353766,
    0xFF4D4119,
    0xFFE2E8F0,
    0xFFE0F2FE,
    0xFF0369A1,
  ),
  biology(
    'Sinh học',
    Icons.spa_outlined,
    0xFF214D3B,
    0xFF1E3F31,
    0xFFA7F3D0,
    0xFFCCFBF1,
    0xFF0F766E,
  ),
  history(
    'Lịch sử',
    Icons.history_edu_outlined,
    0xFF4A3328,
    0xFF4A3328,
    0xFFFDBA74,
    0xFFFDE68A,
    0xFFB45309,
  ),
  diary(
    'Nhật ký',
    Icons.auto_stories_outlined,
    0xFF2A2A3C,
    0xFF2A2A3C,
    0xFFD1D5DB,
    0xFFF1F5F9,
    0xFF475569,
  ),
  other(
    'Ghi chú',
    Icons.description_outlined,
    0xFF28283E,
    0xFF28283E,
    0xFFD1D5DB,
    0xFFF1F5F9,
    0xFF475569,
  );

  const NotesTopic(
    this.label,
    this.icon,
    this._card,
    this._chip,
    this._ink,
    this._light,
    this._lightInk,
  );

  final String label;
  final IconData icon;
  final int _card;
  final int _chip;
  final int _ink;
  final int _light;
  final int _lightInk;

  static NotesTopic fromLabel(String label) {
    final normalized = label.trim().toLowerCase();
    return switch (normalized) {
      'toán học' => math,
      _ => values.firstWhere(
        (topic) => topic.label.toLowerCase() == normalized,
        orElse: () => other,
      ),
    };
  }

  Color card(bool dark) => Color(dark ? _card : _light);
  Color chip(bool dark) => dark ? Color(_chip) : NotesColors.slate200;
  Color labelColor(bool dark) => Color(dark ? _ink : _lightInk);
}

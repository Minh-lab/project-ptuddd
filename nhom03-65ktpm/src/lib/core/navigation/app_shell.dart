import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/notes/presentation/pages/diary_page.dart';
import '../../features/notes/presentation/pages/notes_page.dart';
import '../../features/stats/presentation/bloc/stats_cubit.dart';
import '../../features/stats/presentation/pages/stats_page.dart';
import '../di/app_dependencies.dart';
import '../theme/app_theme.dart';
import '../widgets/notes_dock.dart';
import 'coming_soon_page.dart';

/// Khung điều hướng chính của app: 4 tab cố định theo mockup
/// `02_notes_google_keep_inspired.png` (thanh tab dưới đáy, icon + nhãn).
///
/// Nhóm đã chốt 4 tab đích: **Ghi chú – Nhật ký – Thống kê – Cài đặt**
/// Tab Ghi chú, Nhật ký và Thống kê đã có tính năng. Cài đặt dùng màn chờ.
///
/// `IndexedStack` giữ nguyên trạng thái từng tab (từ khoá tìm kiếm, kiểu
/// lưới/danh sách) khi người dùng chuyển qua lại.
class AppShell extends StatefulWidget {
  const AppShell({
    required this.notesDependencies,
    this.accountName,
    this.accountEmail,
    this.onThemeChanged,
    this.notesActions = const <Widget>[],
    super.key,
  });

  /// Dependency dùng chung cho tab Ghi chú (notes + quiz scores).
  final AppDependencies notesDependencies;

  /// Hành động trên AppBar của tab Ghi chú, do nơi điều hướng truyền vào
  /// (ví dụ nút đăng xuất). Nhờ vậy `core` không phải import feature auth.
  final List<Widget> notesActions;
  final String? accountName;
  final String? accountEmail;
  final VoidCallback? onThemeChanged;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.notes(Theme.of(context));
    final overlay = theme.brightness == Brightness.dark
        ? SystemUiOverlayStyle.light
        : SystemUiOverlayStyle.dark;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlay.copyWith(
        statusBarColor: theme.scaffoldBackgroundColor,
        systemNavigationBarColor: theme.scaffoldBackgroundColor,
        systemNavigationBarIconBrightness: theme.brightness == Brightness.dark
            ? Brightness.light
            : Brightness.dark,
      ),
      child: Scaffold(
        extendBody: true,
        backgroundColor: theme.scaffoldBackgroundColor,
        body: IndexedStack(
          index: _index,
          children: [
            NotesPage(
              dependencies: widget.notesDependencies,
              actions: widget.notesActions,
              accountName: widget.accountName,
              accountEmail: widget.accountEmail,
              onThemeChanged: widget.onThemeChanged,
            ),
            DiaryPage(dependencies: widget.notesDependencies),
            BlocProvider<StatsCubit>(
              create: (_) =>
                  StatsCubit(widget.notesDependencies.studyActivity)..load(),
              child: const StatsPage(),
            ),
            const ComingSoonPage(
              title: 'Cài đặt',
              icon: Icons.tune,
              message: 'Cài đặt tài khoản, giao diện và đồng bộ sẽ có tại đây khi tính năng hoàn thành.',
            ),
          ],
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        floatingActionButton: Theme(
          data: theme,
          child: NotesScanButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const ComingSoonPage(
                  title: 'Quét vở',
                  icon: Icons.document_scanner_outlined,
                  message: 'Tính năng quét vở sẽ có khi nhánh quét ảnh và OCR được tích hợp.',
                ),
              ),
            ),
          ),
        ),
        bottomNavigationBar: Theme(
          data: theme,
          child: NotesDock(
            selectedIndex: _index,
            onSelected: (index) {
              FocusManager.instance.primaryFocus?.unfocus();
              setState(() => _index = index);
            },
          ),
        ),
      ),
    );
  }
}

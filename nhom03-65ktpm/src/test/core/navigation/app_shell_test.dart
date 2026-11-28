import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_note/core/di/app_dependencies.dart';
import 'package:smart_note/core/navigation/app_shell.dart';
import 'package:smart_note/core/theme/app_theme.dart';
import 'package:smart_note/core/widgets/notes_dock.dart';
import 'package:smart_note/features/notes/presentation/bloc/notes_cubit.dart';

import '../../support/fake_auth_repository.dart';

void main() {
  late FakeAuthRepository authRepository;
  late AppDependencies dependencies;

  setUp(() {
    authRepository = FakeAuthRepository();
    dependencies = AppDependencies.create(
      executor: NativeDatabase.memory(),
      authRepository: authRepository,
    );
  });

  tearDown(() => authRepository.dispose());

  Future<void> pumpShell(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: BlocProvider<NotesCubit>(
          create: (_) => NotesCubit(dependencies.noteRepository)..load(),
          child: AppShell(notesDependencies: dependencies),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> disposeShell(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await tester.runAsync(dependencies.dispose);
  }

  testWidgets('Bottom navigation có đúng 4 tab theo thứ tự đã chốt', (
    WidgetTester tester,
  ) async {
    await pumpShell(tester);

    final Finder outerBar = find.byType(BottomAppBar);
    expect(outerBar, findsOneWidget);
    final scanButton = find.widgetWithIcon(
      FloatingActionButton,
      Icons.document_scanner_outlined,
    );
    expect(scanButton, findsOneWidget);
    expect(tester.getCenter(scanButton).dx, tester.getCenter(outerBar).dx);
    for (final String label in <String>[
      'Ghi chú',
      'Nhật ký',
      'Thống kê',
      'Cài đặt',
    ]) {
      expect(
        find.descendant(of: outerBar, matching: find.text(label)),
        findsOneWidget,
        reason: 'Thiếu tab $label',
      );
    }

    await tester.tap(scanButton);
    await tester.pumpAndSettle();
    expect(find.text('Quét vở'), findsOneWidget);

    await disposeShell(tester);
  });

  testWidgets('Mặc định mở tab Ghi chú', (WidgetTester tester) async {
    await pumpShell(tester);

    final NotesDock bar = tester.widget<NotesDock>(find.byType(NotesDock));
    expect(bar.selectedIndex, 0);
    expect(tester.widget<IndexedStack>(find.byType(IndexedStack)).index, 0);

    await disposeShell(tester);
  });

  testWidgets('Tab Nhật ký có tổng kết tuần và danh sách ngày', (
    WidgetTester tester,
  ) async {
    await pumpShell(tester);

    await tester.tap(find.text('Nhật ký').last);
    await tester.pumpAndSettle();

    expect(tester.widget<IndexedStack>(find.byType(IndexedStack)).index, 1);
    expect(find.text('1/7 ngày có nhật ký · 0 từ'), findsOneWidget);
    expect(find.byTooltip('Tuần trước'), findsOneWidget);
    expect(find.byTooltip('Chọn ngày'), findsOneWidget);

    await disposeShell(tester);
  });

  testWidgets('Tab Thống kê mở màn streak và thống kê tuần (#17)', (
    WidgetTester tester,
  ) async {
    await pumpShell(tester);

    await tester.tap(find.text('Thống kê').last);
    await tester.pumpAndSettle();

    expect(tester.widget<IndexedStack>(find.byType(IndexedStack)).index, 2);
    expect(find.text('ngày học liên tiếp'), findsOneWidget);
    expect(find.text('Ghi chú theo tuần'), findsOneWidget);

    await disposeShell(tester);
  });

  testWidgets(
    'Tab Cài đặt cũng là màn giữ chỗ, quay lại Ghi chú vẫn giữ dữ liệu',
    (WidgetTester tester) async {
      await pumpShell(tester);

      await tester.tap(find.text('Cài đặt').last);
      await tester.pumpAndSettle();
      expect(tester.widget<IndexedStack>(find.byType(IndexedStack)).index, 3);

      // Nhãn trên NotesDock nằm sau các trang trong cây widget, nên `.last`
      // là nhãn tab cần bấm.
      await tester.tap(find.text('Ghi chú').last);
      await tester.pumpAndSettle();
      expect(tester.widget<IndexedStack>(find.byType(IndexedStack)).index, 0);
      expect(find.text('Chưa có ghi chú nào'), findsOneWidget);

      await disposeShell(tester);
    },
  );
}

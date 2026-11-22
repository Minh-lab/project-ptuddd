import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_note/app.dart';
import 'package:smart_note/core/di/app_dependencies.dart';
import 'package:smart_note/core/error/failure.dart';

import '../../../support/fake_auth_repository.dart';

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

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(SmartNoteApp(dependencies: dependencies));
    await tester.pumpAndSettle();
  }

  /// Gỡ widget trước khi đóng database để cubit huỷ subscription, tránh lỗi
  /// "Timer is still pending".
  Future<void> disposeApp(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await tester.runAsync(dependencies.dispose);
  }

  Future<void> fillForm(
    WidgetTester tester, {
    String email = 'minh@example.com',
    String password = 'matkhau123',
  }) async {
    await tester.enterText(find.byType(TextFormField).at(0), email);
    await tester.enterText(find.byType(TextFormField).at(1), password);
  }

  testWidgets('Chưa đăng nhập thì hiển thị màn đăng nhập', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester);

    expect(find.text('Đăng nhập để đồng bộ ghi chú của bạn'), findsOneWidget);
    expect(find.text('Chưa có ghi chú nào'), findsNothing);

    await disposeApp(tester);
  });

  testWidgets('Đăng nhập đúng thì vào màn hình chính', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester);
    await fillForm(tester);

    await tester.tap(find.widgetWithText(FilledButton, 'Đăng nhập'));
    await tester.pumpAndSettle();

    expect(find.text('Chưa có ghi chú nào'), findsOneWidget);
    expect(find.text('Đăng nhập để đồng bộ ghi chú của bạn'), findsNothing);

    await disposeApp(tester);
  });

  testWidgets(
    'Sai mật khẩu thì hiển thị lỗi tiếng Việt và ở lại màn đăng nhập',
    (WidgetTester tester) async {
      authRepository.signInFailure = const AuthFailure(
        'Email hoặc mật khẩu không đúng.',
        code: 'wrong-password',
      );
      await pumpApp(tester);
      await fillForm(tester, password: 'saithat');

      await tester.tap(find.widgetWithText(FilledButton, 'Đăng nhập'));
      await tester.pumpAndSettle();

      expect(find.text('Email hoặc mật khẩu không đúng.'), findsOneWidget);
      expect(find.text('Chưa có ghi chú nào'), findsNothing);

      await disposeApp(tester);
    },
  );

  testWidgets('Email sai định dạng bị chặn trước khi gọi Firebase', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester);
    await fillForm(tester, email: 'khong-phai-email');

    await tester.tap(find.widgetWithText(FilledButton, 'Đăng nhập'));
    await tester.pumpAndSettle();

    expect(find.text('Email không hợp lệ.'), findsOneWidget);

    await disposeApp(tester);
  });
}

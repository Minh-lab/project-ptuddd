import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_note/app.dart';
import 'package:smart_note/core/di/app_dependencies.dart';
import 'package:smart_note/core/error/failure.dart';
import 'package:smart_note/features/auth/domain/entities/app_user.dart';
import 'package:smart_note/features/notes/domain/entities/note.dart';
import 'package:smart_note/features/notes/domain/entities/note_share.dart';
import 'package:smart_note/features/notes/domain/repositories/note_share_repository.dart';
import 'package:smart_note/features/notes/presentation/widgets/note_share_dialog.dart';

import '../../../support/fake_auth_repository.dart';

void main() {
  final note = _note();

  testWidgets('Không tạo liên kết nếu chưa nhập UID người nhận', (
    WidgetTester tester,
  ) async {
    final repository = _FakeNoteShareRepository();
    await _showShareDialog(tester, note, repository);

    await tester.tap(find.text('Tạo liên kết chỉ xem'));
    await tester.pumpAndSettle();

    expect(find.text('Nhập Firebase UID của người nhận.'), findsOneWidget);
    expect(repository.createdRecipientId, isNull);
  });

  testWidgets('Tạo liên kết gửi UID và hiển thị URL chỉ xem', (
    WidgetTester tester,
  ) async {
    final repository = _FakeNoteShareRepository();
    await _showShareDialog(tester, note, repository);

    await tester.enterText(
      find.byKey(const ValueKey<String>('share-recipient-uid')),
      'uid-recipient',
    );
    await tester.tap(find.text('Tạo liên kết chỉ xem'));
    await tester.pumpAndSettle();

    expect(repository.createdRecipientId, 'uid-recipient');
    expect(find.text('smartnote://share/share-1'), findsOneWidget);
  });

  testWidgets('Deep link mở bản chụp ở chế độ chỉ xem cho UID đang đăng nhập', (
    WidgetTester tester,
  ) async {
    final authRepository = FakeAuthRepository(
      initialUser: const AppUser(
        id: 'uid-recipient',
        email: 'recipient@example.com',
      ),
    );
    final shareRepository = _FakeNoteShareRepository();
    final dependencies = AppDependencies.create(
      executor: NativeDatabase.memory(),
      authRepository: authRepository,
      noteShareRepository: shareRepository,
    );

    try {
      await tester.pumpWidget(
        SmartNoteApp(
          dependencies: dependencies,
          initialLink: Uri.parse('smartnote://share/share-1'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Bản chụp ghi chú'), findsOneWidget);
      expect(find.text('Nội dung chỉ xem'), findsOneWidget);
      expect(shareRepository.openedRecipientId, 'uid-recipient');
      expect(find.byTooltip('Sửa ghi chú'), findsNothing);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await tester.runAsync(dependencies.dispose);
      await tester.runAsync(authRepository.dispose);
    }
  });

  testWidgets('UID khác không xem được bản chụp qua deep link', (
    WidgetTester tester,
  ) async {
    final authRepository = FakeAuthRepository(
      initialUser: const AppUser(
        id: 'uid-not-recipient',
        email: 'other@example.com',
      ),
    );
    final shareRepository = _FakeNoteShareRepository();
    final dependencies = AppDependencies.create(
      executor: NativeDatabase.memory(),
      authRepository: authRepository,
      noteShareRepository: shareRepository,
    );

    try {
      await tester.pumpWidget(
        SmartNoteApp(
          dependencies: dependencies,
          initialLink: Uri.parse('smartnote://share/share-1'),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Liên kết không dành cho tài khoản này.'),
        findsOneWidget,
      );
      expect(find.text('Nội dung chỉ xem'), findsNothing);
      expect(shareRepository.openedRecipientId, 'uid-not-recipient');
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await tester.runAsync(dependencies.dispose);
      await tester.runAsync(authRepository.dispose);
    }
  });
}

Future<void> _showShareDialog(
  WidgetTester tester,
  Note note,
  NoteShareRepository repository,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => NoteShareDialog(
                note: note,
                ownerId: 'uid-owner',
                repository: repository,
              ),
            ),
            child: const Text('Chia sẻ'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Chia sẻ'));
  await tester.pumpAndSettle();
}

Note _note() {
  final now = DateTime(2026, 11, 26);
  return Note(
    id: 'local-note-id',
    title: 'Bản chụp ghi chú',
    content: 'Nội dung chỉ xem',
    kind: NoteKind.note,
    createdAt: now,
    updatedAt: now,
  );
}

class _FakeNoteShareRepository implements NoteShareRepository {
  String? createdRecipientId;
  String? openedRecipientId;
  final List<NoteShare> shares = <NoteShare>[];

  @override
  Future<List<NoteShare>> listForNote({
    required String sourceNoteId,
    required String ownerId,
  }) async {
    return List<NoteShare>.of(shares);
  }

  @override
  Future<NoteShare> create({
    required Note note,
    required String recipientId,
  }) async {
    createdRecipientId = recipientId;
    final share = NoteShare(
      id: 'share-1',
      noteId: 'snapshot-1',
      sourceNoteId: note.id,
      ownerId: 'uid-owner',
      recipientId: recipientId,
      createdAt: DateTime(2026, 11, 26),
    );
    shares.add(share);
    return share;
  }

  @override
  Future<void> revoke(String shareId) async {
    shares.removeWhere((share) => share.id == shareId);
  }

  @override
  Future<Note> openSharedNote({
    required String shareId,
    required String recipientId,
  }) async {
    openedRecipientId = recipientId;
    if (recipientId != 'uid-recipient') {
      throw const DatabaseFailure('Liên kết không dành cho tài khoản này.');
    }
    return _note();
  }
}

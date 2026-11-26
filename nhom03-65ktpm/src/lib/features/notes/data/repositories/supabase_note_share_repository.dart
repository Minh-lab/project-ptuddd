import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/failure.dart';
import '../../domain/entities/note.dart';
import '../../domain/entities/note_share.dart';
import '../../domain/entities/received_note_share.dart';
import '../../domain/repositories/note_share_repository.dart';
import '../models/supabase_note_mapper.dart';

class SupabaseNoteShareRepository implements NoteShareRepository {
  SupabaseNoteShareRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<NoteShare>> listForNote({
    required String sourceNoteId,
    required String ownerId,
  }) async {
    try {
      await _syncProfile();
      final rows = await _client
          .from('note_shares')
          .select(
            'id, note_id, source_note_id, owner_id, shared_with, '
            'shared_with_email, created_at',
          )
          .eq('source_note_id', sourceNoteId)
          .eq('owner_id', ownerId)
          .order('created_at');
      return rows.map(_shareFromRow).toList();
    } on PostgrestException catch (error) {
      throw _mapPostgrestException(error);
    }
  }

  @override
  Future<List<ReceivedNoteShare>> listReceived() async {
    try {
      await _syncProfile();
      final result = await _client.rpc('list_received_note_shares');
      if (result is! List) {
        throw const FormatException(
          'Supabase trả về danh sách ghi chú được chia sẻ không hợp lệ.',
        );
      }
      return result.map((dynamic value) {
        if (value is! Map<String, dynamic>) {
          throw const FormatException(
            'Supabase trả về bản ghi chia sẻ không hợp lệ.',
          );
        }
        return ReceivedNoteShare(
          id: _stringField(value, 'id'),
          noteId: _stringField(value, 'note_id'),
          ownerId: _stringField(value, 'owner_id'),
          ownerEmail: _optionalStringField(value, 'owner_email') ?? 'SmartNote',
          title: _stringField(value, 'title'),
          kind: NoteKind.fromStorage(_stringField(value, 'kind')),
          createdAt: DateTime.parse(_stringField(value, 'created_at')),
        );
      }).toList();
    } on PostgrestException catch (error) {
      throw _mapPostgrestException(error);
    }
  }

  @override
  Future<NoteShare> create({
    required Note note,
    required String recipientEmail,
  }) async {
    try {
      final result = await _client.rpc(
        'create_note_share_by_email',
        params: <String, dynamic>{
          'p_source_note_id': note.id,
          'p_recipient_email': recipientEmail.trim().toLowerCase(),
          'p_title': note.title,
          'p_content': note.content,
          'p_kind': note.kind.name,
          'p_tags': note.tags,
        },
      );
      final row = _singleRow(result);
      if (row == null) {
        throw const FormatException('Supabase trả về liên kết không hợp lệ.');
      }
      return _shareFromRow(row);
    } on PostgrestException catch (error) {
      throw _mapPostgrestException(error);
    }
  }

  @override
  Future<void> revoke(String shareId) async {
    try {
      await _client.rpc(
        'revoke_note_share',
        params: <String, dynamic>{'p_share_id': shareId},
      );
    } on PostgrestException catch (error) {
      throw _mapPostgrestException(error);
    }
  }

  @override
  Future<Note> openSharedNote({
    required String shareId,
    required String recipientId,
  }) async {
    if (recipientId.trim().isEmpty) {
      throw const DatabaseFailure('Cần đăng nhập để mở liên kết chia sẻ.');
    }

    try {
      final result = await _client.rpc(
        'open_note_share',
        params: <String, dynamic>{'p_share_id': shareId},
      );
      final row = _singleRow(result);
      if (row == null) {
        throw const DatabaseFailure(
          'Liên kết không tồn tại, đã bị thu hồi hoặc không dành cho tài khoản này.',
        );
      }
      return SupabaseNoteMapper.fromRow(row);
    } on PostgrestException catch (error) {
      throw _mapPostgrestException(error);
    }
  }

  NoteShare _shareFromRow(Map<String, dynamic> row) {
    return NoteShare(
      id: _stringField(row, 'id'),
      noteId: _stringField(row, 'note_id'),
      sourceNoteId: _stringField(row, 'source_note_id'),
      ownerId: _stringField(row, 'owner_id'),
      recipientId: _stringField(row, 'shared_with'),
      recipientEmail: _optionalStringField(row, 'shared_with_email'),
      createdAt: DateTime.parse(_stringField(row, 'created_at')),
    );
  }

  String _stringField(Map<String, dynamic> row, String name) {
    final value = row[name];
    if (value is String) return value;
    throw FormatException('Supabase thiếu trường "$name".');
  }

  String? _optionalStringField(Map<String, dynamic> row, String name) {
    final value = row[name];
    if (value == null) return null;
    if (value is String) return value;
    throw FormatException('Supabase trả về trường "$name" không hợp lệ.');
  }

  Future<void> _syncProfile() async {
    await _client.rpc('sync_my_profile');
  }

  Map<String, dynamic>? _singleRow(Object? result) {
    if (result is Map<String, dynamic>) return result;
    if (result is List &&
        result.length == 1 &&
        result.single is Map<String, dynamic>) {
      return result.single as Map<String, dynamic>;
    }
    return null;
  }

  DatabaseFailure _mapPostgrestException(PostgrestException error) {
    if (error.code == '42501' || error.code == 'PGRST301') {
      return const DatabaseFailure(
        'Supabase từ chối quyền truy cập. Kiểm tra cấu hình Firebase third-party auth, claim role=authenticated và chính sách RLS.',
      );
    }
    if (error.code == 'P0002') {
      return const DatabaseFailure(
        'Không tìm thấy tài khoản SmartNote với email này. Người nhận cần đăng nhập ứng dụng ít nhất một lần trước khi được chia sẻ.',
      );
    }
    if (error.code == '22023') {
      return const DatabaseFailure(
        'Email người nhận không hợp lệ hoặc bạn đang chia sẻ cho chính mình.',
      );
    }
    return DatabaseFailure('Lỗi Supabase: ${error.message}');
  }
}

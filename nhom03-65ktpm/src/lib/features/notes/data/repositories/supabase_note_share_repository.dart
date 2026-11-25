import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/failure.dart';
import '../../domain/entities/note.dart';
import '../../domain/entities/note_share.dart';
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
      final rows = await _client
          .from('note_shares')
          .select(
            'id, note_id, source_note_id, owner_id, shared_with, created_at',
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
  Future<NoteShare> create({
    required Note note,
    required String recipientId,
  }) async {
    try {
      final result = await _client.rpc(
        'create_note_share',
        params: <String, dynamic>{
          'p_source_note_id': note.id,
          'p_shared_with': recipientId,
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
    try {
      final share = await _client
          .from('note_shares')
          .select('note_id')
          .eq('id', shareId)
          .eq('shared_with', recipientId)
          .maybeSingle();
      if (share == null) {
        throw const DatabaseFailure(
          'Liên kết không tồn tại, đã bị thu hồi hoặc không dành cho tài khoản này.',
        );
      }

      final row = await _client
          .from('notes')
          .select(
            'id, title, content, kind, created_at, updated_at, subject_id, tags',
          )
          .eq('id', share['note_id'])
          .maybeSingle();
      if (row == null) {
        throw const DatabaseFailure('Không tìm thấy bản ghi chú được chia sẻ.');
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
      createdAt: DateTime.parse(_stringField(row, 'created_at')),
    );
  }

  String _stringField(Map<String, dynamic> row, String name) {
    final value = row[name];
    if (value is String) return value;
    throw FormatException('Supabase thiếu trường "$name".');
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
    return DatabaseFailure('Lỗi Supabase: ${error.message}');
  }
}

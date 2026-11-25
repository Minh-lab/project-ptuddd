import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../core/error/failure.dart';
import '../../../domain/entities/note.dart';
import '../../models/supabase_note_mapper.dart';
import 'note_remote_data_source.dart';

class SupabaseNoteDataSource implements NoteRemoteDataSource {
  SupabaseNoteDataSource(this._client);

  final SupabaseClient _client;

  @override
  Future<List<Note>> fetchNotes(String userId) async {
    try {
      final rows = await _client
          .from('notes')
          .select(
            'id, user_id, title, content, kind, created_at, updated_at, '
            'subject_id, tags',
          )
          .eq('user_id', userId)
          .isFilter('deleted_at', null)
          .order('updated_at', ascending: false);
      return rows
          .map((Map<String, dynamic> row) => SupabaseNoteMapper.fromRow(row))
          .toList();
    } on PostgrestException catch (error) {
      if (error.code == '42501' || error.code == 'PGRST301') {
        throw const DatabaseFailure(
          'Supabase từ chối đọc ghi chú. Kiểm tra Firebase third-party auth, claim role=authenticated và chính sách RLS.',
        );
      }
      throw DatabaseFailure(
        'Không tải được ghi chú từ Supabase: ${error.message}',
      );
    }
  }
}

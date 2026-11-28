import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/subjects_dao.dart';

/// Reconciles the account's subjects before publishing notes that refer to them.
class SupabaseSubjectSync {
  SupabaseSubjectSync(this._client);

  final SupabaseClient _client;

  Future<void> reconcile(String userId, SubjectsDao dao) async {
    final local = await dao.syncSnapshot(userId);
    final response = await _client
        .from('subjects')
        .select()
        .eq('user_id', userId);
    final incoming = response.map(_fromRemote).toList();
    final remoteById = {for (final subject in incoming) subject.id: subject};

    for (final subject in local) {
      final remote = remoteById[subject.id];
      if (remote != null && !subject.updatedAt.isAfter(remote.updatedAt)) {
        continue;
      }
      final values = <String, Object?>{
        'id': subject.id,
        'user_id': userId,
        'name': subject.name,
        'color': subject.color,
        'created_at': subject.createdAt.toUtc().toIso8601String(),
        'updated_at': subject.updatedAt.toUtc().toIso8601String(),
        'deleted_at': subject.deletedAt?.toUtc().toIso8601String(),
      };
      if (remote == null) {
        await _client
            .from('subjects')
            .upsert(values, onConflict: 'id', ignoreDuplicates: true);
      }
      // The server checks the timestamp again in case another device wrote
      // a newer version after this device fetched the subjects.
      await _client
          .from('subjects')
          .update(values)
          .eq('user_id', userId)
          .eq('id', subject.id)
          .lt('updated_at', subject.updatedAt.toUtc().toIso8601String());
    }
    await dao.applyRemoteSubjects(incoming);
  }

  SubjectRow _fromRemote(Map<String, dynamic> row) => SubjectRow(
    id: row['id'] as String,
    name: row['name'] as String,
    color: row['color'] as String?,
    createdAt: DateTime.parse(row['created_at'] as String),
    updatedAt: DateTime.parse(row['updated_at'] as String),
    deletedAt: DateTime.tryParse(row['deleted_at'] as String? ?? ''),
  );
}

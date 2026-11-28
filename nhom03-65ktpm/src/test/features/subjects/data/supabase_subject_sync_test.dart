import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:smart_note/core/database/app_database.dart';
import 'package:smart_note/core/database/notes_dao.dart';
import 'package:smart_note/core/database/subjects_dao.dart';
import 'package:smart_note/core/utils/uuid_format.dart';
import 'package:smart_note/features/subjects/data/repositories/supabase_subject_sync.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test(
    'mã môn cũ được chuyển sang UUID và thiết bị thứ hai đọc được môn',
    () async {
      final first = AppDatabase(NativeDatabase.memory());
      final second = AppDatabase(NativeDatabase.memory());
      addTearDown(first.close);
      addTearDown(second.close);
      final cloud = <Map<String, dynamic>>[];
      final client = SupabaseClient(
        'https://example.test',
        'test-key',
        httpClient: MockClient((request) async {
          expect(request.url.path, '/rest/v1/subjects');
          if (request.method == 'GET') {
            return http.Response(
              jsonEncode(cloud),
              200,
              request: request,
              headers: {'content-type': 'application/json; charset=utf-8'},
            );
          }
          if (request.method == 'POST') {
            cloud.add(jsonDecode(request.body) as Map<String, dynamic>);
          }
          return http.Response('', 204, request: request);
        }),
      );
      addTearDown(client.dispose);
      final firstSubjects = SubjectsDao(first);
      await firstSubjects.insertSubject(
        SubjectsCompanion.insert(id: 'old-id', name: 'Toán'),
      );
      await NotesDao(first).insertNote(
        const NotesCompanion(id: Value('note-1'), subjectId: Value('old-id')),
      );

      final sync = SupabaseSubjectSync(client);
      await sync.reconcile('firebase-uid', firstSubjects);
      await sync.reconcile('firebase-uid', SubjectsDao(second));

      final note = (await NotesDao(first).findById('note-1'))!;
      final subject = (await SubjectsDao(second).getAll()).single;
      expect(isUuid(note.subjectId), isTrue);
      expect(subject.id, note.subjectId);
      expect(subject.name, 'Toán');
      expect(cloud.single['user_id'], 'firebase-uid');
    },
  );
}

import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_note/features/notes/domain/entities/note.dart';
import 'package:smart_note/features/notes/presentation/services/word_export_service.dart';

void main() {
  test('xuất nhiều ghi chú thành DOCX có môn, ngày và tiếng Việt', () async {
    final directory = await Directory.systemTemp.createTemp('smartnote-docx-');
    addTearDown(() => directory.delete(recursive: true));
    final service = WordExportService(
      destination: directory,
      clock: () => DateTime(2026, 11, 27, 10),
    );
    final notes = <Note>[
      Note(
        id: 'note-1',
        title: 'Giải tích & đạo hàm',
        content: 'Nội dung tiếng Việt <đúng dấu>.',
        kind: NoteKind.note,
        createdAt: DateTime(2026, 11, 26),
        updatedAt: DateTime(2026, 11, 27),
        tags: const <String>['Toán'],
      ),
      Note(
        id: 'note-2',
        title: 'Vật lý',
        content: 'Định luật Faraday.',
        kind: NoteKind.note,
        createdAt: DateTime(2026, 11, 25),
        updatedAt: DateTime(2026, 11, 27),
        subjectId: 'Vật lý',
      ),
    ];

    final path = await service.exportNotes(notes);
    final archive = ZipDecoder().decodeBytes(await File(path).readAsBytes());
    final document = utf8
        .decode(archive.findFile('word/document.xml')!.content as List<int>)
        .replaceAll('&#47;', '/');

    expect(archive.findFile('[Content_Types].xml'), isNotNull);
    expect(document, contains('Giải tích &amp; đạo hàm'));
    expect(document, contains('Môn học: Toán'));
    expect(document, contains('Ngày: 26/11/2026'));
    expect(document, contains('Nội dung tiếng Việt &lt;đúng dấu&gt;.'));
    expect(document, contains('Môn học: Vật lý'));
    expect(document, contains('Ngày: 25/11/2026'));
  });
}

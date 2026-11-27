import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';

import '../../domain/entities/note.dart';

class WordExportService {
  WordExportService({this.destination, DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final Directory? destination;
  final DateTime Function() _clock;

  Future<String> exportNotes(List<Note> notes) async {
    if (notes.isEmpty) throw Exception('Chưa chọn ghi chú');

    final now = _clock();
    final archive = Archive();
    archive
      ..addFile(_textFile('[Content_Types].xml', _contentTypesXml))
      ..addFile(_textFile('_rels/.rels', _rootRelsXml))
      ..addFile(_textFile('word/document.xml', _documentXml(notes, now)));

    final bytes = ZipEncoder().encode(archive);
    final directory = destination ?? await _defaultDirectory();
    await directory.create(recursive: true);
    final file = File(
      '${directory.path}${Platform.pathSeparator}SmartNote_${now.millisecondsSinceEpoch}.docx',
    );
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  Future<Directory> _defaultDirectory() async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      return await getDownloadsDirectory() ??
          await getApplicationDocumentsDirectory();
    }
    return getApplicationDocumentsDirectory();
  }

  String _documentXml(List<Note> notes, DateTime exportedAt) {
    final paragraphs = <String>[
      _paragraph('SMARTNOTE - GHI CHÚ ĐÃ XUẤT', bold: true, size: '32'),
      _paragraph('Ngày xuất: ${_formatDate(exportedAt)}'),
    ];
    for (final note in notes) {
      final subject = note.subjectId?.trim();
      final subjectName = subject != null && subject.isNotEmpty
          ? subject
          : note.tags.isNotEmpty
          ? note.tags.first
          : 'Chưa phân loại';
      paragraphs
        ..add(_paragraph(note.displayTitle, bold: true, size: '28'))
        ..add(_paragraph('Môn học: $subjectName'))
        ..add(_paragraph('Ngày: ${_formatDate(note.createdAt)}'))
        ..addAll(
          note.content
              .split('\n')
              .map((String line) => _paragraph(line.isEmpty ? ' ' : line)),
        )
        ..add(_paragraph('', size: '8'));
    }
    return '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:body>${paragraphs.join()}<w:sectPr/></w:body>
</w:document>''';
  }

  ArchiveFile _textFile(String name, String content) {
    final bytes = utf8.encode(content);
    return ArchiveFile(name, bytes.length, bytes);
  }

  String _formatDate(DateTime value) {
    final local = value.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/${local.year}';
  }

  String _paragraph(String text, {bool bold = false, String size = '24'}) {
    final escaped = const HtmlEscape().convert(text);
    final b = bold ? '<w:b/>' : '';
    return '<w:p><w:r><w:rPr>$b<w:sz w:val="$size"/></w:rPr><w:t xml:space="preserve">$escaped</w:t></w:r></w:p>';
  }

  static const String _contentTypesXml =
      '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
</Types>''';

  static const String _rootRelsXml =
      '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
</Relationships>''';
}

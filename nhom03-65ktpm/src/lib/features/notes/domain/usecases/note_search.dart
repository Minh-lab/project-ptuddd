import '../entities/note.dart';

/// Kết quả một đoạn khớp, dùng chỉ số UTF-16 của chuỗi gốc.
class NoteSearchRange {
  const NoteSearchRange({required this.start, required this.end});

  final int start;
  final int end;
}

/// Tìm ghi chú không phân biệt hoa thường và dấu tiếng Việt.
class NoteSearch {
  const NoteSearch();

  static const Map<String, String> _foldedCharacters = <String, String>{
    'à': 'a',
    'á': 'a',
    'ạ': 'a',
    'ả': 'a',
    'ã': 'a',
    'â': 'a',
    'ầ': 'a',
    'ấ': 'a',
    'ậ': 'a',
    'ẩ': 'a',
    'ẫ': 'a',
    'ă': 'a',
    'ằ': 'a',
    'ắ': 'a',
    'ặ': 'a',
    'ẳ': 'a',
    'ẵ': 'a',
    'è': 'e',
    'é': 'e',
    'ẹ': 'e',
    'ẻ': 'e',
    'ẽ': 'e',
    'ê': 'e',
    'ề': 'e',
    'ế': 'e',
    'ệ': 'e',
    'ể': 'e',
    'ễ': 'e',
    'ì': 'i',
    'í': 'i',
    'ị': 'i',
    'ỉ': 'i',
    'ĩ': 'i',
    'ò': 'o',
    'ó': 'o',
    'ọ': 'o',
    'ỏ': 'o',
    'õ': 'o',
    'ô': 'o',
    'ồ': 'o',
    'ố': 'o',
    'ộ': 'o',
    'ổ': 'o',
    'ỗ': 'o',
    'ơ': 'o',
    'ờ': 'o',
    'ớ': 'o',
    'ợ': 'o',
    'ở': 'o',
    'ỡ': 'o',
    'ù': 'u',
    'ú': 'u',
    'ụ': 'u',
    'ủ': 'u',
    'ũ': 'u',
    'ư': 'u',
    'ừ': 'u',
    'ứ': 'u',
    'ự': 'u',
    'ử': 'u',
    'ữ': 'u',
    'ỳ': 'y',
    'ý': 'y',
    'ỵ': 'y',
    'ỷ': 'y',
    'ỹ': 'y',
    'đ': 'd',
  };

  List<Note> call(Iterable<Note> notes, String query) {
    final normalizedQuery = _normalize(query.trim());
    if (normalizedQuery.isEmpty) return notes.toList();

    return notes.where((Note note) {
      return _normalize(note.title).contains(normalizedQuery) ||
          _normalize(note.content).contains(normalizedQuery);
    }).toList();
  }

  List<NoteSearchRange> highlightRanges(String text, String query) {
    final normalizedQuery = _normalize(query.trim());
    if (normalizedQuery.isEmpty) return const <NoteSearchRange>[];

    final normalizedText = _normalizeWithRanges(text);
    final ranges = <NoteSearchRange>[];
    var searchFrom = 0;
    while (searchFrom < normalizedText.value.length) {
      final matchStart = normalizedText.value.indexOf(
        normalizedQuery,
        searchFrom,
      );
      if (matchStart < 0) break;

      final matchEnd = matchStart + normalizedQuery.length;
      ranges.add(
        NoteSearchRange(
          start: normalizedText.sourceRanges[matchStart].start,
          end: normalizedText.sourceRanges[matchEnd - 1].end,
        ),
      );
      searchFrom = matchEnd;
    }
    return ranges;
  }

  static String _normalize(String value) {
    final result = StringBuffer();
    for (final rune in value.runes) {
      if (_isCombiningMark(rune)) continue;
      result.write(_foldRune(rune));
    }
    return result.toString();
  }

  static _NormalizedText _normalizeWithRanges(String value) {
    final normalized = StringBuffer();
    final sourceRanges = <_SourceRange>[];
    var sourceOffset = 0;

    for (final rune in value.runes) {
      final character = String.fromCharCode(rune);
      final sourceEnd = sourceOffset + character.length;

      if (_isCombiningMark(rune)) {
        if (sourceRanges.isNotEmpty) {
          final previous = sourceRanges.last;
          sourceRanges[sourceRanges.length - 1] = _SourceRange(
            previous.start,
            sourceEnd,
          );
        }
      } else {
        final folded = _foldRune(rune);
        normalized.write(folded);
        for (var index = 0; index < folded.length; index++) {
          sourceRanges.add(_SourceRange(sourceOffset, sourceEnd));
        }
      }

      sourceOffset = sourceEnd;
    }

    return _NormalizedText(normalized.toString(), sourceRanges);
  }

  static String _foldRune(int rune) {
    final lowerCase = String.fromCharCode(rune).toLowerCase();
    final result = StringBuffer();
    for (final lowerRune in lowerCase.runes) {
      if (_isCombiningMark(lowerRune)) continue;
      final character = String.fromCharCode(lowerRune);
      result.write(_foldedCharacters[character] ?? character);
    }
    return result.toString();
  }

  static bool _isCombiningMark(int rune) => rune >= 0x0300 && rune <= 0x036f;
}

class _NormalizedText {
  const _NormalizedText(this.value, this.sourceRanges);

  final String value;
  final List<_SourceRange> sourceRanges;
}

class _SourceRange {
  const _SourceRange(this.start, this.end);

  final int start;
  final int end;
}

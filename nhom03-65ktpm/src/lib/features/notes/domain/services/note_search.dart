import '../entities/note.dart';

/// Tìm ghi chú không phân biệt chữ hoa/thường hoặc dấu tiếng Việt.
abstract final class NoteSearch {
  static final Map<int, int> _foldedRunes = _createFoldedRunes();

  static List<Note> filter(List<Note> notes, String query) {
    final normalizedQuery = normalize(query.trim());
    if (normalizedQuery.isEmpty) return notes;

    return notes
        .where(
          (note) =>
              normalize(note.title).contains(normalizedQuery) ||
              normalize(note.content).contains(normalizedQuery),
        )
        .toList();
  }

  /// Vị trí bắt đầu các kết quả trong chuỗi gốc, dùng để tô sáng từ khóa.
  static List<int> matchStarts(String text, String query) {
    final normalizedText = normalize(text);
    final normalizedQuery = normalize(query.trim());
    if (normalizedQuery.isEmpty) return const <int>[];

    final starts = <int>[];
    var offset = 0;
    while (true) {
      final start = normalizedText.indexOf(normalizedQuery, offset);
      if (start < 0) return starts;
      starts.add(start);
      offset = start + normalizedQuery.length;
    }
  }

  static String normalize(String value) {
    final buffer = StringBuffer();
    for (final rune in value.toLowerCase().runes) {
      buffer.writeCharCode(_foldedRunes[rune] ?? rune);
    }
    return buffer.toString();
  }

  static Map<int, int> _createFoldedRunes() {
    const groups = <String, String>{
      'a': 'àáạảãâầấậẩẫăằắặẳẵ',
      'd': 'đ',
      'e': 'èéẹẻẽêềếệểễ',
      'i': 'ìíịỉĩ',
      'o': 'òóọỏõôồốộổỗơờớợởỡ',
      'u': 'ùúụủũưừứựửữ',
      'y': 'ỳýỵỷỹ',
    };
    final folded = <int, int>{};
    for (final entry in groups.entries) {
      for (final rune in entry.value.runes) {
        folded[rune] = entry.key.codeUnitAt(0);
      }
    }
    return Map<int, int>.unmodifiable(folded);
  }
}

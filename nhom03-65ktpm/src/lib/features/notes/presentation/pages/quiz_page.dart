import 'dart:math';

import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/quiz_scores_dao.dart';
import '../../domain/entities/note.dart';
import '../bloc/notes_cubit.dart';
import '../bloc/notes_state.dart';

class _QuizQuestion {
  const _QuizQuestion({
    required this.prompt,
    required this.options,
    required this.correctIndex,
  });

  final String prompt;
  final List<String> options;
  final int correctIndex;
}

class QuizPage extends StatefulWidget {
  const QuizPage({
    required this.notesCubit,
    required this.scoresDao,
    super.key,
  });

  final NotesCubit notesCubit;
  final QuizScoresDao scoresDao;

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  String? _selectedNoteId;
  List<_QuizQuestion> _questions = <_QuizQuestion>[];
  final Map<int, int> _answers = <int, int>{};
  bool _submitted = false;
  List<QuizScoreRow> _history = <QuizScoreRow>[];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final rows = await widget.scoresDao.getAll();
    if (mounted) setState(() => _history = rows);
  }

  List<_QuizQuestion> _generateQuestions(Note note) {
    final sentences = note.content
        .replaceAll('\n', ' ')
        .split(RegExp(r'[.!?\n]+'))
        .map((String value) => value.trim())
        .where((String value) => value.split(RegExp(r'\s+')).length >= 4)
        .toList();
    if (sentences.isEmpty) return <_QuizQuestion>[];

    final random = Random(note.id.hashCode);
    final pool = <String>{
      for (final sentence in sentences)
        ...sentence
            .replaceAll(RegExp(r'[^\w\sÀ-ỹ]'), '')
            .split(RegExp(r'\s+'))
            .where((String word) => word.length >= 4),
    }.toList();

    final result = <_QuizQuestion>[];
    for (final sentence in sentences.take(5)) {
      final words = sentence
          .replaceAll(RegExp(r'[^\w\sÀ-ỹ]'), '')
          .split(RegExp(r'\s+'))
          .where((String word) => word.length >= 4)
          .toList();
      if (words.isEmpty) continue;
      words.shuffle(random);
      final answer = words.first;
      final distractors = pool.where((String word) => word != answer).toList()
        ..shuffle(random);
      final options = <String>[answer, ...distractors.take(3)]..shuffle(random);
      final prompt = sentence.replaceFirst(
        RegExp(RegExp.escape(answer), caseSensitive: false),
        '______',
      );
      result.add(
        _QuizQuestion(
          prompt: 'Điền từ còn thiếu: $prompt',
          options: options,
          correctIndex: options.indexOf(answer),
        ),
      );
    }
    return result;
  }

  Future<void> _submit(Note note) async {
    final correct = _questions.indexed.where((entry) {
      final index = entry.$1;
      final question = entry.$2;
      return _answers[index] == question.correctIndex;
    }).length;

    await widget.scoresDao.insertScore(
      QuizScoresCompanion.insert(
        id: '${DateTime.now().microsecondsSinceEpoch}',
        noteId: note.id,
        noteTitle: Value(note.displayTitle),
        correctAnswers: correct,
        totalQuestions: _questions.length,
        completedAt: Value(DateTime.now()),
      ),
    );
    setState(() => _submitted = true);
    await _loadHistory();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotesCubit, NotesState>(
      bloc: widget.notesCubit,
      builder: (_, NotesState state) {
        final notes = state.notes
            .where((Note note) => note.content.trim().isNotEmpty)
            .toList();
        final matchingNotes = notes
            .where((Note item) => item.id == _selectedNoteId)
            .toList();
        final note = matchingNotes.isEmpty ? null : matchingNotes.first;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            DropdownButtonFormField<String>(
              initialValue: _selectedNoteId,
              decoration: const InputDecoration(
                labelText: 'Chọn ghi chú để tạo đề',
                border: OutlineInputBorder(),
              ),
              items: notes
                  .map(
                    (Note item) => DropdownMenuItem<String>(
                      value: item.id,
                      child: Text(
                        item.displayTitle,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (String? id) {
                if (id == null) return;
                final selected = notes.firstWhere((item) => item.id == id);
                setState(() {
                  _selectedNoteId = id;
                  _questions = _generateQuestions(selected);
                  _answers.clear();
                  _submitted = false;
                });
              },
            ),
            const SizedBox(height: 16),
            if (_questions.isEmpty)
              const _QuizMessage(
                text: 'Ghi chú cần có ít nhất một câu đủ dài để tạo câu hỏi.',
              ),
            for (var i = 0; i < _questions.length; i++)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Câu ${i + 1}: ${_questions[i].prompt}',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      RadioGroup<int>(
                        groupValue: _answers[i],
                        onChanged: _submitted
                            ? (_) {}
                            : (int? value) => setState(() {
                                if (value != null) _answers[i] = value;
                              }),
                        child: Column(
                          children: <Widget>[
                            for (
                              var j = 0;
                              j < _questions[i].options.length;
                              j++
                            )
                              RadioListTile<int>(
                                value: j,
                                title: Text(_questions[i].options[j]),
                              ),
                          ],
                        ),
                      ),
                      if (_submitted)
                        Text(
                          _answers[i] == _questions[i].correctIndex
                              ? 'Đúng'
                              : 'Sai - đáp án: ${_questions[i].options[_questions[i].correctIndex]}',
                          style: TextStyle(
                            color: _answers[i] == _questions[i].correctIndex
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            if (_questions.isNotEmpty)
              FilledButton(
                onPressed:
                    _submitted ||
                        _answers.length != _questions.length ||
                        note == null
                    ? null
                    : () => _submit(note),
                child: const Text('Nộp bài và lưu điểm'),
              ),
            const SizedBox(height: 24),
            Text('Lịch sử điểm', style: Theme.of(context).textTheme.titleLarge),
            if (_history.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text('Chưa có điểm nào'),
              ),
            for (final score in _history)
              ListTile(
                leading: const Icon(Icons.emoji_events_outlined),
                title: Text(score.noteTitle),
                subtitle: Text(
                  '${score.correctAnswers}/${score.totalQuestions} câu đúng',
                ),
                trailing: Text(
                  '${((score.correctAnswers * 100) / score.totalQuestions).round()}%',
                ),
              ),
          ],
        );
      },
    );
  }
}

class _QuizMessage extends StatelessWidget {
  const _QuizMessage({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(text, textAlign: TextAlign.center),
      ),
    );
  }
}

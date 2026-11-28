import 'dart:async';

import 'package:flutter/material.dart';

import '../../../summary/domain/repositories/summary_repository.dart';
import '../../../summary/presentation/pages/summary_page.dart';
import '../../domain/entities/note.dart';
import '../bloc/notes_cubit.dart';

class NoteEditorPage extends StatefulWidget {
  const NoteEditorPage({
    required this.cubit,
    required this.summaryRepository,
    this.isSummaryDemo = false,
    this.note,
    this.initialKind = NoteKind.note,
    super.key,
  });

  final NotesCubit cubit;
  final SummaryRepository summaryRepository;
  final bool isSummaryDemo;
  final Note? note;
  final NoteKind initialKind;

  @override
  State<NoteEditorPage> createState() => _NoteEditorPageState();
}

class _NoteEditorPageState extends State<NoteEditorPage>
    with WidgetsBindingObserver {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  Timer? _saveTimer;
  Future<bool>? _activeSave;
  Note? _note;
  bool _saving = false;
  bool _dirty = false;
  bool _popRequested = false;
  String? _saveError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _note = widget.note;
    if (_note?.isDiary ?? widget.initialKind == NoteKind.diary) {
      final now = DateTime.now();
      final date =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      _titleController = TextEditingController(
        text: _note?.title ?? 'Nhật ký $date',
      );
    } else {
      _titleController = TextEditingController(text: _note?.title ?? '');
    }
    _contentController = TextEditingController(text: _note?.content ?? '');
    _titleController.addListener(_scheduleSave);
    _contentController.addListener(_scheduleSave);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _saveTimer?.cancel();
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      unawaited(_flushPendingChanges());
    }
  }

  void _scheduleSave() {
    _saveTimer?.cancel();
    _dirty = true;
    _saveError = null;
    setState(() => _saving = true);
    _saveTimer = Timer(const Duration(milliseconds: 700), () {
      unawaited(_save());
    });
  }

  Future<bool> _save() {
    _saveTimer?.cancel();
    final activeSave = _activeSave;
    if (activeSave != null) return activeSave;
    if (!_dirty) return Future<bool>.value(true);

    final save = _performSave();
    _activeSave = save;
    return save.whenComplete(() {
      if (identical(_activeSave, save)) _activeSave = null;
      if (_dirty && _saveError == null && mounted) {
        _saveTimer?.cancel();
        _saveTimer = Timer(const Duration(milliseconds: 700), () {
          unawaited(_save());
        });
      }
    });
  }

  Future<bool> _performSave() async {
    if (!mounted) return false;
    final title = _titleController.text;
    final content = _contentController.text;
    setState(() {
      _saving = true;
      _saveError = null;
    });
    try {
      if (_note == null) {
        _note = await widget.cubit.createNote(
          title: title,
          content: content,
          kind: widget.initialKind,
        );
      } else {
        await widget.cubit.updateNote(_note!, title: title, content: content);
        _note = _note!.copyWith(
          title: title,
          content: content,
          updatedAt: DateTime.now(),
        );
      }
      if (!mounted) return false;
      final savedCurrentText =
          title == _titleController.text && content == _contentController.text;
      setState(() {
        _dirty = !savedCurrentText;
        _saving = _dirty;
      });
      return savedCurrentText;
    } on Object catch (error) {
      if (mounted) {
        setState(() {
          _saving = false;
          _saveError = '$error';
        });
      }
      return false;
    }
  }

  Future<bool> _flushPendingChanges() async {
    _saveTimer?.cancel();
    while (_dirty && mounted) {
      _saveError = null;
      final saved = await _save();
      if (!saved && _saveError != null) return false;
    }
    return !_dirty;
  }

  Future<void> _saveThenPop() async {
    if (_popRequested) return;
    _popRequested = true;
    try {
      if (!await _flushPendingChanges() || !mounted) return;
      await WidgetsBinding.instance.endOfFrame;
      if (mounted) Navigator.of(context).pop();
    } finally {
      _popRequested = false;
    }
  }

  /// Lưu nội dung đang gõ rồi mở màn tóm tắt AI (#12).
  ///
  /// Ghi chú mới chưa có trong database sẽ được tạo trước, nhờ vậy bản tóm tắt
  /// luôn gắn với một `noteId` thật.
  Future<void> _openSummary() async {
    if (_contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Viết nội dung trước khi tóm tắt.')),
      );
      return;
    }
    if (!await _flushPendingChanges()) return;
    final note = _note;
    if (!mounted || note == null) {
      return;
    }
    await Navigator.of(context).push(
      SummaryPage.route(
        noteId: note.id,
        noteTitle: note.displayTitle,
        noteContent: _contentController.text,
        repository: widget.summaryRepository,
        isDemo: widget.isSummaryDemo,
      ),
    );
  }

  Future<void> _delete() async {
    final note = _note;
    if (note == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xoá ghi chú?'),
        content: const Text('Ghi chú sẽ được chuyển vào danh sách đã xoá.'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Huỷ'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xoá'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!await _flushPendingChanges()) return;
    await widget.cubit.deleteNote(note.id);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDiary = _note?.isDiary ?? widget.initialKind == NoteKind.diary;
    return PopScope<void>(
      canPop: !_dirty && !_saving,
      onPopInvokedWithResult: (bool didPop, void result) {
        if (!didPop) unawaited(_saveThenPop());
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(isDiary ? 'Nhật ký hằng ngày' : 'Ghi chú'),
          actions: <Widget>[
            Text(
              _saving ? 'Đang lưu...' : 'Đã lưu',
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(width: 8),
            IconButton(
              tooltip: 'Tóm tắt AI',
              icon: const Icon(Icons.auto_awesome_outlined),
              onPressed: _openSummary,
            ),
            if (_note != null)
              IconButton(
                tooltip: 'Xoá',
                icon: const Icon(Icons.delete_outline),
                onPressed: _delete,
              ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: <Widget>[
              if (_saveError != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    'Không lưu được: $_saveError',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Tiêu đề',
                  border: OutlineInputBorder(),
                ),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              Expanded(
                child: TextField(
                  controller: _contentController,
                  decoration: const InputDecoration(
                    labelText: 'Nội dung',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.multiline,
                  expands: true,
                  maxLines: null,
                  textAlignVertical: TextAlignVertical.top,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

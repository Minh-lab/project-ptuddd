import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/app_dependencies.dart';
import '../../domain/entities/note.dart';
import '../bloc/notes_cubit.dart';
import '../bloc/notes_state.dart';
import '../widgets/note_tile.dart';
import 'note_editor_page.dart';
import 'quiz_page.dart';
import '../services/word_export_service.dart';

/// Màn hình chính: danh sách ghi chú đọc từ Drift.
///
/// CRUD/soạn thảo thuộc issue #3, nên màn này chỉ đọc dữ liệu.
class NotesPage extends StatefulWidget {
  const NotesPage({
    required this.dependencies,
    this.actions = const <Widget>[],
    super.key,
  });

  final AppDependencies dependencies;
  /// Widget hành động trên AppBar, do nơi điều hướng truyền vào (ví dụ nút
  /// đăng xuất). Nhờ vậy feature notes không phải import feature auth.
  final List<Widget> actions;

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  NoteKind? _filter;
  final Set<String> _selectedIds = <String>{};
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<NotesCubit>();
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _selectedIds.isEmpty ? 'SmartNote' : '${_selectedIds.length} đã chọn',
        ),
        actions: <Widget>[
          ...(_selectedIds.isEmpty
              ? <Widget>[
                  PopupMenuButton<NoteKind?>(
                    tooltip: 'Lọc ghi chú',
                    icon: const Icon(Icons.filter_list),
                    onSelected: (value) => setState(() => _filter = value),
                    itemBuilder: (_) => const <PopupMenuEntry<NoteKind?>>[
                      PopupMenuItem(value: null, child: Text('Tất cả')),
                      PopupMenuItem(value: NoteKind.note, child: Text('Ghi chú')),
                      PopupMenuItem(value: NoteKind.diary, child: Text('Nhật ký')),
                    ],
                  ),
                  ...widget.actions,
                ]
              : <Widget>[
                  IconButton(
                    tooltip: 'Xuất Word',
                    icon: const Icon(Icons.description_outlined),
                    onPressed: () => _exportSelected(context),
                  ),
                  IconButton(
                    tooltip: 'Huỷ chọn',
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(_selectedIds.clear),
                  ),
                ]),
        ],
      ),
      body: _tabIndex == 0
          ? BlocBuilder<NotesCubit, NotesState>(
        builder: (BuildContext context, NotesState state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.status == NotesStatus.failure) {
            return _Message(
              icon: Icons.error_outline,
              text: state.errorMessage ?? 'Đã xảy ra lỗi',
            );
          }
          final notes = state.notes
              .where((note) => _filter == null || note.kind == _filter)
              .toList();
          if (notes.isEmpty) {
            return const _Message(
              icon: Icons.sticky_note_2_outlined,
              text: 'Chưa có ghi chú nào',
            );
          }
          return ListView.separated(
            itemCount: notes.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (BuildContext context, int index) {
              final note = notes[index];
              final selected = _selectedIds.contains(note.id);
              return NoteTile(
                note: note,
                selected: selected,
                onLongPress: () =>
                    setState(() => _selectedIds.add(note.id)),
                onTap: () {
                  if (_selectedIds.isNotEmpty) {
                    setState(() {
                      if (selected) {
                        _selectedIds.remove(note.id);
                      } else {
                        _selectedIds.add(note.id);
                      }
                    });
                  } else {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            NoteEditorPage(cubit: cubit, note: note),
                      ),
                    );
                  }
                },
              );
            },
          );
        },
          )
          : QuizPage(
              notesCubit: cubit,
              scoresDao: widget.dependencies.quizScoresDao,
            ),
      floatingActionButton: _tabIndex == 0
          ? FloatingActionButton(
              tooltip: 'Tạo ghi chú',
              onPressed: () => _showCreateSheet(context, cubit),
              child: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (index) => setState(() => _tabIndex = index),
        destinations: const <NavigationDestination>[
          NavigationDestination(
            icon: Icon(Icons.note_outlined),
            label: 'Ghi chú',
          ),
          NavigationDestination(
            icon: Icon(Icons.quiz_outlined),
            label: 'Trắc nghiệm',
          ),
        ],
      ),
    );
  }

  Future<void> _showCreateSheet(
    BuildContext context,
    NotesCubit cubit,
  ) async {
    final navigator = Navigator.of(context);
    final kind = await showModalBottomSheet<NoteKind>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.sticky_note_2_outlined),
              title: const Text('Ghi chú mới'),
              onTap: () => navigator.pop(NoteKind.note),
            ),
            ListTile(
              leading: const Icon(Icons.event_note_outlined),
              title: const Text('Viết nhật ký hằng ngày'),
              onTap: () => navigator.pop(NoteKind.diary),
            ),
          ],
        ),
      ),
    );
    if (!mounted || kind == null) return;
    await navigator.push(
      MaterialPageRoute<void>(
        builder: (_) => NoteEditorPage(cubit: cubit, initialKind: kind),
      ),
    );
  }

  Future<void> _exportSelected(BuildContext context) async {
    final state = context.read<NotesCubit>().state;
    final selected = state.notes
        .where((note) => _selectedIds.contains(note.id))
        .toList();
    try {
      final path = await WordExportService().exportNotes(selected);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã xuất tài liệu Word:\n$path')),
      );
      setState(_selectedIds.clear);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không xuất được Word: $error')),
      );
    }
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 48, color: theme.colorScheme.outline),
          const SizedBox(height: 12),
          Text(text, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}

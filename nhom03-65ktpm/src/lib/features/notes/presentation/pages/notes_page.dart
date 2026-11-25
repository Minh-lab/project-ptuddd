import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/notes_cubit.dart';
import '../bloc/notes_state.dart';
import '../widgets/note_tile.dart';

/// Màn hình chính: danh sách ghi chú đọc từ Drift.
///
/// CRUD/soạn thảo thuộc issue #3, nên màn này chỉ đọc dữ liệu.
class NotesPage extends StatefulWidget {
  const NotesPage({this.actions = const <Widget>[], super.key});

  /// Widget hành động trên AppBar, do nơi điều hướng truyền vào (ví dụ nút
  /// đăng xuất). Nhờ vậy feature notes không phải import feature auth.
  final List<Widget> actions;

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SmartNote'), actions: widget.actions),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm ghi chú',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Xóa tìm kiếm',
                        onPressed: () {
                          _searchController.clear();
                          context.read<NotesCubit>().search('');
                          setState(() {});
                        },
                        icon: const Icon(Icons.close),
                      ),
                border: const OutlineInputBorder(),
              ),
              onChanged: (String query) {
                context.read<NotesCubit>().search(query);
                setState(() {});
              },
            ),
          ),
          Expanded(
            child: BlocBuilder<NotesCubit, NotesState>(
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
                if (state.notes.isEmpty) {
                  return _Message(
                    icon: Icons.sticky_note_2_outlined,
                    text: state.searchQuery.trim().isEmpty
                        ? 'Chưa có ghi chú nào'
                        : 'Không tìm thấy ghi chú phù hợp',
                  );
                }
                return ListView.separated(
                  itemCount: state.notes.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (BuildContext context, int index) {
                    return NoteTile(
                      note: state.notes[index],
                      searchQuery: state.searchQuery,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
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

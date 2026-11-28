import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/di/app_dependencies.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_search_bar.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../core/widgets/notes_quick_action.dart';
import '../../../summary/presentation/pages/summary_page.dart';
import '../../domain/entities/note.dart';
import '../bloc/notes_cubit.dart';
import '../bloc/notes_state.dart';
import '../services/word_export_service.dart';
import '../widgets/note_card.dart';
import '../widgets/sync_status_indicator.dart';
import 'note_editor_page.dart';
import 'note_flashcard_page.dart';
import 'quiz_page.dart';

/// Thư viện ghi chú theo mẫu bảng chủ đề đã duyệt.
class NotesPage extends StatefulWidget {
  const NotesPage({
    required this.dependencies,
    this.accountName,
    this.accountEmail,
    this.onThemeChanged,
    this.actions = const <Widget>[],
    super.key,
  });

  final AppDependencies dependencies;
  final String? accountName;
  final String? accountEmail;
  final VoidCallback? onThemeChanged;

  /// Widget hành động trong vùng bộ lọc và công cụ, do nơi điều hướng truyền vào (ví dụ nút
  /// đăng xuất). Nhờ vậy feature notes không phải import feature auth.
  final List<Widget> actions;

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  final Set<String> _selectedIds = <String>{};
  bool _isGrid = true;
  bool _showTopics = true;
  late final Stream<Set<String>> _completedQuizIds = widget.dependencies
      .watchCompletedQuizNoteIds();
  String _query = '';
  String? _selectedTag;
  StreamSubscription<String>? _openRequests;

  bool get _selectionMode => _selectedIds.isNotEmpty;

  @override
  void initState() {
    super.initState();
    // Bấm vào thông báo nhắc nhở (#10) thì mở đúng ghi chú đó.
    _openRequests = widget.dependencies.noteOpenRequests.listen(_openNoteById);
  }

  @override
  void dispose() {
    unawaited(_openRequests?.cancel());
    super.dispose();
  }

  Future<void> _openNoteById(String id) async {
    final cubit = context.read<NotesCubit>();
    var state = cubit.state;
    if (state.status == NotesStatus.initial || state.isLoading) {
      state = await cubit.stream.firstWhere(
        (NotesState next) =>
            next.status != NotesStatus.initial && !next.isLoading,
      );
    }
    if (!mounted) return;
    final note = state.notes.where((Note note) => note.id == id).firstOrNull;
    if (note == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ghi chú của nhắc nhở này không còn nữa.'),
        ),
      );
      return;
    }
    Navigator.of(context).popUntil((Route<dynamic> route) => route.isFirst);
    _openEditor(cubit, note);
  }

  List<String> _tags(List<Note> notes) {
    final tags = <String>{};
    for (final note in notes) {
      tags.addAll(note.tags.where((String tag) => tag.trim().isNotEmpty));
    }
    return tags.toList()..sort((a, b) {
      final subjectOrder = NotesTopic.fromLabel(a).index
          .compareTo(NotesTopic.fromLabel(b).index);
      return subjectOrder == 0 ? a.compareTo(b) : subjectOrder;
    });
  }

  List<Note> _filter(List<Note> notes) {
    final keyword = _query.trim().toLowerCase();
    return notes.where((Note note) {
      if (_selectedTag != null && !note.tags.contains(_selectedTag)) {
        return false;
      }
      if (keyword.isEmpty) {
        return true;
      }
      final haystack = <String>[
        note.title,
        note.content,
        ...note.tags,
      ].join(' ').toLowerCase();
      return haystack.contains(keyword);
    }).toList();
  }

  String _subtitle(NotesState state, int shown, int total) {
    if (state.isLoading || state.status == NotesStatus.failure) {
      return 'Đang đồng bộ ghi chú của bạn';
    }
    if (total == 0) {
      return 'Sẵn sàng cho ghi chú đầu tiên';
    }
    if (_query.trim().isNotEmpty || _selectedTag != null) {
      return '$shown/$total ghi chú phù hợp';
    }
    return '$total ghi chú';
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<NotesCubit>();
    return Theme(
      data: AppTheme.notes(Theme.of(context)),
      child: BlocBuilder<NotesCubit, NotesState>(
        builder: (context, state) {
          final notes = state.notes
              .where((Note note) => !note.isDiary)
              .toList();
          final filtered = _filter(notes);
          return Scaffold(
            body: SafeArea(
              bottom: false,
              child: CustomScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      NotesLayout.gutter,
                      AppSpacing.md,
                      NotesLayout.gutter,
                      NotesLayout.gap,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: _header(
                        context,
                        state,
                        filtered.length,
                        notes,
                        cubit,
                      ),
                    ),
                  ),
                  ..._bodySlivers(
                    context,
                    state,
                    filtered,
                    notes.length,
                    cubit,
                  ),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: NotesLayout.bottomPadding),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _header(
    BuildContext context,
    NotesState state,
    int count,
    List<Note> notes,
    NotesCubit cubit,
  ) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final tags = _tags(notes);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                _selectionMode ? '${_selectedIds.length} đã chọn' : 'Ghi chú',
                style: _selectionMode
                    ? theme.textTheme.headlineSmall
                    : theme.textTheme.headlineLarge,
              ),
            ),
            if (_selectionMode) ...[
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
            ] else ...[
              _accountAvatar(context),
              const SizedBox(width: NotesLayout.actionGap),
              IconButton.filled(
                tooltip: 'Tạo ghi chú',
                style: IconButton.styleFrom(
                  fixedSize: const Size.square(NotesLayout.createSize),
                  minimumSize: const Size.square(NotesLayout.createSize),
                  backgroundColor: colors.primary,
                  foregroundColor: colors.onPrimary,
                ),
                onPressed: () => _showCreateSheet(context, cubit),
                icon: const Icon(Icons.add, size: 24),
              ),
            ],
          ],
        ),
        const SizedBox(height: NotesLayout.headerBottom),
        Visibility(
          visible: !_selectionMode,
          maintainState: true,
          child: AppSearchBar(
            dense: true,
            hintText: 'Tìm trong ghi chú',
            onChanged: (value) => setState(() => _query = value),
          ),
        ),
        if (_selectionMode)
          const Text('Chọn thêm hoặc xuất tài liệu Word')
        else ...[
          const SizedBox(height: NotesLayout.actionTop),
          _quickActions(context, notes, cubit),
          const SizedBox(height: NotesLayout.topicTop - AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Tooltip(
                    message: 'Bộ lọc và công cụ',
                    child: InkWell(
                      onTap: () => setState(() => _showTopics = !_showTopics),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.sm,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                _showTopics
                                    ? 'Theo chủ đề'
                                    : _selectedTag ?? 'Theo chủ đề',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: colors.onSurface,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Icon(
                              _showTopics
                                  ? Icons.keyboard_arrow_down
                                  : Icons.chevron_right,
                              size: 20,
                              color: colors.onSurfaceVariant,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  _subtitle(state, count, notes.length),
                  textAlign: TextAlign.end,
                  style: theme.textTheme.bodySmall,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              IconButton(
                tooltip: _isGrid ? 'Xem dạng danh sách' : 'Xem dạng lưới',
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                iconSize: 19,
                color: colors.onSurfaceVariant,
                icon: Icon(
                  _isGrid
                      ? Icons.view_agenda_outlined
                      : Icons.grid_view_rounded,
                ),
                onPressed: () => setState(() => _isGrid = !_isGrid),
              ),
              SyncStatusIndicator(
                status: state.syncStatus,
                message: state.syncMessage,
              ),
            ],
          ),
          if (_showTopics) ...[
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                _tagChip(context, label: 'Tất cả', tag: null),
                for (final tag in tags) _tagChip(context, label: tag, tag: tag),
              ],
            ),
          ],
        ],
      ],
    );
  }

  Widget _accountAvatar(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final name = widget.accountName?.trim() ?? '';
    final email = widget.accountEmail?.trim() ?? '';
    final identity = name.isEmpty ? email : name;
    return Tooltip(
      message: 'Tài khoản',
      child: Semantics(
        button: true,
        label: 'Tài khoản',
        child: InkResponse(
          onTap: () => _openAccount(context),
          radius: NotesLayout.avatarSize / 2,
          child: CircleAvatar(
            radius: NotesLayout.avatarSize / 2,
            backgroundColor: colors.surfaceContainerHigh,
            foregroundColor: colors.onSurface,
            child: identity.isEmpty
                ? const Icon(Icons.person_outline, size: 22)
                : Text(identity.characters.first.toUpperCase()),
          ),
        ),
      ),
    );
  }

  void _openAccount(BuildContext context) {
    final name = widget.accountName?.trim() ?? '';
    final email = widget.accountEmail?.trim() ?? '';
    final dark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.account_circle_outlined),
                title: Text(name.isEmpty ? 'Tài khoản' : name),
                subtitle: email.isEmpty ? null : Text(email),
              ),
              if (widget.onThemeChanged != null)
                ListTile(
                  leading: Icon(
                    dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                  ),
                  title: Text(
                    dark ? 'Dùng giao diện sáng' : 'Dùng giao diện tối',
                  ),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    widget.onThemeChanged!();
                  },
                ),
              if (widget.actions.isNotEmpty)
                Wrap(alignment: WrapAlignment.center, children: widget.actions),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        ),
      ),
    );
  }

  Widget _quickActions(
    BuildContext context,
    List<Note> notes,
    NotesCubit cubit,
  ) {
    final colors = Theme.of(context).brightness == Brightness.dark
        ? NotesColors.actionIcons
        : NotesColors.lightActionIcons;
    final actions = [
      ('Trắc\nnghiệm AI', Icons.quiz_outlined, () => _openQuiz(context, cubit)),
      (
        'Ôn tập /\nFlashcard',
        Icons.style_outlined,
        () => _openNoteAction(context, notes, summarize: false),
      ),
      (
        'Tóm tắt\nAI',
        Icons.auto_awesome_outlined,
        () => _openNoteAction(context, notes, summarize: true),
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = MediaQuery.textScalerOf(context).scale(13) / 13;
        final width = ((constraints.maxWidth - 2 * NotesLayout.actionGap) / 3)
            .clamp(118.0 * math.max(1, scale), math.max(180.0, 118 * scale))
            .toDouble();
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final (index, (label, icon, onPressed))
                  in actions.indexed) ...[
                if (index > 0) const SizedBox(width: NotesLayout.actionGap),
                SizedBox(
                  width: width,
                  child: NotesQuickAction(
                    label: label,
                    icon: icon,
                    color: colors[index],
                    onPressed: onPressed,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _tagChip(
    BuildContext context, {
    required String label,
    required String? tag,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;
    final selected = _selectedTag == tag;
    final topic = NotesTopic.fromLabel(label);
    return ChoiceChip(
      label: Text(label),
      labelStyle: theme.textTheme.labelLarge?.copyWith(
        color: selected
            ? scheme.onPrimary
            : dark
            ? topic.labelColor(dark)
            : NotesColors.chipText(theme.brightness),
        fontWeight: FontWeight.w600,
      ),
      labelPadding: EdgeInsets.zero,
      padding: const EdgeInsets.symmetric(
        horizontal: NotesLayout.chipPadding,
        vertical: NotesLayout.chipVerticalPadding,
      ),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      shape: const StadiumBorder(),
      side: BorderSide.none,
      backgroundColor: topic.chip(dark),
      selectedColor: NotesColors.selectedChip(theme.brightness),
      selected: selected,
      showCheckmark: false,
      onSelected: (_) => setState(() => _selectedTag = tag),
    );
  }

  Future<void> _openNoteAction(
    BuildContext context,
    List<Note> notes, {
    required bool summarize,
  }) async {
    final available = notes
        .where((note) => note.content.trim().isNotEmpty)
        .toList();
    if (available.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hãy thêm nội dung vào ghi chú trước.')),
      );
      return;
    }
    final navigator = Navigator.of(context);
    final note = await showModalBottomSheet<Note>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: FractionallySizedBox(
          heightFactor: .60,
          child: Column(
            children: [
              ListTile(
                title: Text(
                  summarize
                      ? 'Chọn ghi chú để tóm tắt'
                      : 'Chọn ghi chú để ôn tập',
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: available.length,
                  itemBuilder: (_, index) => ListTile(
                    leading: const Icon(Icons.description_outlined),
                    title: Text(available[index].displayTitle),
                    onTap: () =>
                        Navigator.of(sheetContext).pop(available[index]),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (!mounted || note == null) return;
    await navigator.push(
      summarize
          ? SummaryPage.route(
              noteId: note.id,
              noteTitle: note.displayTitle,
              noteContent: note.content,
              repository: widget.dependencies.summaryRepository,
              isDemo: widget.dependencies.aiClient.isDemo,
            )
          : MaterialPageRoute<void>(
              builder: (_) => NoteFlashcardPage(note: note),
            ),
    );
  }

  List<Widget> _bodySlivers(
    BuildContext context,
    NotesState state,
    List<Note> filtered,
    int totalCount,
    NotesCubit cubit,
  ) {
    final Widget? status = switch (state) {
      _ when state.isLoading => const LoadingView(),
      _ when state.status == NotesStatus.failure => ErrorView(
        message: state.errorMessage ?? 'Đã xảy ra lỗi khi đọc ghi chú.',
        onRetry: cubit.load,
      ),
      _ when totalCount == 0 => EmptyState(
        icon: Icons.sticky_note_2_outlined,
        title: 'Chưa có ghi chú nào',
        message: 'Ghi chú bạn tạo sẽ xuất hiện tại đây.',
        actionLabel: 'Tạo ghi chú',
        onAction: () => _showCreateSheet(context, cubit),
      ),
      _ when filtered.isEmpty => const EmptyState(
        icon: Icons.search_off_rounded,
        title: 'Không tìm thấy ghi chú',
        message: 'Thử từ khoá khác hoặc bỏ bộ lọc môn học.',
      ),
      _ => null,
    };
    if (status != null) {
      return [SliverFillRemaining(child: status)];
    }
    const horizontalPadding = EdgeInsets.symmetric(
      horizontal: NotesLayout.gutter,
    );
    return [
      StreamBuilder<Set<String>>(
        stream: _completedQuizIds,
        builder: (context, snapshot) {
          final quizIds = snapshot.data ?? const <String>{};
          return SliverPadding(
            padding: horizontalPadding,
            sliver: _isGrid
                ? _grid(context, filtered, cubit, quizIds)
                : SliverList.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: NotesLayout.gap),
                    itemBuilder: (_, index) => _card(
                      filtered[index],
                      cubit,
                      hasQuiz: quizIds.contains(filtered[index].id),
                    ),
                  ),
          );
        },
      ),
    ];
  }

  Widget _grid(
    BuildContext context,
    List<Note> filtered,
    NotesCubit cubit,
    Set<String> quizIds,
  ) {
    final textScale = MediaQuery.textScalerOf(context).scale(16) / 16;
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.crossAxisExtent;
        final columns = switch (width) {
          >= 808 => 4,
          >= 568 => 3,
          < 278 => 1,
          _ when textScale > 1.5 => 1,
          _ => 2,
        };
        final tileWidth = (width - (columns - 1) * NotesLayout.gap) / columns;
        final minHeight = NotesLayout.minTileHeight * math.max(1, textScale);
        return SliverGrid.builder(
          itemCount: filtered.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: NotesLayout.gap,
            mainAxisSpacing: NotesLayout.gap,
            mainAxisExtent: math.max(
              tileWidth / NotesLayout.gridAspectRatio,
              minHeight,
            ),
          ),
          itemBuilder: (_, index) => _card(
            filtered[index],
            cubit,
            compact: true,
            hasQuiz: quizIds.contains(filtered[index].id),
          ),
        );
      },
    );
  }

  Widget _card(
    Note note,
    NotesCubit cubit, {
    bool compact = false,
    required bool hasQuiz,
  }) {
    final selected = _selectedIds.contains(note.id);
    return NoteCard(
      key: ValueKey(note.id),
      note: note,
      compact: compact,
      hasQuiz: hasQuiz,
      selected: selected,
      onLongPress: () => setState(() => _selectedIds.add(note.id)),
      onTap: () {
        if (!_selectionMode) {
          _openEditor(cubit, note);
        } else {
          setState(() {
            if (selected) {
              _selectedIds.remove(note.id);
            } else {
              _selectedIds.add(note.id);
            }
          });
        }
      },
    );
  }

  void _openEditor(NotesCubit cubit, Note note) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => NoteEditorPage(
          cubit: cubit,
          note: note,
          summaryRepository: widget.dependencies.summaryRepository,
          isSummaryDemo: widget.dependencies.aiClient.isDemo,
        ),
      ),
    );
  }

  void _openQuiz(BuildContext context, NotesCubit cubit) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => QuizPage(
          notesCubit: cubit,
          scoresDao: widget.dependencies.quizScoresDao,
          aiClient: widget.dependencies.aiClient,
        ),
      ),
    );
  }

  Future<void> _showCreateSheet(BuildContext context, NotesCubit cubit) async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
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
    if (!mounted || kind == null) {
      return;
    }
    Note? note;
    if (kind == NoteKind.diary) {
      try {
        note = await cubit.ensureDiaryForDate(DateTime.now());
      } on Object catch (error) {
        if (!mounted) return;
        messenger.showSnackBar(
          SnackBar(content: Text('Không mở được nhật ký: $error')),
        );
        return;
      }
    }
    if (!mounted) return;
    await navigator.push(
      MaterialPageRoute<void>(
        builder: (_) => NoteEditorPage(
          cubit: cubit,
          note: note,
          initialKind: kind,
          summaryRepository: widget.dependencies.summaryRepository,
          isSummaryDemo: widget.dependencies.aiClient.isDemo,
        ),
      ),
    );
  }

  Future<void> _exportSelected(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final selected = context
        .read<NotesCubit>()
        .state
        .notes
        .where((Note note) => _selectedIds.contains(note.id))
        .toList();
    if (selected.isEmpty) {
      return;
    }
    try {
      final subjects = await widget.dependencies.subjectRepository
          .watchSubjects()
          .first;
      final path = await WordExportService().exportNotes(
        selected,
        subjectNames: {
          for (final subject in subjects) subject.id: subject.name,
        },
      );
      if (!mounted) {
        return;
      }
      await SharePlus.instance.share(
        ShareParams(
          subject: 'SmartNote - ${selected.length} ghi chú',
          files: <XFile>[
            XFile(
              path,
              mimeType: 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
            ),
          ],
        ),
      );
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Đã xuất tài liệu Word:\n$path')),
      );
      setState(_selectedIds.clear);
    } catch (error) {
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(
        SnackBar(content: Text('Không xuất được Word: $error')),
      );
    }
  }
}

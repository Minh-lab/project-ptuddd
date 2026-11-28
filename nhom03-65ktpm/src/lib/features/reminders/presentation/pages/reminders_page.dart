import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../domain/entities/reminder.dart';
import '../bloc/reminders_cubit.dart';
import '../bloc/reminders_state.dart';
import '../widgets/reminder_form_sheet.dart';
import '../widgets/reminder_labels.dart';

/// Màn "Nhắc nhở học tập": xem, thêm, sửa, xoá nhắc nhở theo ghi chú (#10).
class RemindersPage extends StatefulWidget {
  const RemindersPage({super.key});

  @override
  State<RemindersPage> createState() => _RemindersPageState();
}

class _RemindersPageState extends State<RemindersPage>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Người dùng có thể vừa bật thông báo trong cài đặt rồi quay lại app.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<RemindersCubit>().refreshPermission();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<RemindersCubit, RemindersState>(
      listenWhen: (RemindersState previous, RemindersState current) =>
          current.errorMessage != null &&
          current.errorMessage != previous.errorMessage,
      listener: (BuildContext context, RemindersState state) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(state.errorMessage!)));
      },
      builder: (BuildContext context, RemindersState state) {
        return Scaffold(
          appBar: AppBar(title: const Text('Nhắc nhở học tập')),
          floatingActionButton: state.notes.isEmpty
              ? null
              : FloatingActionButton.extended(
                  key: const ValueKey<String>('add-reminder'),
                  onPressed: () => _openForm(context, state),
                  icon: const Icon(Icons.add_alarm),
                  label: const Text('Thêm nhắc nhở'),
                ),
          body: _body(context, state),
        );
      },
    );
  }

  Widget _body(BuildContext context, RemindersState state) {
    if (state.isLoading) return const LoadingView();
    final banner = _PermissionBanner(state: state);
    if (state.reminders.isEmpty) {
      return Column(
        children: <Widget>[
          banner,
          Expanded(
            child: state.notes.isEmpty
                ? const EmptyState(
                    icon: Icons.alarm_outlined,
                    title: 'Chưa có ghi chú nào',
                    message:
                        'Hãy tạo ghi chú trước rồi đặt nhắc nhở để ôn lại.',
                  )
                : EmptyState(
                    icon: Icons.alarm_outlined,
                    title: 'Chưa có nhắc nhở',
                    message: 'Đặt lịch để được nhắc ôn lại ghi chú đúng giờ.',
                    actionLabel: 'Thêm nhắc nhở',
                    onAction: () => _openForm(context, state),
                  ),
          ),
        ],
      );
    }
    return ListView(
      padding: const EdgeInsets.only(bottom: 96),
      children: <Widget>[
        banner,
        for (final reminder in state.reminders)
          _ReminderTile(
            reminder: reminder,
            noteTitle: state.noteFor(reminder.noteId)?.displayTitle,
            onEdit: () => _openForm(context, state, editing: reminder),
            onDelete: () => _confirmDelete(context, reminder),
          ),
      ],
    );
  }

  Future<void> _openForm(
    BuildContext context,
    RemindersState state, {
    Reminder? editing,
  }) {
    final cubit = context.read<RemindersCubit>();
    final messenger = ScaffoldMessenger.of(context);
    return ReminderFormSheet.show(
      context,
      notes: state.notes,
      now: cubit.now,
      editing: editing,
      onSubmit: (ReminderFormValue value) async {
        final error = await cubit.save(
          cubit.draft(
            noteId: value.noteId,
            repeat: value.repeat,
            remindAt: value.remindAt,
            weekdays: value.weekdays,
            editing: editing,
          ),
        );
        if (error == null) {
          messenger.showSnackBar(
            SnackBar(
              content: Text(
                cubit.state.permissionDenied
                    ? 'Đã lưu, nhưng thông báo đang tắt nên sẽ chưa được nhắc.'
                    : 'Đã lưu nhắc nhở.',
              ),
            ),
          );
        }
        return error;
      },
    );
  }

  Future<void> _confirmDelete(BuildContext context, Reminder reminder) async {
    final cubit = context.read<RemindersCubit>();
    final ok = await ConfirmDialog.show(
      context,
      title: 'Xoá nhắc nhở?',
      message: 'Thông báo của nhắc nhở này sẽ không hiện nữa.',
      confirmLabel: 'Xoá',
      isDestructive: true,
    );
    if (ok) await cubit.delete(reminder.id);
  }
}

class _ReminderTile extends StatelessWidget {
  const _ReminderTile({
    required this.reminder,
    required this.noteTitle,
    required this.onEdit,
    required this.onDelete,
  });

  final Reminder reminder;

  /// `null` nếu ghi chú đã bị xoá.
  final String? noteTitle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final next = context.read<RemindersCubit>().nextOccurrence(reminder);
    return ListTile(
      key: ValueKey<String>('reminder-${reminder.id}'),
      leading: Icon(
        next == null ? Icons.alarm_off_outlined : Icons.alarm_on_outlined,
        color: next == null ? scheme.onSurfaceVariant : scheme.primary,
      ),
      title: Text(
        noteTitle ?? 'Ghi chú đã bị xoá',
        style: noteTitle == null ? TextStyle(color: scheme.error) : null,
      ),
      subtitle: Text(
        '${ReminderLabels.schedule(reminder)}\n'
        '${noteTitle == null ? 'Sẽ không nhắc nữa' : ReminderLabels.next(next)}',
      ),
      isThreeLine: true,
      onTap: onEdit,
      trailing: IconButton(
        key: ValueKey<String>('delete-reminder-${reminder.id}'),
        tooltip: 'Xoá nhắc nhở',
        icon: const Icon(Icons.delete_outline),
        onPressed: onDelete,
      ),
    );
  }
}

/// Hướng dẫn khi thông báo bị tắt hoặc thiết bị không hỗ trợ thông báo.
class _PermissionBanner extends StatelessWidget {
  const _PermissionBanner({required this.state});

  final RemindersState state;

  @override
  Widget build(BuildContext context) {
    if (!state.permissionDenied && !state.notificationsUnsupported) {
      return const SizedBox.shrink();
    }
    final theme = Theme.of(context);
    final denied = state.permissionDenied;
    return Card(
      key: const ValueKey<String>('notification-permission-banner'),
      margin: const EdgeInsets.all(AppSpacing.lg),
      color: denied
          ? theme.colorScheme.errorContainer
          : theme.colorScheme.surfaceContainerHigh,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(
                  denied
                      ? Icons.notifications_off_outlined
                      : Icons.info_outline,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    denied ? 'Thông báo đang tắt' : 'Chưa hỗ trợ thông báo',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              denied
                  ? 'Nhắc nhở vẫn được lưu nhưng sẽ không hiện. Bấm "Mở cài '
                        'đặt", chọn Thông báo và bật "Cho phép thông báo" cho '
                        'SmartNote, rồi quay lại app.'
                  : 'Thông báo nhắc nhở chỉ hoạt động trên điện thoại Android '
                        'và iOS.',
            ),
            if (denied)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  key: const ValueKey<String>('open-notification-settings'),
                  onPressed: () =>
                      context.read<RemindersCubit>().openNotificationSettings(),
                  child: const Text('Mở cài đặt'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

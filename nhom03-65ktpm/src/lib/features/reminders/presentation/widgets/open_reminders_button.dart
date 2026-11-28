import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/reminder_note_source.dart';
import '../../domain/repositories/reminder_repository.dart';
import '../bloc/reminders_cubit.dart';
import '../pages/reminders_page.dart';

/// Nút mở màn "Nhắc nhở học tập".
///
/// Nơi điều hướng truyền nút này vào màn hình chính, nhờ vậy feature notes
/// không phải import feature reminders.
class OpenRemindersButton extends StatelessWidget {
  const OpenRemindersButton({
    required this.reminderRepository,
    required this.reminderNotes,
    super.key,
  });

  final ReminderRepository reminderRepository;
  final ReminderNoteSource reminderNotes;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      key: const ValueKey<String>('open-reminders'),
      tooltip: 'Nhắc nhở học tập',
      icon: const Icon(Icons.alarm_outlined),
      onPressed: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => BlocProvider<RemindersCubit>(
            create: (_) =>
                RemindersCubit(reminderRepository, reminderNotes)..load(),
            child: const RemindersPage(),
          ),
        ),
      ),
    );
  }
}

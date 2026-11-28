import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/reminder.dart';
import '../../domain/entities/reminder_note.dart';
import 'reminder_labels.dart';

/// Dữ liệu người dùng nhập trên form, cubit sẽ dựng thành [Reminder].
class ReminderFormValue {
  const ReminderFormValue({
    required this.noteId,
    required this.repeat,
    required this.remindAt,
    required this.weekdays,
  });

  final String noteId;
  final ReminderRepeat repeat;
  final DateTime remindAt;
  final List<int> weekdays;
}

/// Form tạo/sửa nhắc nhở, hiện dạng bottom sheet.
///
/// [onSubmit] trả thông báo lỗi để hiện ngay trên form, hoặc `null` khi đã
/// lưu xong (sheet tự đóng).
class ReminderFormSheet extends StatefulWidget {
  const ReminderFormSheet({
    required this.notes,
    required this.now,
    required this.onSubmit,
    this.editing,
    super.key,
  });

  final List<ReminderNote> notes;
  final DateTime now;
  final Reminder? editing;
  final Future<String?> Function(ReminderFormValue value) onSubmit;

  static Future<void> show(
    BuildContext context, {
    required List<ReminderNote> notes,
    required DateTime now,
    required Future<String?> Function(ReminderFormValue value) onSubmit,
    Reminder? editing,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => ReminderFormSheet(
        notes: notes,
        now: now,
        editing: editing,
        onSubmit: onSubmit,
      ),
    );
  }

  @override
  State<ReminderFormSheet> createState() => _ReminderFormSheetState();
}

class _ReminderFormSheetState extends State<ReminderFormSheet> {
  late String? _noteId;
  late ReminderRepeat _repeat;
  late DateTime _date;
  late TimeOfDay _time;
  late Set<int> _weekdays;
  String? _error;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final editing = widget.editing;
    final now = widget.now;
    // Mặc định: giờ chẵn kế tiếp.
    final suggested = DateTime(now.year, now.month, now.day, now.hour + 1);
    final at = editing?.remindAt ?? suggested;
    _noteId = editing?.noteId ?? widget.notes.firstOrNull?.id;
    _repeat = editing?.repeat ?? ReminderRepeat.once;
    _date = DateTime(at.year, at.month, at.day);
    _time = TimeOfDay(hour: at.hour, minute: at.minute);
    _weekdays = <int>{...?editing?.weekdays};
    if (_weekdays.isEmpty) _weekdays.add(now.weekday);
  }

  Future<void> _pickDate() async {
    final today = DateTime(widget.now.year, widget.now.month, widget.now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: _date.isBefore(today) ? today : _date,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365 * 2)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _submit() async {
    final noteId = _noteId;
    if (noteId == null) {
      setState(() => _error = 'Hãy chọn ghi chú cần nhắc.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final navigator = Navigator.of(context);
    final error = await widget.onSubmit(
      ReminderFormValue(
        noteId: noteId,
        repeat: _repeat,
        remindAt: DateTime(
          _date.year,
          _date.month,
          _date.day,
          _time.hour,
          _time.minute,
        ),
        weekdays: _weekdays.toList(),
      ),
    );
    if (!mounted) return;
    if (error == null) {
      navigator.pop();
    } else {
      setState(() {
        _saving = false;
        _error = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xl,
        0,
        AppSpacing.xl,
        AppSpacing.xl + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              widget.editing == null ? 'Thêm nhắc nhở' : 'Sửa nhắc nhở',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.lg),
            _noteField(),
            const SizedBox(height: AppSpacing.lg),
            _repeatField(),
            const SizedBox(height: AppSpacing.md),
            if (_repeat == ReminderRepeat.once)
              _pickerTile(
                key: const ValueKey<String>('reminder-date'),
                icon: Icons.event_outlined,
                label: 'Ngày',
                value: ReminderLabels.date(_date),
                onTap: _pickDate,
              ),
            _pickerTile(
              key: const ValueKey<String>('reminder-time'),
              icon: Icons.schedule_outlined,
              label: 'Giờ',
              value: ReminderLabels.time(_time.hour, _time.minute),
              onTap: _pickTime,
            ),
            if (_repeat == ReminderRepeat.weekly) _weekdayField(),
            if (_error != null) ...<Widget>[
              const SizedBox(height: AppSpacing.md),
              Text(
                _error!,
                key: const ValueKey<String>('reminder-error'),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            FilledButton(
              key: const ValueKey<String>('save-reminder'),
              onPressed: _saving ? null : _submit,
              child: Text(_saving ? 'Đang lưu…' : 'Lưu nhắc nhở'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _noteField() {
    return DropdownButtonFormField<String>(
      key: const ValueKey<String>('reminder-note'),
      initialValue: _noteId,
      isExpanded: true,
      decoration: const InputDecoration(labelText: 'Ghi chú cần ôn'),
      items: <DropdownMenuItem<String>>[
        for (final note in widget.notes)
          DropdownMenuItem<String>(
            value: note.id,
            child: Text(note.displayTitle, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: (String? id) => setState(() => _noteId = id),
    );
  }

  Widget _repeatField() {
    return SegmentedButton<ReminderRepeat>(
      key: const ValueKey<String>('reminder-repeat'),
      segments: <ButtonSegment<ReminderRepeat>>[
        for (final repeat in ReminderRepeat.values)
          ButtonSegment<ReminderRepeat>(
            value: repeat,
            label: Text(ReminderLabels.repeatName(repeat)),
          ),
      ],
      selected: <ReminderRepeat>{_repeat},
      onSelectionChanged: (Set<ReminderRepeat> selected) =>
          setState(() => _repeat = selected.first),
    );
  }

  Widget _pickerTile({
    required Key key,
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return ListTile(
      key: key,
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(label),
      trailing: Text(value, style: Theme.of(context).textTheme.titleMedium),
      onTap: onTap,
    );
  }

  Widget _weekdayField() {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: <Widget>[
        for (var day = DateTime.monday; day <= DateTime.sunday; day++)
          FilterChip(
            key: ValueKey<String>('weekday-$day'),
            label: Text(ReminderLabels.weekdayShort(day)),
            selected: _weekdays.contains(day),
            onSelected: (bool selected) => setState(() {
              if (selected) {
                _weekdays.add(day);
              } else {
                _weekdays.remove(day);
              }
            }),
          ),
      ],
    );
  }
}

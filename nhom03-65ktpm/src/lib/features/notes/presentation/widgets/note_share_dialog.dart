import 'package:flutter/material.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/utils/form_validators.dart';
import '../../domain/entities/note.dart';
import '../../domain/entities/note_share.dart';
import '../../domain/repositories/note_share_repository.dart';

class NoteShareDialog extends StatefulWidget {
  const NoteShareDialog({
    required this.note,
    required this.ownerId,
    required this.repository,
    super.key,
  });

  final Note note;
  final String ownerId;
  final NoteShareRepository repository;

  @override
  State<NoteShareDialog> createState() => _NoteShareDialogState();
}

class _NoteShareDialogState extends State<NoteShareDialog> {
  final TextEditingController _recipientController = TextEditingController();
  late Future<List<NoteShare>> _sharesFuture;
  bool _isCreating = false;
  String? _sentToEmail;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _sharesFuture = _loadShares();
  }

  @override
  void dispose() {
    _recipientController.dispose();
    super.dispose();
  }

  Future<List<NoteShare>> _loadShares() {
    return widget.repository.listForNote(
      sourceNoteId: widget.note.id,
      ownerId: widget.ownerId,
    );
  }

  Future<void> _createShare() async {
    final recipientEmail = _recipientController.text.trim().toLowerCase();
    final emailError = FormValidators.email(recipientEmail);
    if (emailError != null) {
      setState(() => _errorMessage = emailError);
      return;
    }

    setState(() {
      _isCreating = true;
      _errorMessage = null;
      _sentToEmail = null;
    });
    try {
      final share = await widget.repository.create(
        note: widget.note,
        recipientEmail: recipientEmail,
      );
      if (!mounted) return;
      setState(() {
        _sentToEmail = share.recipientEmail ?? recipientEmail;
        _sharesFuture = _loadShares();
        _recipientController.clear();
      });
    } on Failure catch (error) {
      if (mounted) setState(() => _errorMessage = error.message);
    } on FormatException catch (error) {
      if (mounted) setState(() => _errorMessage = error.message);
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  Future<void> _revoke(NoteShare share) async {
    final shouldRevoke = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thu hồi quyền xem?'),
        content: const Text('Ghi chú sẽ bị gỡ khỏi hộp thư của người nhận.'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Huỷ'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Thu hồi'),
          ),
        ],
      ),
    );
    if (!mounted || shouldRevoke != true) return;

    setState(() => _errorMessage = null);
    try {
      await widget.repository.revoke(share.id);
      if (!mounted) return;
      setState(() {
        _sharesFuture = _loadShares();
      });
    } on Failure catch (error) {
      if (mounted) setState(() => _errorMessage = error.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Chia sẻ: ${widget.note.displayTitle}'),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Text(
                'Gửi bản chụp chỉ xem vào hộp thư SmartNote của email này.',
              ),
              const SizedBox(height: 12),
              TextField(
                key: const ValueKey<String>('share-recipient-email'),
                controller: _recipientController,
                enabled: !_isCreating,
                decoration: const InputDecoration(
                  labelText: 'Email người nhận',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _createShare(),
              ),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: _isCreating ? null : _createShare,
                icon: _isCreating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send_outlined),
                label: const Text('Gửi vào hộp thư'),
              ),
              if (_sentToEmail != null) ...<Widget>[
                const SizedBox(height: 12),
                Text('Đã gửi vào hộp thư của $_sentToEmail.'),
              ],
              if (_errorMessage != null) ...<Widget>[
                const SizedBox(height: 8),
                Text(
                  _errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const Divider(height: 24),
              Text('Đã chia sẻ', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              FutureBuilder<List<NoteShare>>(
                future: _sharesFuture,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Text(
                      'Không thể tải danh sách chia sẻ: ${snapshot.error}',
                    );
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final shares = snapshot.data!;
                  if (shares.isEmpty) {
                    return const Text('Chưa có liên kết nào.');
                  }
                  return ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 200),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: shares.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final share = shares[index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            share.recipientEmail ?? share.recipientId,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            'Tạo ${share.createdAt.toLocal()}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Wrap(
                            children: <Widget>[
                              IconButton(
                                tooltip: 'Thu hồi quyền xem',
                                onPressed: () => _revoke(share),
                                icon: const Icon(Icons.link_off),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Đóng'),
        ),
      ],
    );
  }
}

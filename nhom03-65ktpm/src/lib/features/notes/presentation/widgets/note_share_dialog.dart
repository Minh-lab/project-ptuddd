import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/error/failure.dart';
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
  String? _createdLink;
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
    final recipientId = _recipientController.text.trim();
    if (recipientId.isEmpty) {
      setState(() => _errorMessage = 'Nhập Firebase UID của người nhận.');
      return;
    }
    if (recipientId == widget.ownerId) {
      setState(
        () => _errorMessage = 'Không thể chia sẻ ghi chú cho chính bạn.',
      );
      return;
    }

    setState(() {
      _isCreating = true;
      _errorMessage = null;
      _createdLink = null;
    });
    try {
      final share = await widget.repository.create(
        note: widget.note,
        recipientId: recipientId,
      );
      if (!mounted) return;
      setState(() {
        _createdLink = _linkFor(share.id);
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
        title: const Text('Thu hồi liên kết?'),
        content: const Text('Người nhận sẽ không thể mở bản ghi chú này nữa.'),
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
        if (_createdLink == _linkFor(share.id)) _createdLink = null;
      });
    } on Failure catch (error) {
      if (mounted) setState(() => _errorMessage = error.message);
    }
  }

  Future<void> _copyLink(String link) async {
    try {
      await Clipboard.setData(ClipboardData(text: link));
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Đã sao chép liên kết.')));
      }
    } on PlatformException {
      if (mounted) {
        setState(
          () =>
              _errorMessage = 'Không thể sao chép liên kết trên thiết bị này.',
        );
      }
    } on MissingPluginException {
      if (mounted) {
        setState(() => _errorMessage = 'Tính năng sao chép chưa khả dụng.');
      }
    }
  }

  String _linkFor(String shareId) {
    if (kIsWeb) {
      return Uri.base
          .replace(queryParameters: <String, String>{'share': shareId})
          .toString();
    }
    return Uri(
      scheme: 'smartnote',
      host: 'share',
      path: '/$shareId',
    ).toString();
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
                'Chỉ tài khoản có Firebase UID này mới xem được bản chụp ghi chú.',
              ),
              const SizedBox(height: 12),
              TextField(
                key: const ValueKey<String>('share-recipient-uid'),
                controller: _recipientController,
                enabled: !_isCreating,
                decoration: const InputDecoration(
                  labelText: 'Firebase UID người nhận',
                  border: OutlineInputBorder(),
                ),
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
                    : const Icon(Icons.link),
                label: const Text('Tạo liên kết chỉ xem'),
              ),
              if (_createdLink != null) ...<Widget>[
                const SizedBox(height: 12),
                const Text('Liên kết mới (bản chụp tại thời điểm chia sẻ):'),
                SelectableText(_createdLink!),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => _copyLink(_createdLink!),
                    icon: const Icon(Icons.copy),
                    label: const Text('Sao chép'),
                  ),
                ),
              ],
              if (_errorMessage != null) ...<Widget>[
                const SizedBox(height: 8),
                Text(
                  _errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const Divider(height: 24),
              Text(
                'Liên kết đang hoạt động',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              FutureBuilder<List<NoteShare>>(
                future: _sharesFuture,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Text('Không thể tải liên kết: ${snapshot.error}');
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
                        final link = _linkFor(share.id);
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            'UID: ${share.recipientId}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            'Tạo ${share.createdAt.toLocal()}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Wrap(
                            spacing: 0,
                            children: <Widget>[
                              IconButton(
                                tooltip: 'Sao chép liên kết',
                                onPressed: () => _copyLink(link),
                                icon: const Icon(Icons.copy_outlined),
                              ),
                              IconButton(
                                tooltip: 'Thu hồi liên kết',
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

import 'package:flutter/material.dart';

import '../../domain/entities/received_note_share.dart';
import '../../domain/repositories/note_share_repository.dart';
import 'shared_note_page.dart';

class SharedNotesPage extends StatefulWidget {
  const SharedNotesPage({
    required this.repository,
    required this.recipientId,
    super.key,
  });

  final NoteShareRepository repository;
  final String recipientId;

  @override
  State<SharedNotesPage> createState() => _SharedNotesPageState();
}

class _SharedNotesPageState extends State<SharedNotesPage> {
  late Future<List<ReceivedNoteShare>> _sharesFuture;

  @override
  void initState() {
    super.initState();
    _sharesFuture = widget.repository.listReceived();
  }

  void _reload() {
    setState(() => _sharesFuture = widget.repository.listReceived());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Align(
          alignment: Alignment.centerRight,
          child: IconButton(
            tooltip: 'Tải lại hộp thư',
            onPressed: _reload,
            icon: const Icon(Icons.refresh),
          ),
        ),
        Expanded(
          child: FutureBuilder<List<ReceivedNoteShare>>(
            future: _sharesFuture,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return _Message(
                  icon: Icons.error_outline,
                  text: 'Không tải được hộp thư: ${snapshot.error}',
                );
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final shares = snapshot.data!;
              if (shares.isEmpty) {
                return const _Message(
                  icon: Icons.inbox_outlined,
                  text: 'Chưa có ghi chú nào được chia sẻ với bạn.',
                );
              }
              return ListView.separated(
                itemCount: shares.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final share = shares[index];
                  return ListTile(
                    leading: Icon(
                      share.kind.name == 'diary'
                          ? Icons.event_note_outlined
                          : Icons.sticky_note_2_outlined,
                    ),
                    title: Text(
                      share.title.trim().isEmpty
                          ? '(Chưa có tiêu đề)'
                          : share.title.trim(),
                    ),
                    subtitle: Text('Từ ${share.ownerEmail} · Chỉ xem'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => SharedNotePage(
                          repository: widget.repository,
                          shareId: share.id,
                          recipientId: widget.recipientId,
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 48, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 12),
          Text(text, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

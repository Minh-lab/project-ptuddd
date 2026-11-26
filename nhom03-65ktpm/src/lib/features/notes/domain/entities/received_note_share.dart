import 'package:equatable/equatable.dart';

import 'note.dart';

class ReceivedNoteShare extends Equatable {
  const ReceivedNoteShare({
    required this.id,
    required this.noteId,
    required this.ownerId,
    required this.ownerEmail,
    required this.title,
    required this.kind,
    required this.createdAt,
  });

  final String id;
  final String noteId;
  final String ownerId;
  final String ownerEmail;
  final String title;
  final NoteKind kind;
  final DateTime createdAt;

  @override
  List<Object?> get props => <Object?>[
    id,
    noteId,
    ownerId,
    ownerEmail,
    title,
    kind,
    createdAt,
  ];
}

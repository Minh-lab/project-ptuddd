import 'package:equatable/equatable.dart';

/// Một liên kết chia sẻ riêng cho một tài khoản Firebase.
class NoteShare extends Equatable {
  const NoteShare({
    required this.id,
    required this.noteId,
    required this.sourceNoteId,
    required this.ownerId,
    required this.recipientId,
    this.recipientEmail,
    required this.createdAt,
  });

  final String id;
  final String noteId;
  final String sourceNoteId;
  final String ownerId;
  final String recipientId;
  final String? recipientEmail;
  final DateTime createdAt;

  @override
  List<Object?> get props => <Object?>[
    id,
    noteId,
    sourceNoteId,
    ownerId,
    recipientId,
    recipientEmail,
    createdAt,
  ];
}

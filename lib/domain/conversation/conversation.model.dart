import 'package:equatable/equatable.dart';
import 'package:flutter_chatflow/models.dart';

class ConversationModel extends Equatable {
  final int id;
  final List<ChatUser> participants;
  final String lastMessage;
  final DateTime timestamp;

  const ConversationModel({
    required this.id,
    required this.participants,
    this.lastMessage = "",
    required this.timestamp,
  });

  @override
  List<Object?> get props => [lastMessage, timestamp];

  factory ConversationModel.fromMap(Map map) => ConversationModel(
    id: map['id'],
    participants:
        (map['participants'] as List)
            .map((e) => ChatUser(userID: e['userId'].toString(), name: e['user'], photoUrl: e['avatar']))
            .toList(),
    lastMessage: map['lastMessage'] ?? "",
    timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
  );
}

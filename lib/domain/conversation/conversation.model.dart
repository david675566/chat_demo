import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
// ignore: depend_on_referenced_packages
import 'package:flutter_chat_types/flutter_chat_types.dart' as chat_type;

class ConversationModel extends Equatable {
  final int id;
  final List<chat_type.User> participants;
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
            .map((e) => chat_type.User(id: e['userId'].toString(), firstName: e['user'], imageUrl: e['avatar']))
            .toList(),
    lastMessage: map['lastMessage'] ?? "",
    timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
  );
}

part of 'chat.bloc.dart';

sealed class ChatEvent {}

class RequestGetMessages extends ChatEvent {
  final int conversationId;
  RequestGetMessages({required this.conversationId});
}

class RequestPostTextMessage extends ChatEvent {
  final int conversationId;
  final chat_types.TextMessage message;
  RequestPostTextMessage({required this.conversationId, required this.message});
}

class RequestMessageReaction extends ChatEvent {
  final int conversationId;
  final String targetMessage;
  final String reaction;
  RequestMessageReaction({required this.conversationId, required this.targetMessage, required this.reaction});
}

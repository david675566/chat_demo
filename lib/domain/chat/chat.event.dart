part of 'chat.bloc.dart';

sealed class ChatEvent {}

class InitializeChat extends ChatEvent {}

class RequestGetMessages extends ChatEvent {
  final int conversationId;
  RequestGetMessages({required this.conversationId});
}

class RequestPostMessage extends ChatEvent {
  final int conversationId;
  final chat_types.Message message;
  RequestPostMessage({required this.conversationId, required this.message});
}

class RequestMessageReaction extends ChatEvent {
  final int conversationId;
  final String targetMessage;
  final String reaction;
  RequestMessageReaction({required this.conversationId, required this.targetMessage, required this.reaction});
}

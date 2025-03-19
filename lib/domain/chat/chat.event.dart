part of 'chat.bloc.dart';

sealed class ChatEvent {}

class RequestGetChatHistory extends ChatEvent {
  final int conversationId;
  RequestGetChatHistory({required this.conversationId});
}

class RequestPostTextChat extends ChatEvent {
  final int conversationId;
  final chat_model.TextMessage message;
  RequestPostTextChat({required this.conversationId, required this.message});
}

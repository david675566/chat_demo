part of 'conversation.bloc.dart';

sealed class ConversationEvent {}

class RequestGetConversations extends ConversationEvent {}

class RequestNewConversation extends ConversationEvent {}

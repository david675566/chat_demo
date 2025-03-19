part of 'conversation.bloc.dart';

sealed class ConversationState {}

class ConversationInitial extends ConversationState {}

class FetchingConversation extends ConversationState {}

class ConversationReady extends ConversationState {
  final List<ConversationModel> data;
  ConversationReady({this.data = const []});
}

class ConversationLoadFailure extends ConversationState {
  final Object? error;
  final String? errorStr;
  ConversationLoadFailure({this.error, this.errorStr});
}

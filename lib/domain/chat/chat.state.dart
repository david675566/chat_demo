part of 'chat.bloc.dart';

sealed class ChatState {}

class ChatInitial extends ChatState {}

class FetchingChat extends ChatState {}

class ChatReady extends ChatState {
  final List<chat_model.Message> data;
  ChatReady({this.data = const []});
}

class ChatLoadFailure extends ChatState {
  final Object? error;
  final String? errorStr;
  ChatLoadFailure({this.error, this.errorStr});
}

class ChatPostFailure extends ChatState {
  final Object? error;
  final String? errorStr;
  ChatPostFailure({this.error, this.errorStr});
}

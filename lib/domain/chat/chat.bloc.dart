import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as chat_types;
import 'package:uuid/uuid.dart';

// local
import 'package:chat_demo/provider/api_provider.dart';

part 'chat.event.dart';
part 'chat.repo.dart';
part 'chat.state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  ChatBloc({required ChatRepository chatRepository}) : _chatRepository = chatRepository, super(ChatInitial()) {
    on<RequestGetMessages>(_onRequestMessages);
    on<RequestPostTextMessage>(_onPostTextMessage);
    on<RequestMessageReaction>(_onMessageReaction);
  }

  final ChatRepository _chatRepository;

  FutureOr<void> _onRequestMessages(RequestGetMessages event, Emitter<ChatState> emit) async {
    emit(FetchingChat());
    await _chatRepository
        .fetchMessages(event.conversationId)
        .then((result) => emit(ChatReady(data: result)))
        .onError((error, stacktrace) => emit(ChatLoadFailure(error: error, errorStr: error.toString())));
  }

  FutureOr<void> _onPostTextMessage(RequestPostTextMessage event, Emitter<ChatState> emit) async {
    emit.onEach(
      _chatRepository.postTextMessage(event.conversationId, event.message),
      onData: (result) => {emit(ChatReady(data: result))},
    );
  }

  FutureOr<void> _onMessageReaction(RequestMessageReaction event, Emitter<ChatState> emit) {
    final result = _chatRepository.reactMessage(event.conversationId, event.targetMessage, event.reaction);
    emit(ChatReady(data: result));
  }
}

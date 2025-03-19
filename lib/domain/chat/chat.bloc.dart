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
    on<RequestGetChatHistory>(_onRequestConversations);
    on<RequestPostTextChat>(_onPostConversations);
  }

  final ChatRepository _chatRepository;
  final currentUser = chat_types.User(
    id: "114514",
    firstName: "David",
    imageUrl: "https://gravatar.com/avatar/572097362be9eba959dd4471c15cf6c0b700c66648bc3a2814ac75827110d6a2",
  );

  FutureOr<void> _onRequestConversations(RequestGetChatHistory event, Emitter<ChatState> emit) async {
    emit(FetchingChat());
    await _chatRepository
        .fetchMessages(event.conversationId)
        .then((result) => emit(ChatReady(data: result)))
        .onError((error, stacktrace) => emit(ChatLoadFailure(error: error, errorStr: error.toString())));
  }

  FutureOr<void> _onPostConversations(RequestPostTextChat event, Emitter<ChatState> emit) async {
    emit.onEach(
      _chatRepository.postTextMessage(event.conversationId, event.message),
      onData: (result) => {emit(ChatReady(data: result))},
    );
  }
}

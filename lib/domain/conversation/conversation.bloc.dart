import 'dart:async';

import 'package:chat_demo/domain/chat/chat.bloc.dart';
import 'package:chat_demo/domain/conversation/conversation.model.dart';
import 'package:chat_demo/provider/api_provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'conversation.event.dart';
part 'conversation.repo.dart';
part 'conversation.state.dart';

class ConversationBloc extends Bloc<ConversationEvent, ConversationState> {
  ConversationBloc({required ConversationRepository convRepository})
    : _convRepository = convRepository,
      super(ConversationInitial()) {
    on<RequestGetConversations>(_onRequestConversations);
    on<RequestNewConversation>(_onNewConversation);
  }

  final ConversationRepository _convRepository;

  FutureOr<void> _onRequestConversations(RequestGetConversations event, Emitter<ConversationState> emit) async {
    emit(FetchingConversation());
    await _convRepository
        .fetchConversations()
        .then((result) => emit(ConversationReady(data: result)))
        .onError((error, stacktrace) => emit(ConversationLoadFailure(error: error, errorStr: error.toString())));
  }

  FutureOr<void> _onNewConversation(RequestNewConversation event, Emitter<ConversationState> emit) async {
    await _convRepository.createConversation().then((result) => emit(ConversationReady(data: result)));
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart' as chat_ui;
import 'package:flutter_chat_types/flutter_chat_types.dart' as chat_types;

// local
import 'package:chat_demo/domain/chat/chat.bloc.dart';
import 'package:uuid/uuid.dart';

class ChatRoomView extends StatelessWidget {
  const ChatRoomView({required this.conversationId, required this.participants, super.key});
  final int conversationId;
  final List<chat_types.User> participants;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ChatBloc>(
      create: (context) {
        return ChatBloc(chatRepository: ChatRepository())..add(RequestGetChatHistory(conversationId: conversationId));
      },
      child: BlocBuilder<ChatBloc, ChatState>(
        buildWhen: (previous, current) => previous != current,
        builder:
            (context, state) => chat_ui.Chat(
              showUserAvatars: true,
              showUserNames: true,
              messages: (state is ChatReady) ? state.data : [],
              user: context.read<ChatBloc>().currentUser,
              onSendPressed: (msg) {
                final message = chat_types.TextMessage.fromPartial(
                  id: Uuid().v4(),
                  author: context.read<ChatBloc>().currentUser,
                  partialText: msg,
                  showStatus: true,
                  status: chat_types.Status.sending,
                );

                context.read<ChatBloc>().add(RequestPostTextChat(conversationId: conversationId, message: message));
              },
            ),
      ),
    );
  }
}

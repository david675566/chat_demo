import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chatflow/chatflow.dart';
import 'package:flutter_chatflow/models.dart';

// local
import 'package:chat_demo/domain/chat/chat.bloc.dart';
import 'package:flutter_chatflow/utils/types.dart';

class ChatRoomView extends StatelessWidget {
  const ChatRoomView({required this.conversationId, required this.participants, super.key});
  final int conversationId;
  final List<ChatUser> participants;

  @override
  Widget build(BuildContext context) {
    // void _handleOnAttachmentPressed({Message? repliedTo}) async {
    //   /// logic for adding image to chat.
    //   /// You could use a dialog to choose between different media types
    //   /// And rename the function accordingly
    // }

    return Scaffold(
      appBar: AppBar(title: Text(participants.map((e) => e.name!).join('&'))),
      body: SafeArea(
        child: BlocProvider<ChatBloc>(
      create: (context) {
        return ChatBloc(chatRepository: ChatRepository())..add(RequestGetChatHistory(conversationId: conversationId));
      },
      child: BlocBuilder<ChatBloc, ChatState>(
        buildWhen: (previous, current) => previous != current,
        builder:
            (context, state) {
              final currentUser = context.read<ChatBloc>().currentUser;

              return ChatFlow(
                showUserAvatarInChat: true,
                messages: (state is ChatReady) ? state.data : [],
                chatUser: currentUser,
                onSendPressed: (msg, {repliedTo}) {
                  int createdAt = DateTime.now().millisecondsSinceEpoch;

                  final textMessage = TextMessage(
                    author: currentUser,
                    createdAt: createdAt,
                    text: msg,
                    status: DeliveryStatus.sending,
                );

                  context.read<ChatBloc>().add(
                    RequestPostTextChat(conversationId: conversationId, message: textMessage),
                  );
                },
                // onAttachmentPressed: _handleOnAttachmentPressed,
              );
            },
          ),
        ),
      ),
    );
  }
}

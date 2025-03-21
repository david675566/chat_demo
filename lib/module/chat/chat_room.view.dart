import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as chat_types;
import 'package:uuid/uuid.dart';

// local
import 'package:chat_demo/domain/chat/chat.bloc.dart';
import 'package:chat_demo/widget/chat_input.dart';
import 'package:chat_demo/widget/message_bubble.dart';

class ChatRoomView extends StatelessWidget {
  const ChatRoomView({required this.conversationId, required this.participants, super.key});
  final int conversationId;
  final List<chat_types.User> participants;


  @override
  Widget build(BuildContext context) {
    final chatRepo = ChatRepository();

    return BlocProvider<ChatBloc>(
      create: (context) {
        return ChatBloc(chatRepository: chatRepo)..add(RequestGetMessages(conversationId: conversationId));
      },
      child: BlocBuilder<ChatBloc, ChatState>(
        buildWhen: (previous, current) => previous != current,
        builder: (context, state) {
          final messages = (state is ChatReady) ? state.data : <chat_types.Message>[];
          return Scaffold(
            appBar: AppBar(title: Text(participants.map((e) => e.firstName!).join('&'))),
            body: SafeArea(
              child: ListView.separated(
                reverse: true,
                padding: const EdgeInsets.symmetric(vertical: 12),
                separatorBuilder: (context, index) => const SizedBox(height: 9),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final msg = messages[index];
                  final isOutgoing = (chatRepo.currentUser.id == msg.author.id);
                  return Padding(
                    padding: EdgeInsets.only(bottom: (msg.metadata?.isNotEmpty??false)?30:0),
                    child: MessageWidget(
                      message: messages[index],
                      isOutgoing: isOutgoing,
                      reactions: ChatRepository.emojiToStringMap.keys.toList(),
                      onReactionTap: (reaction) {
                        print("Reaction: $reaction");
                        context.read<ChatBloc>().add(
                          RequestMessageReaction(
                            conversationId: conversationId,
                            targetMessage: messages[index].id,
                            reaction: reaction,
                          ),
                      );
                    },
                  ),
                  );
                },
              ),
            ),
            bottomNavigationBar: BottomAppBar(
              child: InputWidget(
                onSendPressed: (text) {
                  debugPrint("Sending: $text");
                  final message = chat_types.TextMessage(
                    id: Uuid().v4(),
                    author: chatRepo.currentUser,
                    text: text,
                    showStatus: true,
                    status: chat_types.Status.sending,
                    createdAt: DateTime.now().millisecondsSinceEpoch,
                  );
                  context.read<ChatBloc>().add(
                    RequestPostTextMessage(conversationId: conversationId, message: message),
                  );
                },
              )
            ),
          );
        },
      ),
    );
  }
}

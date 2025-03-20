import 'package:cached_network_image/cached_network_image.dart';
import 'package:chat_demo/widget/user_avatar.dart';
import 'package:chat_input/chat_input.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_bubble/chat_bubble.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart' as chat_ui;
import 'package:flutter_chat_types/flutter_chat_types.dart' as chat_types;

// local
import 'package:chat_demo/domain/chat/chat.bloc.dart';
import 'package:jiffy/jiffy.dart';
import 'package:uuid/uuid.dart';

class ChatRoomView extends StatelessWidget {
  const ChatRoomView({required this.conversationId, required this.participants, super.key});
  final int conversationId;
  final List<chat_types.User> participants;

  @override
  Widget build(BuildContext context) {
    final chatRepo = ChatRepository();

    return BlocProvider<ChatBloc>(
      create: (context) {
        return ChatBloc(chatRepository: chatRepo)..add(RequestGetChatHistory(conversationId: conversationId));
      },
      child: BlocBuilder<ChatBloc, ChatState>(
        buildWhen: (previous, current) => previous != current,
        builder: (context, state) {
          final messages = (state is ChatReady) ? state.data : <chat_types.Message>[];
          return Scaffold(
            appBar: AppBar(),
            body: SafeArea(
              child: CustomScrollView(
                reverse: true,
                slivers: [
                  SliverList.separated(
                    separatorBuilder: (context, index) => const SizedBox(height: 9),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      final isOutgoing = (chatRepo.currentUser.id == msg.author.id);
                      return Padding(
                        padding: const EdgeInsets.all(3),
                        child: MessageWidget(message: messages[index], isOutgoing: isOutgoing),
                      );
                    },
                  ),
                ],
              ),
            ),
            bottomNavigationBar: BottomAppBar(
              padding: const EdgeInsets.all(0),
              child: InputWidget(
                onSendAudio: (audioFile, duration) => debugPrint("Sending Audio"),
                onSendText: (text) {
                  final message = chat_types.TextMessage(
                    id: Uuid().v4(),
                    author: chatRepo.currentUser,
                    text: text,
                    showStatus: true,
                    status: chat_types.Status.sending,
                    createdAt: DateTime.now().millisecondsSinceEpoch,
                  );

                  context.read<ChatBloc>().add(RequestPostTextChat(conversationId: conversationId, message: message));
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

//
// Although I could get everything done by chat_ui's widget,
// but that plugin's widgets are all heavily depend on their own "InheritedChatTheme"
// means the context must stays as one otherwise it'll broke.
// (e.g. Trying to get a nice Hero style w/ "Navigator.push()" -> The method where it's generating a new 'context' object? broke, "Null check operator used on a null value")
//
class MessageWidget extends StatelessWidget {
  const MessageWidget({super.key, required this.message, this.isOutgoing = false});
  final chat_types.Message message;
  final bool isOutgoing;

  static const iconSize = 12.0;

  @override
  Widget build(BuildContext context) {
    final messageWidth = MediaQuery.sizeOf(context).width * 0.6;
    final showStatus = (message.showStatus ?? false);

    if (message is chat_types.SystemMessage) {
      // System Message, no bubbles, @ center & must be italic
      return ConstrainedBox(
        constraints: BoxConstraints(maxHeight: 18),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              (message as chat_types.SystemMessage).text,
              softWrap: false,
              style: TextStyle(fontSize: 14, color: Colors.grey, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      );
    }

    //
    // UGC Messages.
    //
    return Row(
      mainAxisAlignment: (isOutgoing) ? MainAxisAlignment.end : MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const SizedBox(width: 9),
        buildPrefix(message: message),
        const SizedBox(width: 12),
        ChatBubble(
          clipper: ChatBubbleClipper5(
            secondRadius: 15,
            type: (isOutgoing) ? BubbleType.sendBubble : BubbleType.receiverBubble,
          ),
          backGroundColor: (isOutgoing) ? Colors.blueAccent : Color(0xffE7E7ED),
          child: Container(
            constraints: BoxConstraints(maxWidth: messageWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isOutgoing)
                  Text(message.author.firstName!, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                MessageContentWidget(message: message, isOutgoing: isOutgoing, messageWidth: messageWidth),
              ],
            ),
          ),
        ),
        SizedBox(width: (showStatus) ? 3 : 12),
        buildSuffix(message: message),
        if (showStatus) const SizedBox(width: 3),
      ],
    );
  }

  Widget buildPrefix({required chat_types.Message message}) {
    if (isOutgoing) {
      return buildTime(message.createdAt!);
    }

    return buildAvatar(message.author);
  }

  Widget buildSuffix({required chat_types.Message message}) {
    if (!isOutgoing) {
      return buildTime(message.createdAt!);
    }

    // Message status
    switch (message.status) {
      case chat_types.Status.sending:
        return SizedBox(width: iconSize, height: iconSize, child: CircularProgressIndicator.adaptive(strokeWidth: 1));
      case chat_types.Status.delivered:
        return Icon(CupertinoIcons.check_mark, size: iconSize);
      case chat_types.Status.error:
        return Icon(CupertinoIcons.clear_circled, size: iconSize, color: Colors.redAccent);
      default:
        return SizedBox();
    }
  }

  Widget buildTime(int createdAt) {
    return Text(
      Jiffy.parseFromMillisecondsSinceEpoch(createdAt).Hm,
      style: TextStyle(color: Colors.grey, fontSize: 14),
    );
  }

  Widget buildAvatar(chat_types.User author) {
    return Avatar(from: author);
  }
}

class MessageContentWidget extends StatelessWidget {
  const MessageContentWidget({super.key, required this.message, this.isOutgoing = false, required this.messageWidth});
  final chat_types.Message message;
  final bool isOutgoing; // to determine theme.
  final double messageWidth;

  @override
  Widget build(BuildContext context) {
    // This demo only cares about image & text, would be enough
    if (message is chat_types.ImageMessage) {
      final msg = (message as chat_types.ImageMessage);
      return GestureDetector(
        onTap: () => debugPrint("Supposed to have a full screen here but chat_ui didn't expose all the model out."),
        child: Hero(
          tag: msg.id,
          child: CachedNetworkImage(
            imageUrl: msg.uri,
            progressIndicatorBuilder:
                (context, url, progress) => CircularProgressIndicator.adaptive(value: progress.progress),
          ),
        ),
      );
    }

    // assume it's all text.
    return chat_ui.TextMessageText(
      bodyTextStyle: TextStyle(fontSize: 14, color: (isOutgoing) ? Colors.white : Colors.black),
      text: (message as chat_types.TextMessage).text,
    );
  }
}

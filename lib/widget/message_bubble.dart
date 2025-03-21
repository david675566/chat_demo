import 'package:chat_demo/domain/chat/chat.bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import 'package:jiffy/jiffy.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_chat_bubble/chat_bubble.dart';
import 'package:flutter_chat_reactions/flutter_chat_reactions.dart';
import 'package:flutter_chat_reactions/utilities/hero_dialog_route.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart' as chat_ui;
import 'package:flutter_chat_types/flutter_chat_types.dart' as chat_types;

// local
import './user_avatar.dart';

//
// Although I could get everything done by chat_ui's widget,
// but that plugin's widgets are all heavily depend on their own "InheritedChatTheme"
// means the context must stays as one otherwise it'll broke.
// (e.g. Trying to get a nice Hero style w/ "Navigator.push()" -> The method where it's generating a new 'context' object? broke, "Null check operator used on a null value")
//
class MessageWidget extends StatelessWidget {
  const MessageWidget({
    super.key,
    required this.message,
    this.isOutgoing = false,
    required this.onReactionTap,
    required this.reactions,
  });
  final chat_types.Message message;
  final bool isOutgoing;
  final List<String> reactions;
  final void Function(String) onReactionTap;

  static const iconSize = 12.0;

  // message timestamp
  Widget buildTime(int createdAt) => Text(
    Jiffy.parseFromMillisecondsSinceEpoch(createdAt).Hm,
    style: TextStyle(color: Colors.grey, fontSize: 14),
  );

  // message author avatar
  Widget buildAvatar(chat_types.User author) => Avatar(from: author);

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
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      );
    }

    //
    // UGC Messages.
    // with Emojis/Reactions
    //
    return Row(
      mainAxisAlignment:
          (isOutgoing) ? MainAxisAlignment.end : MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const SizedBox(width: 9),
        buildPrefix(message: message),
        const SizedBox(width: 12),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onLongPress: () {
            Navigator.of(context).push(
              HeroDialogRoute(
                builder: (context) {
                  return ReactionsDialogWidget(
                    id: message.id, // unique id for message
                    messageWidget: Align(
                      alignment:
                          (isOutgoing)
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                      child: buildMessageBubble(messageWidth),
                    ), // message widget
                    widgetAlignment:
                        (isOutgoing)
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                    menuItems: [],
                    reactions: reactions,
                    onReactionTap: (reaction) => onReactionTap(reaction),
                    onContextMenuTap: (menuItem) {
                      print('menu item: $menuItem');
                      // handle context menu item
                    },
                  );
                },
              ),
            );
          },
          child: Stack(
            alignment: AlignmentDirectional.bottomEnd,
            clipBehavior: Clip.none,
            children: [
              Hero(tag: message.id, child: buildMessageBubble(messageWidth)),

              // Custom Reactions row w/ numbers
              Positioned(
                bottom: -30,
                child: 
              EmojiListWidget(message: message),
              ),
            ],
          ),
        ),
        SizedBox(width: (showStatus) ? 3 : 12),
        buildSuffix(message: message),
        if (showStatus) const SizedBox(width: 3),
      ],
    );
  }

  Widget buildMessageBubble(double messageWidth) {
    return ChatBubble(
      alignment: (isOutgoing) ? Alignment.centerRight : Alignment.centerLeft,
      clipper: ChatBubbleClipper5(
        secondRadius: 15,
        type: (isOutgoing) ? BubbleType.sendBubble : BubbleType.receiverBubble,
      ),
      backGroundColor: (isOutgoing) ? Colors.blueAccent : Color(0xffE7E7ED),
      child: Container(
        constraints: BoxConstraints(maxWidth: messageWidth),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isOutgoing)
              Text(
                message.author.firstName!,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            MessageContentWidget(
              message: message,
              isOutgoing: isOutgoing,
              messageWidth: messageWidth,
            ),
          ],
        ),
      ),
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
        return SizedBox(
          width: iconSize,
          height: iconSize,
          child: CircularProgressIndicator.adaptive(strokeWidth: 1),
        );
      case chat_types.Status.delivered:
        return Icon(CupertinoIcons.check_mark, size: iconSize);
      case chat_types.Status.error:
        return Icon(
          CupertinoIcons.clear_circled,
          size: iconSize,
          color: Colors.redAccent,
        );
      default:
        return SizedBox();
    }
  }
}

class MessageContentWidget extends StatelessWidget {
  const MessageContentWidget({
    super.key,
    required this.message,
    this.isOutgoing = false,
    required this.messageWidth,
  });
  final chat_types.Message message;
  final bool isOutgoing; // to determine theme.
  final double messageWidth;

  @override
  Widget build(BuildContext context) {
    // This demo only cares about image & text, would be enough
    if (message is chat_types.ImageMessage) {
      final msg = (message as chat_types.ImageMessage);
      return GestureDetector(
        onTap:
            () => debugPrint(
              "Supposed to have a full screen here but chat_ui didn't expose all the model out.",
            ),
        child: CachedNetworkImage(
          imageUrl: msg.uri,
          progressIndicatorBuilder:
              (context, url, progress) =>
                  CircularProgressIndicator.adaptive(value: progress.progress),
        ),
      );
    }

    // assume it's all text.
    return chat_ui.TextMessageText(
      options: chat_ui.TextMessageOptions(
        isTextSelectable: false,
      ),
      bodyTextStyle: TextStyle(
        fontSize: 14,
        color: (isOutgoing) ? Colors.white : Colors.black,
      ),
      text: (message as chat_types.TextMessage).text,
    );
  }
}

class EmojiListWidget extends StatelessWidget {
  const EmojiListWidget({super.key, required this.message});
  final chat_types.Message message;

  @override
  Widget build(BuildContext context) {
    if (message.metadata?.isEmpty ?? true) {
      return const SizedBox();
    }

    final emojiList = ChatRepository.emojiToStringMap.entries;
    final messageReactions = message.metadata!.entries;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.1,
      ),
      padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(128),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 9,
        children:
            // Iterate through all reactions and display them
            messageReactions.map<Widget>((item) {
              // find the corresponding emoji
              final emoji = emojiList.firstWhere((e) => e.value == item.key);
              return _buildContent(emoji.key, item.value);
            }).toList(),
      ),
    );
  }

  Widget _buildContent(String emoji, int counts) {
    return Row(
      children: [
        // Reaction Icon
        Text(emoji),
        const SizedBox(width: 1),
        // Reaction Counts
        Text(counts.toString(), style: TextStyle(color: Colors.white)),
      ],
    );
  }
}

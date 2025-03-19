part of 'chat.bloc.dart';

class ChatRepository {
  // would need a cache to temp. stores all histories.
  final List<chat_model.Message> messages = [];

  Future<List<chat_model.Message>> fetchMessages(int conversationId) async {
    // get the messages
    final res = await ApiProvider().fetchMessages(conversationId);
    messages.clear();
    messages.addAll(res.map((e) => fromChatJson(e)).toList().reversed);
    return messages;
  }

  // Use one-shot stream to track sending progress.
  Stream<List<chat_model.Message>> postTextMessage(int conversationId, chat_model.TextMessage message) async* {
    final messageId = message.messageID;
    messages.insert(0, message);
    yield messages;

    final body = {
      'conversationId': conversationId,
      'userId': int.parse(message.author.userID),
      'user': message.author.name,
      "avatar": message.author.photoUrl,
      "messageType": "text",
      "message": message.text,
      "reactions": {"like": 0, "love": 0, "laugh": 0},
      "timestamp": DateTime.now().millisecondsSinceEpoch,
    };

    // post messages
    yield await ApiProvider()
        .postMessage(conversationId, body)
        .then((res) {
          final pos = messages.indexWhere((e) => e.messageID == messageId); // Can't assume it stays exactly @ 0.
          message.status = chat_util.DeliveryStatus.delivered;
          messages[pos] = message;
          return messages;
        })
        .onError((error, stackTrace) {
          // Still send back message w/ error state
          final pos = messages.indexWhere((e) => e.messageID == messageId); // Can't assume it stays exactly @ 0.
          message.status = chat_util.DeliveryStatus.sending;
          messages[pos] = message;
          return messages;
        });
  }

  // A helper method to translate chat data format
  chat_model.Message fromChatJson(Map json) {
    final author = chat_model.ChatUser(
      userID: (json['userId'] as int).toString(),
      name: json['user'],
      photoUrl: json['avatar'],
    );
    switch (json['messageType']) {
      case "image":
        return chat_model.ImageMessage(
          messageID: Uuid().v4(),
          uri: json['message'],
          author: author,
          createdAt: json['timestamp'],
        );
      case "file":
        return chat_model.FileMessage(
          messageID: Uuid().v4(),
          uri: json['message'],
          author: author,
          createdAt: json['timestamp'],
        );
      case "system":
        return chat_model.ChatInfo(messageID: Uuid().v4(), info: json['message'], createdAt: json['timestamp']);
      case "text":
      default:
        return chat_model.TextMessage(
          messageID: Uuid().v4(),
          text: json['message'],
          author: author,
          createdAt: json['timestamp'],
        );
    }
  }
}

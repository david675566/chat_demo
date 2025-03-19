part of 'chat.bloc.dart';

class ChatRepository {
  // would need a cache to temp. stores all histories.
  final List<chat_types.Message> messages = [];

  Future<List<chat_types.Message>> fetchMessages(int conversationId) async {
    // get the messages
    final res = await ApiProvider().fetchMessages(conversationId);
    messages.clear();
    messages.addAll(res.map((e) => fromChatJson(e)).toList().reversed);
    return messages;
  }

  // Use one-shot stream to track sending progress.
  Stream<List<chat_types.Message>> postTextMessage(int conversationId, chat_types.TextMessage message) async* {
    final messageId = message.id;
    messages.insert(0, message);
    yield messages;

    final body = {
      'conversationId': conversationId,
      'userId': int.parse(message.author.id),
      'user': message.author.firstName,
      "avatar": message.author.imageUrl,
      "messageType": "text",
      "message": message.text,
      "reactions": {"like": 0, "love": 0, "laugh": 0},
      "timestamp": DateTime.now().millisecondsSinceEpoch,
    };

    // post messages
    yield await ApiProvider()
        .postMessage(conversationId, body)
        .then((res) {
          final pos = messages.indexWhere((e) => e.id == messageId); // Can't assume it stays exactly @ 0.
          messages[pos] = message.copyWith(showStatus: true, status: chat_types.Status.delivered);
          return messages;
        })
        .onError((error, stackTrace) {
          // Still send back message w/ error state
          final pos = messages.indexWhere((e) => e.id == messageId); // Can't assume it stays exactly @ 0.
          messages[pos] = message.copyWith(status: chat_types.Status.error);
          return messages;
        });
  }

  // A helper method to translate chat data format
  chat_types.Message fromChatJson(Map json) {
    final chat_types.User author = chat_types.User(
      id: (json['userId'] as int).toString(),
      firstName: json['user'],
      imageUrl: json['avatar'],
    );
    switch (json['messageType']) {
      case "image":
        return chat_types.ImageMessage(
          id: Uuid().v4(),
          name: json['user'],
          size: 0,
          uri: json['message'],
          author: author,
        );
      case "file":
        return chat_types.FileMessage(
          id: Uuid().v4(),
          name: json['user'],
          size: 0,
          uri: json['message'],
          author: author,
        );
      case "system":
        return chat_types.SystemMessage(id: Uuid().v4(), text: json['message']);
      case "text":
      default:
        return chat_types.TextMessage(id: Uuid().v4(), text: json['message'], author: author);
    }
  }
}

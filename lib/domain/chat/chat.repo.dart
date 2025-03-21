part of 'chat.bloc.dart';

class ChatRepository {
  final currentUser = chat_types.User(
    id: "114514",
    firstName: "David",
    imageUrl:
        "https://gravatar.com/avatar/572097362be9eba959dd4471c15cf6c0b700c66648bc3a2814ac75827110d6a2",
  );

  // would need a cache to temp. stores all histories.
  final List<chat_types.Message> messages = [];

  static const Map<String, String> emojiToStringMap = {
    '👍': 'like',
    '❤️': 'love',
    '😆': 'laugh',
  };

  // Simulate Live Chat
  Stream<chat_types.Message> generateRandomMessage() async* {
    final template = List<chat_types.Message>.from(messages.where((e) => e.author != currentUser));
    while (true) {
      await Future.delayed(Duration(seconds: 3));
      final msg = template[Random().nextInt(template.length)];
      yield msg.copyWith(
          id: Uuid().v4(),
          createdAt: DateTime.now().millisecondsSinceEpoch,
          metadata: {"like": 0, "love": 0, "laugh": 0},
        );
    }
  }

  // Get all messages
  Future<List<chat_types.Message>> fetchMessages(int conversationId) async {
    // get the messages
    final res = await ApiProvider().fetchMessages(conversationId);
    messages.clear();
    messages.addAll(res.map((e) => fromChatJson(e)).toList().reversed);
    return messages;
  }

  // Message Reaction
  List<chat_types.Message> reactMessage(
    int conversationId,
    String messageId,
    String reaction,
  ) {
    final emojiString = emojiToStringMap[reaction];
    if (emojiString == null) {
      return messages;
    }

    // modify local cache
    final targetIdx = messages.indexWhere(
      (element) => element.id == messageId,
    );
    if(targetIdx == -1){
      return messages;
    }
    if (messages[targetIdx].metadata?.isEmpty ?? true) {
      // Append all reactions map to the message metadata
      messages[targetIdx] = messages[targetIdx].copyWith(
        metadata: emojiToStringMap.map((key, value) => MapEntry(value, 0)),
      );
    }
    messages[targetIdx].metadata?[emojiString] += 1;

    final targetMessage = messages[targetIdx];
    String identifier;
    if (targetMessage is chat_types.ImageMessage) {
      identifier =
          targetMessage.uri +
          targetMessage.author.firstName! +
          targetMessage.createdAt.toString();
    } else {
      final msg = targetMessage as chat_types.TextMessage;
      identifier = msg.text + msg.author.firstName! + msg.createdAt.toString();
    }
    final body = {
      "reaction": emojiString,
      "operation": "add",
      "identifier": identifier,
    };

    ApiProvider().reactMessage(conversationId, body);
    return messages;
  }

  // Post Message
  // Use one-shot stream to track sending progress.
  Stream<List<chat_types.Message>> postMessage(
    int conversationId,
    chat_types.Message message,
  ) async* {
    final messageId = message.id;
    messages.insert(0, message);
    yield messages;

    final isImage = message is chat_types.ImageMessage;
    String content = "";
    if(isImage){
      content = message.uri;
    }else{
      content = (message as chat_types.TextMessage).text;
    }

    // I'm tend not to modify the original json, stay with the flow like I can't access backend.
    final body = {
      'conversationId': conversationId,
      'userId': int.parse(message.author.id),
      'user': message.author.firstName,
      "avatar": message.author.imageUrl,
      "messageType": (isImage) ? "image" : "text",
      "message":content,
      "reactions":message.metadata?['reactions'] ?? {"like": 0, "love": 0, "laugh": 0},
      "timestamp": message.createdAt!,
    };

    // post messages
    yield await ApiProvider()
        .postMessage(conversationId, body)
        .then((res) {
          final pos = messages.indexWhere(
            (e) => e.id == messageId,
          ); // Can't assume it stays exactly @ 0.
          messages[pos] = message.copyWith(
            showStatus: true,
            status: chat_types.Status.delivered,
          );
          return messages;
        })
        .onError((error, stackTrace) {
          // Still send back message w/ error state
          final pos = messages.indexWhere(
            (e) => e.id == messageId,
          ); // Can't assume it stays exactly @ 0.
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
          createdAt: json['timestamp'],
          metadata: json['reactions'],
        );
      case "system":
        return chat_types.SystemMessage(
          id: Uuid().v4(),
          text: json['message'],
          createdAt: json['timestamp'],
        );
      case "text":
      default:
        return chat_types.TextMessage(
          id: Uuid().v4(),
          text: json['message'],
          author: author,
          createdAt: json['timestamp'],
          metadata: json['reactions'],
        );
    }
  }
}

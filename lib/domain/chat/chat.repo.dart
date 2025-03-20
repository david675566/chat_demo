part of 'chat.bloc.dart';

class ChatRepository {
  final currentUser = chat_types.User(
    id: "114514",
    firstName: "David",
    imageUrl: "https://gravatar.com/avatar/572097362be9eba959dd4471c15cf6c0b700c66648bc3a2814ac75827110d6a2",
  );

  // would need a cache to temp. stores all histories.
  final List<chat_types.Message> _messages = [];

  Map<String, String> emojiToStringMap = {'👍': 'like', '❤️': 'love', '😆': 'laugh'};

  // Get all messages
  Future<List<chat_types.Message>> fetchMessages(int conversationId) async {
    // get the messages
    final res = await ApiProvider().fetchMessages(conversationId);
    _messages.clear();
    _messages.addAll(res.map((e) => fromChatJson(e)).toList().reversed);
    return _messages;
  }

  // Message Reaction
  List<chat_types.Message> reactMessage(int conversationId, String messageId, String reaction) {
    final emojiString = emojiToStringMap[reaction];
    // modify local cache
    final targetIdx = _messages.indexWhere((element) => element.id == messageId);
    _messages[targetIdx].metadata?[emojiString!] += 1;

    final targetMessage = _messages[targetIdx];
    String identifier;
    if (targetMessage is chat_types.ImageMessage) {
      identifier = targetMessage.uri+targetMessage.author.firstName!;
    } else {
      identifier = (targetMessage as chat_types.TextMessage).text+targetMessage.author.firstName!;
    }
    final body = {"reaction": emojiString, "operation": "add", "identifier": identifier};

    ApiProvider().reactMessage(conversationId, body);
    return _messages;
  }

  // Post Message
  // Use one-shot stream to track sending progress.
  Stream<List<chat_types.Message>> postTextMessage(int conversationId, chat_types.TextMessage message) async* {
    final messageId = message.id;
    _messages.insert(0, message);
    yield _messages;

    // I'm tend not to modify the original json, stay with the flow like I can't access backend.
    final body = {
      'conversationId': conversationId,
      'userId': int.parse(currentUser.id),
      'user': currentUser.firstName,
      "avatar": currentUser.imageUrl,
      "messageType": "text",
      "message": message.text,
      "reactions": message.metadata?['reactions'] ?? {"like": 0, "love": 0, "laugh": 0},
      "timestamp": DateTime.now().millisecondsSinceEpoch,
    };

    // post messages
    yield await ApiProvider()
        .postMessage(conversationId, body)
        .then((res) {
          final pos = _messages.indexWhere((e) => e.id == messageId); // Can't assume it stays exactly @ 0.
          _messages[pos] = message.copyWith(showStatus: true, status: chat_types.Status.delivered);
          return _messages;
        })
        .onError((error, stackTrace) {
          // Still send back message w/ error state
          final pos = _messages.indexWhere((e) => e.id == messageId); // Can't assume it stays exactly @ 0.
          _messages[pos] = message.copyWith(status: chat_types.Status.error);
          return _messages;
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
        return chat_types.SystemMessage(id: Uuid().v4(), text: json['message'], createdAt: json['timestamp']);
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

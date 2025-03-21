import 'package:flutter_test/flutter_test.dart';
import 'package:chat_demo/domain/chat/chat.bloc.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as chat_types;
import 'package:uuid/uuid.dart';

void main() {
  late ChatRepository chatRepository;

  setUp(() {
    chatRepository = ChatRepository();

    // 初始化一些訊息
    chatRepository.messages.addAll([
      chat_types.TextMessage(
        id: '1',
        text: 'Hello!',
        author: chatRepository.currentUser,
        createdAt: DateTime.now().millisecondsSinceEpoch,
      ),
      chat_types.TextMessage(
        id: '2',
        text: 'How are you?',
        author: chat_types.User(id: '2', firstName: 'Alice'),
        createdAt: DateTime.now().millisecondsSinceEpoch,
      ),
    ]);
  });

  group('fetchMessages', () {
    test('should fetch messages from API', () async {
      final messages = await chatRepository.fetchMessages(1);

      expect(messages, isNotEmpty);
    });

    test('should update messages in repository', () async {
      final initialMessages = List.from(chatRepository.messages);

      await chatRepository.fetchMessages(1);

      expect(chatRepository.messages, isNotEmpty);
      expect(chatRepository.messages, isNot(equals(initialMessages)));
    });
  });

  group('postMessage', () {
    test('should add message to repository', () async {
      await chatRepository.fetchMessages(1);

      final newMessage = chat_types.TextMessage(
        id: Uuid().v4(),
        author: chatRepository.currentUser,
        text: "Hello, World!",
        showStatus: true,
        status: chat_types.Status.sending,
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );

      // postMessage is Stream btw
      await chatRepository.postMessage(1, newMessage);
    });

    group('reactMessage', () {
      test('should not modify messages if reaction is invalid', () {
        final initialMessages = List.from(chatRepository.messages);

        chatRepository.reactMessage(1, 'some-message-id', 'invalid-reaction');

        expect(chatRepository.messages, equals(initialMessages));
      });

      test('should update metadata for valid reaction', () {
        final messageId = chatRepository.messages.first.id;

        chatRepository.reactMessage(1, messageId, '👍');

        final updatedMessage = chatRepository.messages.firstWhere(
          (msg) => msg.id == messageId,
        );
        expect(updatedMessage.metadata?['like'], equals(1));
      });

      test('should initialize metadata if it is empty', () {
        final messageId = chatRepository.messages.first.id;

        // 清空 metadata
        chatRepository.messages[0] = chatRepository.messages[0].copyWith(
          metadata: {},
        );

        chatRepository.reactMessage(1, messageId, '❤️');

        final updatedMessage = chatRepository.messages.firstWhere(
          (msg) => msg.id == messageId,
        );
        expect(updatedMessage.metadata?['love'], equals(1));
      });

      test('should not crash if message does not exist', () {
        expect(
          () => chatRepository.reactMessage(1, 'non-existent-id', '👍'),
          returnsNormally,
        );
      });
    });

    test(
      'generateRandomMessage should emit messages from other users',
      () async {
        // 確保 Stream 只會發出其他使用者的訊息
        final stream = chatRepository.generateRandomMessage();

        // 驗證 Stream 是否正確發出訊息
        await expectLater(
          stream,
          emitsInOrder([
            isA<chat_types.Message>().having(
              (msg) => msg.author.id,
              'author.id',
              isNot(chatRepository.currentUser.id),
            ),
            isA<chat_types.Message>().having(
              (msg) => msg.author.id,
              'author.id',
              isNot(chatRepository.currentUser.id),
            ),
          ]),
        );
      },
    );
  });
}

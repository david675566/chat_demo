part of 'conversation.bloc.dart';

class ConversationRepository {
  // final firebase_storage.FirebaseStorage _firebaseStorage;
  ConversationRepository();

  final List<ConversationModel> _conversations = [];

  Future<List<ConversationModel>> fetchConversations() async {
    final res = await ApiProvider().fetchConversations();
    _conversations.clear();
    _conversations.addAll(res.map((e) => ConversationModel.fromMap(e)).toList());
    return _conversations;
  }

  // craete new conversation
  Future<List<ConversationModel>> createConversation() async {
    final newConv = ConversationModel(
      id: _conversations.length + 2, // it counts from 1
      participants: [ChatRepository().currentUser],
      timestamp: DateTime.now(),
    );
    _conversations.add(newConv);

    final body = {
      'id': newConv.id,
      'participants': newConv.participants.map((e) => e.id).toList(),
      'timestamp': newConv.timestamp.millisecondsSinceEpoch,
    };
    final res = await ApiProvider().createConversation(body);
    return _conversations;
  }
}

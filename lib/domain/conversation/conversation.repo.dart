part of 'conversation.bloc.dart';

class ConversationRepository {
  // final firebase_storage.FirebaseStorage _firebaseStorage;
  const ConversationRepository();

  Future<List<ConversationModel>> fetchConversations() async {
    final res = await ApiProvider().fetchConversations();
    return res.map((e) => ConversationModel.fromMap(e)).toList();
  }
}

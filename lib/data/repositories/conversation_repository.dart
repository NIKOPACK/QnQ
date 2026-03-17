import 'package:isar/isar.dart';
import 'package:qnq/data/datasources/local/database_service.dart';
import 'package:qnq/data/models/conversation_model.dart';
import 'package:qnq/data/models/message_model.dart';

class ConversationRepository {
  Future<Isar> get _db => DatabaseService.instance;

  Future<List<Conversation>> getAll() async {
    final db = await _db;
    return db.conversations.where().sortByUpdatedAtDesc().findAll();
  }

  Future<List<Conversation>> getByAgentUid(String agentUid) async {
    final db = await _db;
    return db.conversations
        .filter()
        .agentUidEqualTo(agentUid)
        .isArchivedEqualTo(false)
        .sortByUpdatedAtDesc()
        .findAll();
  }

  Future<Conversation?> getByUid(String uid) async {
    final db = await _db;
    return db.conversations.filter().uidEqualTo(uid).findFirst();
  }

  Future<void> save(Conversation conversation) async {
    final db = await _db;
    conversation.updatedAt = DateTime.now();
    await db.writeTxn(() => db.conversations.put(conversation));
  }

  Future<void> delete(String uid) async {
    final db = await _db;
    final conversation = await db.conversations.filter().uidEqualTo(uid).findFirst();
    if (conversation != null) {
      // Delete all messages in this conversation
      await db.writeTxn(() async {
        await db.messages.filter().conversationUidEqualTo(uid).deleteAll();
        await db.conversations.delete(conversation.id);
      });
    }
  }

  Future<void> deleteAllByAgentUid(String agentUid) async {
    final db = await _db;
    final conversations = await db.conversations
        .filter()
        .agentUidEqualTo(agentUid)
        .findAll();
    await db.writeTxn(() async {
      for (final conv in conversations) {
        await db.messages.filter().conversationUidEqualTo(conv.uid).deleteAll();
      }
      await db.conversations.filter().agentUidEqualTo(agentUid).deleteAll();
    });
  }
}

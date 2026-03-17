import 'package:isar/isar.dart';
import 'package:qnq/data/datasources/local/database_service.dart';
import 'package:qnq/data/models/message_model.dart';

class MessageRepository {
  Future<Isar> get _db => DatabaseService.instance;

  Future<List<Message>> getByConversationUid(String conversationUid) async {
    final db = await _db;
    return db.messages
        .filter()
        .conversationUidEqualTo(conversationUid)
        .sortByCreatedAt()
        .findAll();
  }

  Future<Message?> getByUid(String uid) async {
    final db = await _db;
    return db.messages.filter().uidEqualTo(uid).findFirst();
  }

  Future<void> save(Message message) async {
    final db = await _db;
    await db.writeTxn(() => db.messages.put(message));
  }

  Future<void> saveAll(List<Message> messages) async {
    final db = await _db;
    await db.writeTxn(() => db.messages.putAll(messages));
  }

  Future<void> delete(String uid) async {
    final db = await _db;
    final message = await db.messages.filter().uidEqualTo(uid).findFirst();
    if (message != null) {
      await db.writeTxn(() => db.messages.delete(message.id));
    }
  }

  Future<void> deleteByConversationUid(String conversationUid) async {
    final db = await _db;
    await db.writeTxn(
      () => db.messages.filter().conversationUidEqualTo(conversationUid).deleteAll(),
    );
  }

  Stream<void> watchByConversation(String conversationUid) async* {
    final db = await _db;
    yield* db.messages.watchLazy();
  }
}

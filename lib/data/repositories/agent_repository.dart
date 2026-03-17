import 'package:isar/isar.dart';
import 'package:qnq/data/datasources/local/database_service.dart';
import 'package:qnq/data/models/agent_model.dart';

class AgentRepository {
  Future<Isar> get _db => DatabaseService.instance;

  Future<List<Agent>> getAll() async {
    final db = await _db;
    return db.agents.where().sortByUpdatedAtDesc().findAll();
  }

  Future<Agent?> getByUid(String uid) async {
    final db = await _db;
    return db.agents.filter().uidEqualTo(uid).findFirst();
  }

  Future<List<Agent>> getByCategory(String category) async {
    final db = await _db;
    return db.agents.filter().categoryEqualTo(category).sortByUpdatedAtDesc().findAll();
  }

  Future<List<Agent>> getBuiltin() async {
    final db = await _db;
    return db.agents.filter().isBuiltinEqualTo(true).findAll();
  }

  Future<List<Agent>> getPinned() async {
    final db = await _db;
    return db.agents.filter().isPinnedEqualTo(true).sortByUpdatedAtDesc().findAll();
  }

  Future<List<Agent>> search(String query) async {
    final db = await _db;
    return db.agents
        .filter()
        .nameContains(query, caseSensitive: false)
        .or()
        .descriptionContains(query, caseSensitive: false)
        .findAll();
  }

  Future<void> save(Agent agent) async {
    final db = await _db;
    agent.updatedAt = DateTime.now();
    await db.writeTxn(() => db.agents.put(agent));
  }

  Future<void> incrementUsageCount(String uid) async {
    final db = await _db;
    final agent = await db.agents.filter().uidEqualTo(uid).findFirst();
    if (agent != null) {
      agent.usageCount++;
      agent.updatedAt = DateTime.now();
      await db.writeTxn(() => db.agents.put(agent));
    }
  }

  Future<void> delete(String uid) async {
    final db = await _db;
    final agent = await db.agents.filter().uidEqualTo(uid).findFirst();
    if (agent != null) {
      await db.writeTxn(() => db.agents.delete(agent.id));
    }
  }

  Stream<void> watchAll() async* {
    final db = await _db;
    yield* db.agents.watchLazy();
  }
}

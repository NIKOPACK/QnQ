import 'package:isar/isar.dart';
import 'package:qnq/data/datasources/local/database_service.dart';
import 'package:qnq/data/models/provider_config_model.dart';

class ProviderConfigRepository {
  Future<Isar> get _db => DatabaseService.instance;

  Future<List<ProviderConfig>> getAll() async {
    final db = await _db;
    return db.providerConfigs.where().findAll();
  }

  Future<ProviderConfig?> getByUid(String uid) async {
    final db = await _db;
    return db.providerConfigs.filter().uidEqualTo(uid).findFirst();
  }

  Future<List<ProviderConfig>> getEnabled() async {
    final db = await _db;
    return db.providerConfigs.filter().isEnabledEqualTo(true).findAll();
  }

  Future<void> save(ProviderConfig config) async {
    final db = await _db;
    config.updatedAt = DateTime.now();
    await db.writeTxn(() => db.providerConfigs.put(config));
  }

  Future<void> delete(String uid) async {
    final db = await _db;
    final config = await db.providerConfigs.filter().uidEqualTo(uid).findFirst();
    if (config != null) {
      await db.writeTxn(() => db.providerConfigs.delete(config.id));
    }
  }

  Stream<void> watchAll() async* {
    final db = await _db;
    yield* db.providerConfigs.watchLazy();
  }
}

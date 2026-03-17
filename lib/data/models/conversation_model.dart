import 'package:isar/isar.dart';

part 'conversation_model.g.dart';

@collection
class Conversation {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String uid;

  /// UID of the agent this conversation belongs to
  @Index()
  late String agentUid;

  String title = '';

  DateTime createdAt = DateTime.now();

  DateTime updatedAt = DateTime.now();

  bool isArchived = false;
}

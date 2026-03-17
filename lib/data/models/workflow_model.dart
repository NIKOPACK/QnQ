import 'package:isar/isar.dart';

part 'workflow_model.g.dart';

@collection
class Workflow {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String uid;

  late String name;

  String description = '';

  /// JSON-serialized list of nodes
  late String nodesJson;

  /// JSON-serialized list of edges (connections)
  late String edgesJson;

  DateTime createdAt = DateTime.now();

  DateTime updatedAt = DateTime.now();
}

import 'package:isar/isar.dart';

part 'mcp_server_model.g.dart';

@collection
class McpServer {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String uid;

  late String name;

  String description = '';

  @Enumerated(EnumType.name)
  late McpTransportEnum transport;

  /// For SSE: the server URL; For stdio: the command to run
  late String endpoint;

  /// For stdio: command arguments
  List<String> args = [];

  /// For stdio: environment variables as JSON
  String envJson = '{}';

  bool isEnabled = true;

  /// JSON-serialized list of discovered tools
  String discoveredToolsJson = '[]';

  DateTime createdAt = DateTime.now();

  DateTime updatedAt = DateTime.now();
}

enum McpTransportEnum {
  stdio,
  sse,
}

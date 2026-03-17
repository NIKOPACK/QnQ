import 'package:isar/isar.dart';

part 'agent_model.g.dart';

@collection
class Agent {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String uid;

  late String name;

  String description = '';

  String? avatarUrl;

  String? avatarEmoji;

  @Enumerated(EnumType.name)
  late AgentTypeEnum agentType;

  /// UID of the provider config
  String? providerUid;

  String? modelName;

  String systemPrompt = '';

  double temperature = 0.7;

  int maxTokens = 4096;

  double topP = 1.0;

  /// List of tool IDs this agent can use
  List<String> enabledToolIds = [];

  /// For workflow agents: the workflow UID
  String? workflowUid;

  bool isBuiltin = false;

  bool isPinned = false;

  String category = 'general';

  int usageCount = 0;

  DateTime createdAt = DateTime.now();

  DateTime updatedAt = DateTime.now();
}

enum AgentTypeEnum {
  chat,
  workflow,
}

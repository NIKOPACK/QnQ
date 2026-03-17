import 'package:isar/isar.dart';

part 'message_model.g.dart';

@collection
class Message {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String uid;

  @Index()
  late String conversationUid;

  @Enumerated(EnumType.name)
  late MessageRoleEnum role;

  late String content;

  /// For tool calls: serialized JSON of tool call requests
  String? toolCalls;

  /// For tool results: the tool call ID this is responding to
  String? toolCallId;

  /// For tool results: the tool name
  String? toolName;

  /// Metadata: token usage, model used, etc.
  String? metadata;

  bool isError = false;

  DateTime createdAt = DateTime.now();
}

enum MessageRoleEnum {
  system,
  user,
  assistant,
  tool,
}

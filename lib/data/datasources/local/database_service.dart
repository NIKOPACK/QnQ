import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qnq/data/models/agent_model.dart';
import 'package:qnq/data/models/conversation_model.dart';
import 'package:qnq/data/models/mcp_server_model.dart';
import 'package:qnq/data/models/message_model.dart';
import 'package:qnq/data/models/plugin_model.dart';
import 'package:qnq/data/models/provider_config_model.dart';
import 'package:qnq/data/models/workflow_model.dart';

class DatabaseService {
  static Isar? _instance;

  static Future<Isar> get instance async {
    if (_instance != null && _instance!.isOpen) return _instance!;
    _instance = await _init();
    return _instance!;
  }

  static Future<Isar> _init() async {
    final dir = await getApplicationDocumentsDirectory();
    return Isar.open(
      [
        ProviderConfigSchema,
        AgentSchema,
        ConversationSchema,
        MessageSchema,
        WorkflowSchema,
        PluginRecordSchema,
        McpServerSchema,
      ],
      directory: dir.path,
      name: 'qnq_db',
    );
  }

  static Future<void> close() async {
    await _instance?.close();
    _instance = null;
  }
}

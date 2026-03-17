import 'package:isar/isar.dart';

part 'plugin_model.g.dart';

@collection
class PluginRecord {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String pluginId;

  late String name;

  String description = '';

  String version = '1.0.0';

  String? author;

  /// Path to the plugin directory
  late String installPath;

  /// Entry script filename
  String entryFile = 'main.lua';

  /// JSON-serialized list of permissions
  String permissionsJson = '[]';

  /// JSON-serialized list of tool definitions
  String toolsJson = '[]';

  @Enumerated(EnumType.name)
  PluginStatusEnum status = PluginStatusEnum.installed;

  DateTime installedAt = DateTime.now();

  DateTime updatedAt = DateTime.now();
}

enum PluginStatusEnum {
  installed,
  enabled,
  disabled,
  error,
}

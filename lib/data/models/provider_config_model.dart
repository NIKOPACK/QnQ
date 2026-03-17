import 'package:isar/isar.dart';

part 'provider_config_model.g.dart';

@collection
class ProviderConfig {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String uid;

  late String name;

  @Enumerated(EnumType.name)
  late ProviderTypeEnum providerType;

  late String baseUrl;

  late String apiKey;

  String? organizationId;

  String? deploymentId; // For Azure

  List<String> availableModels = [];

  String? defaultModel;

  bool isEnabled = true;

  DateTime createdAt = DateTime.now();

  DateTime updatedAt = DateTime.now();
}

enum ProviderTypeEnum {
  openai,
  anthropic,
  gemini,
  azure,
  custom,
}

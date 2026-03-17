import 'package:qnq/data/models/provider_config_model.dart';
import 'package:qnq/data/repositories/provider_config_repository.dart';
import 'package:qnq/services/llm/anthropic_provider.dart';
import 'package:qnq/services/llm/gemini_provider.dart';
import 'package:qnq/services/llm/llm_provider.dart';
import 'package:qnq/services/llm/openai_provider.dart';

/// Central service that manages multiple LLM providers and routes requests.
class LLMService {
  final ProviderConfigRepository _configRepository;
  final Map<String, LLMProvider> _providers = {};

  LLMService(this._configRepository);

  /// Initialize providers from stored configurations.
  Future<void> initialize() async {
    final configs = await _configRepository.getEnabled();
    for (final config in configs) {
      _providers[config.uid] = _createProvider(config);
    }
  }

  /// Get a provider by its config UID.
  LLMProvider? getProvider(String configUid) => _providers[configUid];

  /// Get all active providers.
  Map<String, LLMProvider> get providers => Map.unmodifiable(_providers);

  /// Add or update a provider at runtime.
  void registerProvider(ProviderConfig config) {
    _providers[config.uid]?.dispose();
    _providers[config.uid] = _createProvider(config);
  }

  /// Remove a provider.
  void removeProvider(String configUid) {
    _providers[configUid]?.dispose();
    _providers.remove(configUid);
  }

  /// Test a provider's connection.
  Future<bool> testProvider(String configUid) async {
    final provider = _providers[configUid];
    if (provider == null) return false;
    return provider.testConnection();
  }

  /// List models for a specific provider.
  Future<List<String>> listModels(String configUid) async {
    final provider = _providers[configUid];
    if (provider == null) return [];
    return provider.listModels();
  }

  /// Dispose all providers.
  void dispose() {
    for (final provider in _providers.values) {
      provider.dispose();
    }
    _providers.clear();
  }

  LLMProvider _createProvider(ProviderConfig config) {
    switch (config.providerType) {
      case ProviderTypeEnum.openai:
      case ProviderTypeEnum.custom:
        return OpenAICompatibleProvider(
          name: config.name,
          baseUrl: config.baseUrl,
          apiKey: config.apiKey,
          organizationId: config.organizationId,
        );
      case ProviderTypeEnum.anthropic:
        return AnthropicProvider(
          name: config.name,
          baseUrl: config.baseUrl,
          apiKey: config.apiKey,
        );
      case ProviderTypeEnum.gemini:
        return GeminiProvider(
          name: config.name,
          baseUrl: config.baseUrl,
          apiKey: config.apiKey,
        );
      case ProviderTypeEnum.azure:
        // Azure uses OpenAI-compatible API with different endpoint format
        return OpenAICompatibleProvider(
          name: config.name,
          baseUrl: config.baseUrl,
          apiKey: config.apiKey,
        );
    }
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qnq/data/repositories/agent_repository.dart';
import 'package:qnq/data/repositories/conversation_repository.dart';
import 'package:qnq/data/repositories/message_repository.dart';
import 'package:qnq/data/repositories/provider_config_repository.dart';
import 'package:qnq/services/llm/llm_service.dart';

// ============================================================
// Repository Providers
// ============================================================

final providerConfigRepositoryProvider = Provider<ProviderConfigRepository>(
  (ref) => ProviderConfigRepository(),
);

final agentRepositoryProvider = Provider<AgentRepository>(
  (ref) => AgentRepository(),
);

final conversationRepositoryProvider = Provider<ConversationRepository>(
  (ref) => ConversationRepository(),
);

final messageRepositoryProvider = Provider<MessageRepository>(
  (ref) => MessageRepository(),
);

// ============================================================
// LLM Service Provider
// ============================================================

final llmServiceProvider = Provider<LLMService>((ref) {
  final configRepo = ref.watch(providerConfigRepositoryProvider);
  final service = LLMService(configRepo);
  ref.onDispose(() => service.dispose());
  return service;
});

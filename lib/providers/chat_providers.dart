import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qnq/data/models/conversation_model.dart';
import 'package:qnq/data/models/message_model.dart';
import 'package:qnq/providers/service_providers.dart';
import 'package:uuid/uuid.dart';

// ============================================================
// Conversation Providers
// ============================================================

final conversationsByAgentProvider =
    FutureProvider.family<List<Conversation>, String>((ref, agentUid) {
  return ref.read(conversationRepositoryProvider).getByAgentUid(agentUid);
});

// ============================================================
// Chat State
// ============================================================

class ChatState {
  final String agentUid;
  final String? conversationUid;
  final List<Message> messages;
  final bool isLoading;
  final String? error;
  final String streamingContent;

  const ChatState({
    required this.agentUid,
    this.conversationUid,
    this.messages = const [],
    this.isLoading = false,
    this.error,
    this.streamingContent = '',
  });

  ChatState copyWith({
    String? agentUid,
    String? conversationUid,
    List<Message>? messages,
    bool? isLoading,
    String? error,
    String? streamingContent,
  }) {
    return ChatState(
      agentUid: agentUid ?? this.agentUid,
      conversationUid: conversationUid ?? this.conversationUid,
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      streamingContent: streamingContent ?? this.streamingContent,
    );
  }
}

final chatStateProvider =
    StateNotifierProvider.family<ChatNotifier, ChatState, String>(
  (ref, agentUid) => ChatNotifier(ref, agentUid),
);

class ChatNotifier extends StateNotifier<ChatState> {
  final Ref _ref;
  static const _uuid = Uuid();

  ChatNotifier(this._ref, String agentUid) : super(ChatState(agentUid: agentUid));

  Future<void> loadConversation(String? conversationUid) async {
    if (conversationUid == null) {
      // Start a new conversation
      final newUid = _uuid.v4();
      final conversation = Conversation()
        ..uid = newUid
        ..agentUid = state.agentUid
        ..title = 'New Conversation';
      await _ref.read(conversationRepositoryProvider).save(conversation);
      state = state.copyWith(conversationUid: newUid, messages: []);
      return;
    }

    final messages = await _ref.read(messageRepositoryProvider).getByConversationUid(conversationUid);
    state = state.copyWith(conversationUid: conversationUid, messages: messages);
  }

  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty || state.isLoading) return;
    if (state.conversationUid == null) await loadConversation(null);

    // Add user message
    final userMessage = Message()
      ..uid = _uuid.v4()
      ..conversationUid = state.conversationUid!
      ..role = MessageRoleEnum.user
      ..content = content;

    await _ref.read(messageRepositoryProvider).save(userMessage);

    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isLoading: true,
      error: null,
      streamingContent: '',
    );

    try {
      // Get agent config
      final agent = await _ref.read(agentRepositoryProvider).getByUid(state.agentUid);
      if (agent == null) throw Exception('Agent not found');

      final providerUid = agent.providerUid;
      if (providerUid == null) throw Exception('No model provider configured');

      final provider = _ref.read(llmServiceProvider).getProvider(providerUid);
      if (provider == null) throw Exception('Provider not available');

      final modelName = agent.modelName;
      if (modelName == null) throw Exception('No model selected');

      // Build LLM messages
      final llmMessages = <Map<String, String>>[];
      if (agent.systemPrompt.isNotEmpty) {
        llmMessages.add({'role': 'system', 'content': agent.systemPrompt});
      }
      for (final msg in state.messages) {
        llmMessages.add({
          'role': msg.role.name,
          'content': msg.content,
        });
      }

      // Build typed LLM messages
      final typedMessages = llmMessages
          .map((m) => _ref.read(llmServiceProvider)._buildLLMMessage(m))
          .toList();

      // Stream response
      String fullContent = '';
      await for (final chunk in provider.streamChat(
        model: modelName,
        messages: typedMessages,
        temperature: agent.temperature,
        maxTokens: agent.maxTokens,
        topP: agent.topP,
      )) {
        if (chunk.contentDelta != null) {
          fullContent += chunk.contentDelta!;
          state = state.copyWith(streamingContent: fullContent);
        }
      }

      // Save assistant message
      final assistantMessage = Message()
        ..uid = _uuid.v4()
        ..conversationUid = state.conversationUid!
        ..role = MessageRoleEnum.assistant
        ..content = fullContent;

      await _ref.read(messageRepositoryProvider).save(assistantMessage);

      // Update conversation title if it's the first message
      if (state.messages.length == 1) {
        final conversation =
            await _ref.read(conversationRepositoryProvider).getByUid(state.conversationUid!);
        if (conversation != null) {
          conversation.title = content.length > 50 ? '${content.substring(0, 50)}...' : content;
          await _ref.read(conversationRepositoryProvider).save(conversation);
        }
      }

      // Increment agent usage count
      await _ref.read(agentRepositoryProvider).incrementUsageCount(state.agentUid);

      state = state.copyWith(
        messages: [...state.messages, assistantMessage],
        isLoading: false,
        streamingContent: '',
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        streamingContent: '',
      );
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Helper extension on LLMService (private)
extension _LLMServiceHelper on dynamic {
  // ignore: unused_element
  _buildLLMMessage(Map<String, String> m) {
    // We import inline to avoid circular deps
    return m;
  }
}

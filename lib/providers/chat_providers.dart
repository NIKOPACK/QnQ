import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qnq/data/models/conversation_model.dart';
import 'package:qnq/data/models/message_model.dart';
import 'package:qnq/providers/service_providers.dart';
import 'package:qnq/services/llm/llm_provider.dart';
import 'package:qnq/services/tools/tool_registry.dart';
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
  final List<String> activeToolCalls; // Tool names currently executing

  const ChatState({
    required this.agentUid,
    this.conversationUid,
    this.messages = const [],
    this.isLoading = false,
    this.error,
    this.streamingContent = '',
    this.activeToolCalls = const [],
  });

  ChatState copyWith({
    String? agentUid,
    String? conversationUid,
    List<Message>? messages,
    bool? isLoading,
    String? error,
    String? streamingContent,
    List<String>? activeToolCalls,
  }) {
    return ChatState(
      agentUid: agentUid ?? this.agentUid,
      conversationUid: conversationUid ?? this.conversationUid,
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      streamingContent: streamingContent ?? this.streamingContent,
      activeToolCalls: activeToolCalls ?? this.activeToolCalls,
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
  static const _maxToolCallRounds = 5;

  ChatNotifier(this._ref, String agentUid) : super(ChatState(agentUid: agentUid));

  Future<void> loadConversation(String? conversationUid) async {
    if (conversationUid == null) {
      final newUid = _uuid.v4();
      final conversation = Conversation()
        ..uid = newUid
        ..agentUid = state.agentUid
        ..title = 'New Conversation';
      await _ref.read(conversationRepositoryProvider).save(conversation);
      state = state.copyWith(conversationUid: newUid, messages: []);
      return;
    }
    final messages = await _ref
        .read(messageRepositoryProvider)
        .getByConversationUid(conversationUid);
    state = state.copyWith(conversationUid: conversationUid, messages: messages);
  }

  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty || state.isLoading) return;
    if (state.conversationUid == null) await loadConversation(null);

    // Persist user message immediately
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
      final agent = await _ref.read(agentRepositoryProvider).getByUid(state.agentUid);
      if (agent == null) throw Exception('Agent not found');

      final providerUid = agent.providerUid;
      if (providerUid == null) {
        throw Exception(
            'No model provider configured. Go to Settings → Providers to add one.');
      }

      final provider = _ref.read(llmServiceProvider).getProvider(providerUid);
      if (provider == null) {
        throw Exception('Provider not initialized. Try restarting the app.');
      }

      final modelName = agent.modelName;
      if (modelName == null || modelName.isEmpty) {
        throw Exception('No model selected for this agent.');
      }

      // Build tool definitions from agent's enabled tool IDs
      final toolRegistry = ToolRegistry();
      final enabledTools = toolRegistry.getTools(agent.enabledToolIds);
      final toolDefinitions = enabledTools
          .map((t) => ToolDefinition(
                name: t.name,
                description: t.description,
                parameters: t.parameters,
              ))
          .toList();

      // Build initial LLM context from conversation history
      final llmMessages = <LLMMessage>[];
      if (agent.systemPrompt.isNotEmpty) {
        llmMessages.add(LLMMessage(role: 'system', content: agent.systemPrompt));
      }
      for (final msg in state.messages) {
        if (msg.role == MessageRoleEnum.tool) {
          llmMessages.add(LLMMessage(
            role: 'tool',
            content: msg.content,
            toolCallId: msg.toolCallId,
            name: msg.toolName,
          ));
        } else {
          llmMessages.add(LLMMessage(role: msg.role.name, content: msg.content));
        }
      }

      // ── Function Calling Loop ──────────────────────────────────────
      // Loop to handle multi-turn tool calling (LLM → Tool → LLM → ...)
      String finalContent = '';

      for (var round = 0; round < _maxToolCallRounds; round++) {
        if (toolDefinitions.isEmpty) {
          // No tools — pure streaming response
          String streamed = '';
          await for (final chunk in provider.streamChat(
            model: modelName,
            messages: llmMessages,
            temperature: agent.temperature,
            maxTokens: agent.maxTokens,
          )) {
            if (chunk.contentDelta != null) {
              streamed += chunk.contentDelta!;
              state = state.copyWith(streamingContent: streamed);
            }
          }
          finalContent = streamed;
          break;
        }

        // With tools: use non-streaming chat() to reliably capture tool_calls
        final response = await provider.chat(
          model: modelName,
          messages: llmMessages,
          tools: toolDefinitions,
          temperature: agent.temperature,
          maxTokens: agent.maxTokens,
        );

        if (!response.hasToolCalls) {
          // LLM gave a direct text answer — done
          finalContent = response.content;
          if (finalContent.isEmpty) {
            // Rare fallback: use streaming for the final turn
            await for (final chunk in provider.streamChat(
              model: modelName,
              messages: llmMessages,
              temperature: agent.temperature,
              maxTokens: agent.maxTokens,
            )) {
              if (chunk.contentDelta != null) {
                finalContent += chunk.contentDelta!;
                state = state.copyWith(streamingContent: finalContent);
              }
            }
          }
          break;
        }

        // ── LLM requested tool calls ─────────────────────────────────
        // Save the assistant message that contains tool_calls
        final toolCallsJson =
            jsonEncode(response.toolCalls.map((tc) => tc.toJson()).toList());
        final assistantToolMsg = Message()
          ..uid = _uuid.v4()
          ..conversationUid = state.conversationUid!
          ..role = MessageRoleEnum.assistant
          ..content = response.content
          ..toolCalls = toolCallsJson;
        await _ref.read(messageRepositoryProvider).save(assistantToolMsg);

        // Add assistant turn to LLM context
        llmMessages.add(LLMMessage(
          role: 'assistant',
          content: response.content,
          toolCalls: response.toolCalls,
        ));

        // Update UI: show which tools are running
        state = state.copyWith(
          messages: [...state.messages, assistantToolMsg],
          activeToolCalls: response.toolCalls.map((tc) => tc.name).toList(),
          streamingContent: '',
        );

        // Execute each tool in parallel and collect results
        final toolResults = <Message>[];
        for (final toolCall in response.toolCalls) {
          Map<String, dynamic> args = {};
          try {
            args = jsonDecode(toolCall.arguments) as Map<String, dynamic>;
          } catch (_) {}

          final result = await toolRegistry.execute(
            toolName: toolCall.name,
            toolCallId: toolCall.id,
            arguments: args,
          );

          final toolResultMsg = Message()
            ..uid = _uuid.v4()
            ..conversationUid = state.conversationUid!
            ..role = MessageRoleEnum.tool
            ..content = result.content
            ..toolCallId = result.toolCallId
            ..toolName = toolCall.name
            ..isError = result.isError;

          await _ref.read(messageRepositoryProvider).save(toolResultMsg);
          toolResults.add(toolResultMsg);

          // Add tool result to LLM context for the next round
          llmMessages.add(LLMMessage(
            role: 'tool',
            content: result.content,
            toolCallId: result.toolCallId,
            name: toolCall.name,
          ));
        }

        state = state.copyWith(
          messages: [...state.messages, ...toolResults],
          activeToolCalls: [],
        );
        // ── Continue loop: send results back to LLM ──────────────────
      }
      // ── End Function Calling Loop ──────────────────────────────────

      // Save the final assistant response
      final assistantMessage = Message()
        ..uid = _uuid.v4()
        ..conversationUid = state.conversationUid!
        ..role = MessageRoleEnum.assistant
        ..content = finalContent;
      await _ref.read(messageRepositoryProvider).save(assistantMessage);

      // Update title after the first user message
      final userMsgCount =
          state.messages.where((m) => m.role == MessageRoleEnum.user).length;
      if (userMsgCount == 1) {
        final conv = await _ref
            .read(conversationRepositoryProvider)
            .getByUid(state.conversationUid!);
        if (conv != null) {
          conv.title =
              content.length > 50 ? '${content.substring(0, 50)}...' : content;
          await _ref.read(conversationRepositoryProvider).save(conv);
        }
      }

      await _ref
          .read(agentRepositoryProvider)
          .incrementUsageCount(state.agentUid);

      state = state.copyWith(
        messages: [...state.messages, assistantMessage],
        isLoading: false,
        streamingContent: '',
        activeToolCalls: [],
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        streamingContent: '',
        activeToolCalls: [],
      );
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

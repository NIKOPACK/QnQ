/// Represents a single message in a chat conversation for LLM API calls.
class LLMMessage {
  final String role; // system, user, assistant, tool
  final String content;
  final List<ToolCall>? toolCalls;
  final String? toolCallId;
  final String? name;

  const LLMMessage({
    required this.role,
    required this.content,
    this.toolCalls,
    this.toolCallId,
    this.name,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'role': role,
      'content': content,
    };
    if (toolCalls != null && toolCalls!.isNotEmpty) {
      map['tool_calls'] = toolCalls!.map((tc) => tc.toJson()).toList();
    }
    if (toolCallId != null) map['tool_call_id'] = toolCallId;
    if (name != null) map['name'] = name;
    return map;
  }

  factory LLMMessage.fromJson(Map<String, dynamic> json) {
    return LLMMessage(
      role: json['role'] as String,
      content: json['content'] as String? ?? '',
      toolCalls: (json['tool_calls'] as List?)
          ?.map((tc) => ToolCall.fromJson(tc as Map<String, dynamic>))
          .toList(),
      toolCallId: json['tool_call_id'] as String?,
      name: json['name'] as String?,
    );
  }
}

/// Represents a tool call made by the LLM.
class ToolCall {
  final String id;
  final String name;
  final String arguments; // JSON string

  const ToolCall({
    required this.id,
    required this.name,
    required this.arguments,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': 'function',
        'function': {
          'name': name,
          'arguments': arguments,
        },
      };

  factory ToolCall.fromJson(Map<String, dynamic> json) {
    final function_ = json['function'] as Map<String, dynamic>;
    return ToolCall(
      id: json['id'] as String,
      name: function_['name'] as String,
      arguments: function_['arguments'] as String,
    );
  }
}

/// Represents a tool definition for the LLM.
class ToolDefinition {
  final String name;
  final String description;
  final Map<String, dynamic> parameters; // JSON Schema

  const ToolDefinition({
    required this.name,
    required this.description,
    required this.parameters,
  });

  Map<String, dynamic> toJson() => {
        'type': 'function',
        'function': {
          'name': name,
          'description': description,
          'parameters': parameters,
        },
      };
}

/// Response from an LLM completion.
class LLMResponse {
  final String content;
  final List<ToolCall> toolCalls;
  final String? finishReason;
  final TokenUsage? usage;

  const LLMResponse({
    required this.content,
    this.toolCalls = const [],
    this.finishReason,
    this.usage,
  });

  bool get hasToolCalls => toolCalls.isNotEmpty;
}

/// Token usage statistics.
class TokenUsage {
  final int promptTokens;
  final int completionTokens;
  final int totalTokens;

  const TokenUsage({
    required this.promptTokens,
    required this.completionTokens,
    required this.totalTokens,
  });
}

/// A streaming chunk from the LLM.
class LLMStreamChunk {
  final String? contentDelta;
  final List<ToolCall>? toolCallDeltas;
  final String? finishReason;

  const LLMStreamChunk({
    this.contentDelta,
    this.toolCallDeltas,
    this.finishReason,
  });
}

/// Abstract interface for all LLM providers.
abstract class LLMProvider {
  String get name;
  String get providerType;

  /// List available models.
  Future<List<String>> listModels();

  /// Send a chat completion request.
  Future<LLMResponse> chat({
    required String model,
    required List<LLMMessage> messages,
    List<ToolDefinition>? tools,
    double? temperature,
    int? maxTokens,
    double? topP,
  });

  /// Send a streaming chat completion request.
  Stream<LLMStreamChunk> streamChat({
    required String model,
    required List<LLMMessage> messages,
    List<ToolDefinition>? tools,
    double? temperature,
    int? maxTokens,
    double? topP,
  });

  /// Test if the provider configuration is valid.
  Future<bool> testConnection();

  /// Dispose resources.
  void dispose() {}
}

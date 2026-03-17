import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:qnq/services/llm/llm_provider.dart';

/// OpenAI-compatible provider. Covers OpenAI, DeepSeek, Qwen, GLM, MiniMax,
/// and any other provider that implements the OpenAI Chat Completion API.
class OpenAICompatibleProvider extends LLMProvider {
  final String _name;
  final String _baseUrl;
  final String _apiKey;
  final String? _organizationId;
  final Dio _dio;

  OpenAICompatibleProvider({
    required String name,
    required String baseUrl,
    required String apiKey,
    String? organizationId,
  })  : _name = name,
        _baseUrl = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl,
        _apiKey = apiKey,
        _organizationId = organizationId,
        _dio = Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 120),
        ));

  @override
  String get name => _name;

  @override
  String get providerType => 'openai';

  Map<String, String> get _headers {
    final headers = <String, String>{
      'Authorization': 'Bearer $_apiKey',
      'Content-Type': 'application/json',
    };
    if (_organizationId != null && _organizationId!.isNotEmpty) {
      headers['OpenAI-Organization'] = _organizationId!;
    }
    return headers;
  }

  @override
  Future<List<String>> listModels() async {
    try {
      final response = await _dio.get(
        '$_baseUrl/models',
        options: Options(headers: _headers),
      );
      final data = response.data as Map<String, dynamic>;
      final models = (data['data'] as List)
          .map((m) => m['id'] as String)
          .where((id) => id.contains('gpt') || id.contains('o1') || id.contains('o3') || !id.contains('embedding'))
          .toList()
        ..sort();
      return models;
    } catch (e) {
      return [];
    }
  }

  @override
  Future<LLMResponse> chat({
    required String model,
    required List<LLMMessage> messages,
    List<ToolDefinition>? tools,
    double? temperature,
    int? maxTokens,
    double? topP,
  }) async {
    final body = _buildRequestBody(
      model: model,
      messages: messages,
      tools: tools,
      temperature: temperature,
      maxTokens: maxTokens,
      topP: topP,
      stream: false,
    );

    final response = await _dio.post(
      '$_baseUrl/chat/completions',
      data: body,
      options: Options(headers: _headers),
    );

    return _parseResponse(response.data as Map<String, dynamic>);
  }

  @override
  Stream<LLMStreamChunk> streamChat({
    required String model,
    required List<LLMMessage> messages,
    List<ToolDefinition>? tools,
    double? temperature,
    int? maxTokens,
    double? topP,
  }) async* {
    final body = _buildRequestBody(
      model: model,
      messages: messages,
      tools: tools,
      temperature: temperature,
      maxTokens: maxTokens,
      topP: topP,
      stream: true,
    );

    final response = await _dio.post(
      '$_baseUrl/chat/completions',
      data: body,
      options: Options(
        headers: _headers,
        responseType: ResponseType.stream,
      ),
    );

    final stream = response.data.stream as Stream<List<int>>;
    String buffer = '';

    await for (final chunk in stream) {
      buffer += utf8.decode(chunk);
      final lines = buffer.split('\n');
      buffer = lines.last;

      for (final line in lines.take(lines.length - 1)) {
        final trimmed = line.trim();
        if (trimmed.isEmpty || !trimmed.startsWith('data: ')) continue;

        final data = trimmed.substring(6);
        if (data == '[DONE]') return;

        try {
          final json = jsonDecode(data) as Map<String, dynamic>;
          final chunk = _parseStreamChunk(json);
          if (chunk != null) yield chunk;
        } catch (_) {
          // Skip malformed chunks
        }
      }
    }
  }

  @override
  Future<bool> testConnection() async {
    try {
      final response = await _dio.get(
        '$_baseUrl/models',
        options: Options(
          headers: _headers,
          receiveTimeout: const Duration(seconds: 10),
        ),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  @override
  void dispose() {
    _dio.close();
  }

  Map<String, dynamic> _buildRequestBody({
    required String model,
    required List<LLMMessage> messages,
    List<ToolDefinition>? tools,
    double? temperature,
    int? maxTokens,
    double? topP,
    required bool stream,
  }) {
    final body = <String, dynamic>{
      'model': model,
      'messages': messages.map((m) => m.toJson()).toList(),
      'stream': stream,
    };
    if (temperature != null) body['temperature'] = temperature;
    if (maxTokens != null) body['max_tokens'] = maxTokens;
    if (topP != null) body['top_p'] = topP;
    if (tools != null && tools.isNotEmpty) {
      body['tools'] = tools.map((t) => t.toJson()).toList();
    }
    return body;
  }

  LLMResponse _parseResponse(Map<String, dynamic> json) {
    final choice = (json['choices'] as List).first as Map<String, dynamic>;
    final message = choice['message'] as Map<String, dynamic>;

    final toolCalls = (message['tool_calls'] as List?)
            ?.map((tc) => ToolCall.fromJson(tc as Map<String, dynamic>))
            .toList() ??
        [];

    TokenUsage? usage;
    if (json['usage'] != null) {
      final u = json['usage'] as Map<String, dynamic>;
      usage = TokenUsage(
        promptTokens: u['prompt_tokens'] as int? ?? 0,
        completionTokens: u['completion_tokens'] as int? ?? 0,
        totalTokens: u['total_tokens'] as int? ?? 0,
      );
    }

    return LLMResponse(
      content: message['content'] as String? ?? '',
      toolCalls: toolCalls,
      finishReason: choice['finish_reason'] as String?,
      usage: usage,
    );
  }

  LLMStreamChunk? _parseStreamChunk(Map<String, dynamic> json) {
    final choices = json['choices'] as List?;
    if (choices == null || choices.isEmpty) return null;

    final choice = choices.first as Map<String, dynamic>;
    final delta = choice['delta'] as Map<String, dynamic>?;
    if (delta == null) return null;

    final toolCallDeltas = (delta['tool_calls'] as List?)
        ?.map((tc) => ToolCall.fromJson(tc as Map<String, dynamic>))
        .toList();

    return LLMStreamChunk(
      contentDelta: delta['content'] as String?,
      toolCallDeltas: toolCallDeltas,
      finishReason: choice['finish_reason'] as String?,
    );
  }
}

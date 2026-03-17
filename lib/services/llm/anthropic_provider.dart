import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:qnq/services/llm/llm_provider.dart';

/// Anthropic Claude provider using the Messages API.
class AnthropicProvider extends LLMProvider {
  final String _name;
  final String _baseUrl;
  final String _apiKey;
  final Dio _dio;

  AnthropicProvider({
    required String name,
    required String baseUrl,
    required String apiKey,
  })  : _name = name,
        _baseUrl = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl,
        _apiKey = apiKey,
        _dio = Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 120),
        ));

  @override
  String get name => _name;

  @override
  String get providerType => 'anthropic';

  Map<String, String> get _headers => {
        'x-api-key': _apiKey,
        'Content-Type': 'application/json',
        'anthropic-version': '2023-06-01',
      };

  @override
  Future<List<String>> listModels() async {
    // Anthropic doesn't have a models endpoint; return known models
    return [
      'claude-sonnet-4-20250514',
      'claude-3-5-haiku-20241022',
      'claude-3-5-sonnet-20241022',
      'claude-3-opus-20240229',
    ];
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
      maxTokens: maxTokens ?? 4096,
      topP: topP,
      stream: false,
    );

    final response = await _dio.post(
      '$_baseUrl/v1/messages',
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
      maxTokens: maxTokens ?? 4096,
      topP: topP,
      stream: true,
    );

    final response = await _dio.post(
      '$_baseUrl/v1/messages',
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
        try {
          final json = jsonDecode(data) as Map<String, dynamic>;
          final type = json['type'] as String?;

          if (type == 'content_block_delta') {
            final delta = json['delta'] as Map<String, dynamic>;
            if (delta['type'] == 'text_delta') {
              yield LLMStreamChunk(contentDelta: delta['text'] as String?);
            } else if (delta['type'] == 'input_json_delta') {
              // Tool call argument streaming
              yield LLMStreamChunk(contentDelta: null);
            }
          } else if (type == 'content_block_start') {
            final contentBlock = json['content_block'] as Map<String, dynamic>;
            if (contentBlock['type'] == 'tool_use') {
              yield LLMStreamChunk(
                toolCallDeltas: [
                  ToolCall(
                    id: contentBlock['id'] as String,
                    name: contentBlock['name'] as String,
                    arguments: '',
                  ),
                ],
              );
            }
          } else if (type == 'message_stop') {
            yield const LLMStreamChunk(finishReason: 'stop');
          }
        } catch (_) {}
      }
    }
  }

  @override
  Future<bool> testConnection() async {
    try {
      final response = await _dio.post(
        '$_baseUrl/v1/messages',
        data: {
          'model': 'claude-3-5-haiku-20241022',
          'max_tokens': 1,
          'messages': [
            {'role': 'user', 'content': 'hi'}
          ],
        },
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
    required int maxTokens,
    double? topP,
    required bool stream,
  }) {
    // Separate system message
    String? systemPrompt;
    final apiMessages = <Map<String, dynamic>>[];

    for (final msg in messages) {
      if (msg.role == 'system') {
        systemPrompt = msg.content;
      } else {
        apiMessages.add({
          'role': msg.role,
          'content': msg.content,
        });
      }
    }

    final body = <String, dynamic>{
      'model': model,
      'messages': apiMessages,
      'max_tokens': maxTokens,
      'stream': stream,
    };

    if (systemPrompt != null) body['system'] = systemPrompt;
    if (temperature != null) body['temperature'] = temperature;
    if (topP != null) body['top_p'] = topP;

    if (tools != null && tools.isNotEmpty) {
      body['tools'] = tools
          .map((t) => {
                'name': t.name,
                'description': t.description,
                'input_schema': t.parameters,
              })
          .toList();
    }

    return body;
  }

  LLMResponse _parseResponse(Map<String, dynamic> json) {
    final content = json['content'] as List;
    final textParts = <String>[];
    final toolCalls = <ToolCall>[];

    for (final block in content) {
      final blockMap = block as Map<String, dynamic>;
      if (blockMap['type'] == 'text') {
        textParts.add(blockMap['text'] as String);
      } else if (blockMap['type'] == 'tool_use') {
        toolCalls.add(ToolCall(
          id: blockMap['id'] as String,
          name: blockMap['name'] as String,
          arguments: jsonEncode(blockMap['input']),
        ));
      }
    }

    TokenUsage? usage;
    if (json['usage'] != null) {
      final u = json['usage'] as Map<String, dynamic>;
      usage = TokenUsage(
        promptTokens: u['input_tokens'] as int? ?? 0,
        completionTokens: u['output_tokens'] as int? ?? 0,
        totalTokens: (u['input_tokens'] as int? ?? 0) + (u['output_tokens'] as int? ?? 0),
      );
    }

    return LLMResponse(
      content: textParts.join(),
      toolCalls: toolCalls,
      finishReason: json['stop_reason'] as String?,
      usage: usage,
    );
  }
}

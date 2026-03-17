import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:qnq/services/llm/llm_provider.dart';

/// Google Gemini provider using the REST API.
class GeminiProvider extends LLMProvider {
  final String _name;
  final String _baseUrl;
  final String _apiKey;
  final Dio _dio;

  GeminiProvider({
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
  String get providerType => 'gemini';

  @override
  Future<List<String>> listModels() async {
    try {
      final response = await _dio.get(
        '$_baseUrl/v1beta/models?key=$_apiKey',
      );
      final data = response.data as Map<String, dynamic>;
      return (data['models'] as List)
          .map((m) => (m['name'] as String).replaceFirst('models/', ''))
          .where((name) => name.contains('gemini'))
          .toList()
        ..sort();
    } catch (_) {
      return [
        'gemini-2.0-flash',
        'gemini-2.0-pro',
        'gemini-1.5-pro',
        'gemini-1.5-flash',
      ];
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
      messages: messages,
      tools: tools,
      temperature: temperature,
      maxTokens: maxTokens,
      topP: topP,
    );

    final response = await _dio.post(
      '$_baseUrl/v1beta/models/$model:generateContent?key=$_apiKey',
      data: body,
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
      messages: messages,
      tools: tools,
      temperature: temperature,
      maxTokens: maxTokens,
      topP: topP,
    );

    final response = await _dio.post(
      '$_baseUrl/v1beta/models/$model:streamGenerateContent?alt=sse&key=$_apiKey',
      data: body,
      options: Options(responseType: ResponseType.stream),
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
          final candidates = json['candidates'] as List?;
          if (candidates == null || candidates.isEmpty) continue;

          final content = candidates.first['content'] as Map<String, dynamic>?;
          if (content == null) continue;

          final parts = content['parts'] as List?;
          if (parts == null) continue;

          for (final part in parts) {
            final partMap = part as Map<String, dynamic>;
            if (partMap.containsKey('text')) {
              yield LLMStreamChunk(contentDelta: partMap['text'] as String);
            } else if (partMap.containsKey('functionCall')) {
              final fc = partMap['functionCall'] as Map<String, dynamic>;
              yield LLMStreamChunk(
                toolCallDeltas: [
                  ToolCall(
                    id: 'fc_${DateTime.now().millisecondsSinceEpoch}',
                    name: fc['name'] as String,
                    arguments: jsonEncode(fc['args']),
                  ),
                ],
              );
            }
          }
        } catch (_) {}
      }
    }
  }

  @override
  Future<bool> testConnection() async {
    try {
      final response = await _dio.get(
        '$_baseUrl/v1beta/models?key=$_apiKey',
        options: Options(receiveTimeout: const Duration(seconds: 10)),
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
    required List<LLMMessage> messages,
    List<ToolDefinition>? tools,
    double? temperature,
    int? maxTokens,
    double? topP,
  }) {
    String? systemInstruction;
    final contents = <Map<String, dynamic>>[];

    for (final msg in messages) {
      if (msg.role == 'system') {
        systemInstruction = msg.content;
      } else {
        contents.add({
          'role': msg.role == 'assistant' ? 'model' : 'user',
          'parts': [
            {'text': msg.content}
          ],
        });
      }
    }

    final body = <String, dynamic>{
      'contents': contents,
    };

    if (systemInstruction != null) {
      body['systemInstruction'] = {
        'parts': [
          {'text': systemInstruction}
        ],
      };
    }

    final generationConfig = <String, dynamic>{};
    if (temperature != null) generationConfig['temperature'] = temperature;
    if (maxTokens != null) generationConfig['maxOutputTokens'] = maxTokens;
    if (topP != null) generationConfig['topP'] = topP;
    if (generationConfig.isNotEmpty) {
      body['generationConfig'] = generationConfig;
    }

    if (tools != null && tools.isNotEmpty) {
      body['tools'] = [
        {
          'functionDeclarations': tools
              .map((t) => {
                    'name': t.name,
                    'description': t.description,
                    'parameters': t.parameters,
                  })
              .toList(),
        },
      ];
    }

    return body;
  }

  LLMResponse _parseResponse(Map<String, dynamic> json) {
    final candidates = json['candidates'] as List;
    if (candidates.isEmpty) {
      return const LLMResponse(content: '');
    }

    final content = candidates.first['content'] as Map<String, dynamic>;
    final parts = content['parts'] as List;
    final textParts = <String>[];
    final toolCalls = <ToolCall>[];

    for (final part in parts) {
      final partMap = part as Map<String, dynamic>;
      if (partMap.containsKey('text')) {
        textParts.add(partMap['text'] as String);
      } else if (partMap.containsKey('functionCall')) {
        final fc = partMap['functionCall'] as Map<String, dynamic>;
        toolCalls.add(ToolCall(
          id: 'fc_${DateTime.now().millisecondsSinceEpoch}',
          name: fc['name'] as String,
          arguments: jsonEncode(fc['args']),
        ));
      }
    }

    TokenUsage? usage;
    if (json['usageMetadata'] != null) {
      final u = json['usageMetadata'] as Map<String, dynamic>;
      usage = TokenUsage(
        promptTokens: u['promptTokenCount'] as int? ?? 0,
        completionTokens: u['candidatesTokenCount'] as int? ?? 0,
        totalTokens: u['totalTokenCount'] as int? ?? 0,
      );
    }

    return LLMResponse(
      content: textParts.join(),
      toolCalls: toolCalls,
      finishReason: candidates.first['finishReason'] as String?,
      usage: usage,
    );
  }
}

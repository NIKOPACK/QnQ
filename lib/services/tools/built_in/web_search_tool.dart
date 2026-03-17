import 'package:dio/dio.dart';
import 'package:qnq/services/tools/agent_tool.dart';

/// Built-in tool: performs a web search using DuckDuckGo Instant Answer API.
/// Returns a summary/snippet without requiring an API key.
class WebSearchTool extends AgentTool {
  static const String toolId = 'builtin_web_search';

  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 15),
  ));

  @override
  String get id => toolId;

  @override
  String get name => 'web_search';

  @override
  String get description =>
      'Search the web for current information. Use this when the user asks about recent events, '
      'facts you might not know, or anything that requires up-to-date information.';

  @override
  Map<String, dynamic> get parameters => {
        'type': 'object',
        'properties': {
          'query': {
            'type': 'string',
            'description': 'The search query to look up on the web.',
          },
        },
        'required': ['query'],
      };

  @override
  String get category => 'network';

  @override
  String get iconName => 'search';

  @override
  bool get requiresNetwork => true;

  @override
  Future<String> execute(Map<String, dynamic> arguments) async {
    final query = arguments['query'] as String? ?? '';
    if (query.trim().isEmpty) return 'Error: query is required.';

    try {
      // DuckDuckGo Instant Answer API - no key required
      final response = await _dio.get(
        'https://api.duckduckgo.com/',
        queryParameters: {
          'q': query,
          'format': 'json',
          'no_html': '1',
          'skip_disambig': '1',
        },
      );

      final data = response.data as Map<String, dynamic>;
      final abstract_ = data['AbstractText'] as String? ?? '';
      final answer = data['Answer'] as String? ?? '';
      final relatedTopics = (data['RelatedTopics'] as List?)
          ?.take(3)
          .map((t) {
            if (t is Map && t['Text'] != null) return '- ${t['Text']}';
            return null;
          })
          .whereType<String>()
          .join('\n') ??
          '';

      if (abstract_.isNotEmpty) {
        return 'Search result for "$query":\n\n$abstract_'
            '${relatedTopics.isNotEmpty ? '\n\nRelated:\n$relatedTopics' : ''}';
      } else if (answer.isNotEmpty) {
        return 'Answer: $answer';
      } else if (relatedTopics.isNotEmpty) {
        return 'Related results for "$query":\n$relatedTopics';
      } else {
        return 'No results found for "$query". Try rephrasing your query.';
      }
    } catch (e) {
      return 'Search failed: ${e.toString()}. Please try again.';
    }
  }
}

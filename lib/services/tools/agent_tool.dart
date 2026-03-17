/// Abstract interface for all agent tools — built-in, MCP-bridged, or plugin-provided.
///
/// Each tool must:
/// - Declare its JSON Schema via [parameters] (used to build the LLM `tools` payload)
/// - Implement [execute] to perform the actual work and return a result string
abstract class AgentTool {
  /// Unique identifier used in the agent's enabled tool list.
  String get id;

  /// Display name shown in the UI.
  String get name;

  /// Short description sent to the LLM.
  String get description;

  /// JSON Schema for the tool parameters (OpenAI tool format).
  /// Example:
  /// ```json
  /// {
  ///   "type": "object",
  ///   "properties": {
  ///     "query": {"type": "string", "description": "The search query"}
  ///   },
  ///   "required": ["query"]
  /// }
  /// ```
  Map<String, dynamic> get parameters;

  /// Category for grouping in the UI: 'info', 'device', 'network', etc.
  String get category => 'general';

  /// Icon name for UI rendering (Material icon name).
  String get iconName => 'build';

  /// Execute the tool with the given [arguments] (JSON-decoded map).
  /// Must return a string result to feed back to the LLM.
  /// Throw an exception to signal a tool failure.
  Future<String> execute(Map<String, dynamic> arguments);

  /// Whether this tool requires network access.
  bool get requiresNetwork => false;

  /// List of permissions needed before [execute] can run.
  List<String> get requiredPermissions => const [];
}

/// Result of a tool execution, including the content and success status.
class ToolExecutionResult {
  final String toolId;
  final String toolCallId;
  final String content;
  final bool isError;

  const ToolExecutionResult({
    required this.toolId,
    required this.toolCallId,
    required this.content,
    this.isError = false,
  });
}

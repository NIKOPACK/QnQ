import 'package:qnq/services/tools/agent_tool.dart';
import 'package:qnq/services/tools/built_in/camera_tool.dart';
import 'package:qnq/services/tools/built_in/calendar_tool.dart';
import 'package:qnq/services/tools/built_in/datetime_tool.dart';
import 'package:qnq/services/tools/built_in/file_tool.dart';
import 'package:qnq/services/tools/built_in/location_tool.dart';
import 'package:qnq/services/tools/built_in/sensors_tool.dart';
import 'package:qnq/services/tools/built_in/voice_tool.dart';
import 'package:qnq/services/tools/built_in/web_search_tool.dart';

/// Central registry for all available AgentTools.
/// Manages built-in tools and any dynamically registered tools (MCP, plugins).
class ToolRegistry {
  static final ToolRegistry _instance = ToolRegistry._internal();
  factory ToolRegistry() => _instance;
  ToolRegistry._internal();

  final Map<String, AgentTool> _tools = {};

  /// Initialize with all built-in tools.
  void initialize() {
    _register(DateTimeTool());
    _register(WebSearchTool());
    _register(LocationTool());
    _register(FileTool());
    _register(CameraTool());
    _register(VoiceTool());
    _register(CalendarTool());
    _register(SensorsTool());
  }

  void _register(AgentTool tool) {
    _tools[tool.id] = tool;
  }

  /// Register a tool dynamically (MCP bridge or plugin tool).
  void registerTool(AgentTool tool) => _register(tool);

  /// Unregister a tool by ID (e.g., when a plugin is uninstalled).
  void unregisterTool(String toolId) => _tools.remove(toolId);

  /// Get a tool by its ID.
  AgentTool? getTool(String toolId) => _tools[toolId];

  /// Get multiple tools by their IDs (for an agent's enabled tool list).
  List<AgentTool> getTools(List<String> toolIds) {
    return toolIds
        .map((id) => _tools[id])
        .whereType<AgentTool>()
        .toList();
  }

  /// Get all registered tools.
  List<AgentTool> get allTools => _tools.values.toList();

  /// Get tools by category.
  List<AgentTool> getByCategory(String category) =>
      _tools.values.where((t) => t.category == category).toList();

  /// Execute a tool by name (as reported by the LLM) and return the result.
  Future<ToolExecutionResult> execute({
    required String toolName,
    required String toolCallId,
    required Map<String, dynamic> arguments,
  }) async {
    // Find by tool.name (the function name that the LLM calls), not by tool.id
    final tool = _tools.values.firstWhere(
      (t) => t.name == toolName,
      orElse: () => throw Exception('Tool "$toolName" not found in registry'),
    );

    try {
      final result = await tool.execute(arguments);
      return ToolExecutionResult(
        toolId: tool.id,
        toolCallId: toolCallId,
        content: result,
      );
    } catch (e) {
      return ToolExecutionResult(
        toolId: tool.id,
        toolCallId: toolCallId,
        content: 'Error executing tool "$toolName": ${e.toString()}',
        isError: true,
      );
    }
  }
}

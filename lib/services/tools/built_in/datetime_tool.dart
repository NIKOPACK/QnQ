import 'package:qnq/services/tools/agent_tool.dart';

/// Built-in tool: returns the current date and time.
/// Great for validating the function calling loop works end-to-end.
class DateTimeTool extends AgentTool {
  static const String toolId = 'builtin_datetime';

  @override
  String get id => toolId;

  @override
  String get name => 'get_current_datetime';

  @override
  String get description =>
      'Get the current date and time. Use when the user asks about the current time, date, day of the week, or related time information.';

  @override
  Map<String, dynamic> get parameters => {
        'type': 'object',
        'properties': {
          'format': {
            'type': 'string',
            'description':
                'Optional format: "date" (date only), "time" (time only), "full" (default: both date and time)',
            'enum': ['date', 'time', 'full'],
          },
        },
        'required': [],
      };

  @override
  String get category => 'info';

  @override
  String get iconName => 'schedule';

  @override
  Future<String> execute(Map<String, dynamic> arguments) async {
    final format = arguments['format'] as String? ?? 'full';
    final now = DateTime.now();

    switch (format) {
      case 'date':
        return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      case 'time':
        return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
      default:
        return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} '
            '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
    }
  }
}

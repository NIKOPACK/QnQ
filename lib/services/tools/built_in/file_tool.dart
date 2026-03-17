import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:qnq/services/tools/agent_tool.dart';

/// Built-in tool: allow the user to select files and for the agent to read them.
class FileTool extends AgentTool {
  static const String toolId = 'builtin_file';

  @override
  String get id => toolId;

  @override
  String get name => 'file_management';

  @override
  String get description =>
      'Use this tool to ask the user to pick a file, or to read the content of a file. '
      'Supported actions: "pick" (opens file picker), "read" (reads content of a file path).';

  @override
  Map<String, dynamic> get parameters => {
        'type': 'object',
        'properties': {
          'action': {
            'type': 'string',
            'enum': ['pick', 'read'],
            'description': 'The action to perform: "pick" or "read".'
          },
          'path': {
            'type': 'string',
            'description': 'The absolute path of the file to read (required for "read" action).'
          }
        },
        'required': ['action']
      };

  @override
  String get category => 'info';

  @override
  String get iconName => 'folder_open';

  @override
  Future<String> execute(Map<String, dynamic> arguments) async {
    final action = arguments['action'] as String;

    if (action == 'pick') {
      try {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.any,
          allowMultiple: false,
        );

        if (result == null || result.files.isEmpty) {
          return 'No file selected by the user.';
        }

        final file = result.files.first;
        return 'File selected: ${file.name}\nPath: ${file.path}\nSize: ${file.size} bytes';
      } catch (e) {
        return 'Error picking file: $e';
      }
    } else if (action == 'read') {
      final path = arguments['path'] as String?;
      if (path == null || path.isEmpty) {
        return 'Error: Path is required for "read" action.';
      }

      try {
        final file = File(path);
        if (!await file.exists()) {
          return 'Error: File does not exist at path: $path';
        }

        // Check if it's a text file or common readable format
        // For simplicity in this demo tool, we read as string
        final content = await file.readAsString();
        // Limit content length to avoid context overflow
        if (content.length > 5000) {
          return 'File content (truncated to 5000 characters):\n\n${content.substring(0, 5000)}...';
        }
        return 'File content of $path:\n\n$content';
      } catch (e) {
        return 'Error reading file: $e. Note: If it is a binary file (like an image or PDF), direct text reading is not supported.';
      }
    }

    return 'Unknown action: $action';
  }
}

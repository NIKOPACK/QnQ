import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:qnq/core/services/permission_service.dart';
import 'package:qnq/services/tools/agent_tool.dart';
import 'package:record/record.dart';

/// Built-in tool: allows the agent to record audio from the user's microphone.
class VoiceTool extends AgentTool {
  static const String toolId = 'builtin_voice';
  final AudioRecorder _recorder = AudioRecorder();

  @override
  String get id => toolId;

  @override
  String get name => 'voice_recorder';

  @override
  String get description =>
      'Use this tool to record short voice messages or audio from the microphone. '
      'Supported actions: "start" (starts recording), "stop" (stops recording and returns the path).';

  @override
  Map<String, dynamic> get parameters => {
        'type': 'object',
        'properties': {
          'action': {
            'type': 'string',
            'enum': ['start', 'stop'],
            'description': 'The action to perform: "start" or "stop".'
          }
        },
        'required': ['action']
      };

  @override
  String get category => 'device';

  @override
  String get iconName => 'mic';

  @override
  List<String> get requiredPermissions => ['microphone'];

  @override
  Future<String> execute(Map<String, dynamic> arguments) async {
    final action = arguments['action'] as String;
    final permissionService = PermissionService();

    if (action == 'start') {
      if (!await permissionService.requestMicrophone()) {
        return 'Error: Microphone permission denied.';
      }

      try {
        if (await _recorder.isRecording()) {
          return 'Already recording. Use "stop" to finish the current recording first.';
        }

        final Directory tempDir = await getTemporaryDirectory();
        final String path = '${tempDir.path}/recording_${DateTime.now().millisecondsSinceEpoch}.m4a';
        
        const config = RecordConfig();
        await _recorder.start(config, path: path);
        return 'Recording started. Tell the user to speak now. Use "stop" action when finished.';
      } catch (e) {
        return 'Error starting recording: $e';
      }
    } else if (action == 'stop') {
      try {
        if (!await _recorder.isRecording()) {
          return 'Error: No active recording to stop.';
        }

        final path = await _recorder.stop();
        if (path == null) return 'Error: Recording failed to save.';
        
        final size = await File(path).length();
        return 'Recording stopped and saved.\nLocal path: $path\nSize: $size bytes';
      } catch (e) {
        return 'Error stopping recording: $e';
      }
    }

    return 'Unknown action: $action';
  }
}

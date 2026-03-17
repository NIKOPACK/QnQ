import 'package:image_picker/image_picker.dart';
import 'package:qnq/core/services/permission_service.dart';
import 'package:qnq/services/tools/agent_tool.dart';

/// Built-in tool: allows the agent to ask the user to take a photo or pick one from gallery.
class CameraTool extends AgentTool {
  static const String toolId = 'builtin_camera';
  final ImagePicker _picker = ImagePicker();

  @override
  String get id => toolId;

  @override
  String get name => 'camera_capture';

  @override
  String get description =>
      'Use this tool to ask the user to take a photo with their camera or pick an image from their gallery. '
      'Supported actions: "take_photo" (opens camera), "pick_image" (opens gallery).';

  @override
  Map<String, dynamic> get parameters => {
        'type': 'object',
        'properties': {
          'action': {
            'type': 'string',
            'enum': ['take_photo', 'pick_image'],
            'description': 'The action to perform: "take_photo" or "pick_image".'
          }
        },
        'required': ['action']
      };

  @override
  String get category => 'device';

  @override
  String get iconName => 'photo_camera';

  @override
  List<String> get requiredPermissions => ['camera', 'storage'];

  @override
  Future<String> execute(Map<String, dynamic> arguments) async {
    final action = arguments['action'] as String;
    final permissionService = PermissionService();

    if (action == 'take_photo') {
      if (!await permissionService.requestCamera()) {
        return 'Error: Camera permission denied.';
      }

      try {
        final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
        if (photo == null) return 'Action cancelled: No photo taken.';
        return 'Photo captured successfully.\nLocal path: ${photo.path}\nSize: ${await photo.length()} bytes';
      } catch (e) {
        return 'Error capturing photo: $e';
      }
    } else if (action == 'pick_image') {
      try {
        final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
        if (image == null) return 'Action cancelled: No image selected.';
        return 'Image selected from gallery.\nLocal path: ${image.path}\nSize: ${await image.length()} bytes';
      } catch (e) {
        return 'Error picking image: $e';
      }
    }

    return 'Unknown action: $action';
  }
}

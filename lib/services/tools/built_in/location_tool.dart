import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:qnq/core/services/permission_service.dart';
import 'package:qnq/services/tools/agent_tool.dart';

/// Built-in tool: gets the user's current GPS location and address.
class LocationTool extends AgentTool {
  static const String toolId = 'builtin_location';

  @override
  String get id => toolId;

  @override
  String get name => 'get_current_location';

  @override
  String get description =>
      'Get the user\'s current physical location, including latitude, longitude, and physical address. '
      'Use this when the user asks about local weather, places nearby, navigation, or their current whereabouts.';

  @override
  Map<String, dynamic> get parameters => {
        'type': 'object',
        'properties': {},
        'required': [],
      };

  @override
  String get category => 'device';

  @override
  String get iconName => 'location_on';

  @override
  bool get requiresNetwork => true; // Geocoding needs network

  @override
  List<String> get requiredPermissions => ['location'];

  @override
  Future<String> execute(Map<String, dynamic> arguments) async {
    // 1. Check permissions via our PermissionService
    final permissionService = PermissionService();
    bool hasPermission = await permissionService.hasLocation();
    
    if (!hasPermission) {
      hasPermission = await permissionService.requestLocation();
      if (!hasPermission) {
        return 'Error: Location permission denied by the user.';
      }
    }

    // 2. Check if location services are enabled globally
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return 'Error: Location services are disabled on the device.';
    }

    try {
      // 3. Get current position (high accuracy)
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );

      // 4. Reverse geocode to get human-readable address
      String addressStr = 'Address not found';
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          final List<String> addressParts = [];
          if (place.name != null && place.name!.isNotEmpty) addressParts.add(place.name!);
          if (place.street != null && place.street!.isNotEmpty && place.street != place.name) addressParts.add(place.street!);
          if (place.locality != null && place.locality!.isNotEmpty) addressParts.add(place.locality!);
          if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) addressParts.add(place.administrativeArea!);
          if (place.country != null && place.country!.isNotEmpty) addressParts.add(place.country!);
          if (place.postalCode != null && place.postalCode!.isNotEmpty) addressParts.add(place.postalCode!);
          
          if (addressParts.isNotEmpty) {
            addressStr = addressParts.join(', ');
          }
        }
      } catch (e) {
        addressStr = 'Reverse geocoding failed: ${e.toString()}';
      }

      return 'Location: $addressStr\n'
          'Coordinates: ${position.latitude}, ${position.longitude}\n'
          'Altitude: ${position.altitude}m';
    } catch (e) {
      return 'Failed to get location: ${e.toString()}';
    }
  }
}

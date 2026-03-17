import 'package:permission_handler/permission_handler.dart';

/// Unified permission service for the QnQ app.
/// Handles all runtime permission requests using [permission_handler].
class PermissionService {
  static final PermissionService _instance = PermissionService._internal();
  factory PermissionService() => _instance;
  PermissionService._internal();

  // ───────────────────────────────────────────────────────────────
  // Check
  // ───────────────────────────────────────────────────────────────

  Future<bool> isGranted(Permission permission) async {
    final status = await permission.status;
    return status.isGranted;
  }

  // ───────────────────────────────────────────────────────────────
  // Request
  // ───────────────────────────────────────────────────────────────

  /// Request a single permission. Returns [true] if granted.
  Future<bool> request(Permission permission) async {
    final status = await permission.request();
    return status.isGranted;
  }

  /// Request multiple permissions. Returns a map of results.
  Future<Map<Permission, bool>> requestAll(List<Permission> permissions) async {
    final statuses = await permissions.request();
    return statuses.map((perm, status) => MapEntry(perm, status.isGranted));
  }

  // ───────────────────────────────────────────────────────────────
  // Named Helpers
  // ───────────────────────────────────────────────────────────────

  Future<bool> requestCamera() => request(Permission.camera);
  Future<bool> requestMicrophone() => request(Permission.microphone);
  Future<bool> requestStorage() => request(Permission.storage);
  Future<bool> requestLocation() => request(Permission.locationWhenInUse);
  Future<bool> requestNotifications() => request(Permission.notification);
  Future<bool> requestCalendar() => request(Permission.calendarFullAccess);
  Future<bool> requestContacts() => request(Permission.contacts);
  Future<bool> requestSensors() => request(Permission.sensors);

  Future<bool> hasCamera() => isGranted(Permission.camera);
  Future<bool> hasLocation() => isGranted(Permission.locationWhenInUse);
  Future<bool> hasStorage() => isGranted(Permission.storage);
  Future<bool> hasMicrophone() => isGranted(Permission.microphone);

  // ───────────────────────────────────────────────────────────────
  // Settings
  // ───────────────────────────────────────────────────────────────

  /// Open the app settings page (e.g., if permission was permanently denied).
  Future<bool> openSettings() => openAppSettings();
}

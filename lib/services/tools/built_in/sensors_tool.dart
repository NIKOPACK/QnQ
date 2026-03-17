import 'dart:async';
import 'package:qnq/services/tools/agent_tool.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// Built-in tool: allow the agent to read current motion/orientation data from the device sensors.
class SensorsTool extends AgentTool {
  static const String toolId = 'builtin_sensors';

  @override
  String get id => toolId;

  @override
  String get name => 'motion_sensors';

  @override
  String get description =>
      'Read current motion data from the device sensors (Accelerometer and Gyroscope). '
      'Useful for determining orientation, movement, or if the device is being shaken.';

  @override
  Map<String, dynamic> get parameters => {
        'type': 'object',
        'properties': {
          'durationSeconds': {
            'type': 'integer',
            'description': 'How long to sample the sensors (1-5 seconds). Default is 1.',
            'minimum': 1,
            'maximum': 5
          }
        }
      };

  @override
  String get category => 'device';

  @override
  String get iconName => 'sensors';

  @override
  Future<String> execute(Map<String, dynamic> arguments) async {
    final int duration = arguments['durationSeconds'] ?? 1;
    
    try {
      // Sample sensors
      UserAccelerometerEvent? accel;
      GyroscopeEvent? gyro;
      
      final sub1 = userAccelerometerEventStream().listen((event) => accel = event);
      final sub2 = gyroscopeEventStream().listen((event) => gyro = event);
      
      await Future.delayed(Duration(seconds: duration));
      
      await sub1.cancel();
      await sub2.cancel();
      
      if (accel == null || gyro == null) {
        return 'Error: Sensors not responding or not available on this device.';
      }
      
      return 'Sensor Data (Sampled for $duration s):\n'
          'Accelerometer: x=${accel!.x.toStringAsFixed(2)}, y=${accel!.y.toStringAsFixed(2)}, z=${accel!.z.toStringAsFixed(2)}\n'
          'Gyroscope: x=${gyro!.x.toStringAsFixed(2)}, y=${gyro!.y.toStringAsFixed(2)}, z=${gyro!.z.toStringAsFixed(2)}\n'
          'Status: Device is currently ${accel!.x.abs() + accel!.y.abs() + accel!.z.abs() < 0.2 ? "static" : "in motion"}.';
    } catch (e) {
      return 'Error reading sensors: $e';
    }
  }
}

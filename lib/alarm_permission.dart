import 'package:flutter/services.dart';

class AlarmPermission {
  static const platform = MethodChannel('com.example/alarm_permission');

  // Check if the alarm permission is granted
  static Future<bool> checkAlarmPermission() async {
    try {
      final bool result = await platform.invokeMethod('checkAlarmPermission');
      return result;
    } on PlatformException catch (e) {
      print("Failed to check alarm permission: ${e.message}");
      return false;
    }
  }

  // Request alarm permission
  static Future<void> requestAlarmPermission() async {
    try {
      await platform.invokeMethod('requestAlarmPermission');
    } on PlatformException catch (e) {
      print("Failed to request alarm permission: ${e.message}");
    }
  }
}

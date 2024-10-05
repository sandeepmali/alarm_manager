import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AlarmServiceManager {
  static const platform = MethodChannel('com.example.alarm/alarm_service');

  // Start the foreground service
  static Future<void> startAlarmService(int selectedTime) async {
    try {
      await platform.invokeMethod('scheduleAlarm', {
        // 'hour': selectedTime!.hourOfPeriod,
        // 'minute': selectedTime!.minute,
        'selectedTime': selectedTime,
        'message': 'ringing',
      });
    } on PlatformException catch (e) {
      print("Failed to start service: '${e.message}'.");
    }
  }

  // Stop the foreground service
  static Future<void> stopAlarmService() async {
    try {
      await platform.invokeMethod('stopAlarmService');
    } on PlatformException catch (e) {
      print("Failed to stop service: '${e.message}'.");
    }
  }
}

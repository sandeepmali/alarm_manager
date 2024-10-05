import 'package:flutter/material.dart';

class ListItem {
  final TimeOfDay? alarmTIme;
  final int? notificationId;
  late final bool isAlarmOn;

  ListItem({required this.alarmTIme, required this.isAlarmOn, required  this.notificationId});
}

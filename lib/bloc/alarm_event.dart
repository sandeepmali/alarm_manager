part of 'alarm_bloc.dart';

@immutable
abstract class AlarmEvent {}

class FetchListOfAlarms extends AlarmEvent {}

class AddAlarmItem extends AlarmEvent {
  final ListItem alarmItem;

  AddAlarmItem(this.alarmItem);
}

class RemoveAlarmItem extends AlarmEvent {
  final int index;

  RemoveAlarmItem(this.index);
}

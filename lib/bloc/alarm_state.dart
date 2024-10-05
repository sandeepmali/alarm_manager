part of 'alarm_bloc.dart';

@immutable
abstract  class AlarmState {}

class ListInitial extends AlarmState {}

class ListLoading extends AlarmState {}
class ListAddItem extends AlarmState {}

class ListLoaded extends AlarmState {
  final List<ListItem> items;
  ListLoaded(this.items);
}

class ListError extends AlarmState {
  final String errorMessage;
  ListError(this.errorMessage);
}
import 'package:alarm/bloc/list_item.dart';
import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';

part 'alarm_event.dart';

part 'alarm_state.dart';

class AlarmBloc extends Bloc<AlarmEvent, AlarmState> {
  List<ListItem> alarmItemList = [];

  AlarmBloc() : super(ListInitial()) {
    on<FetchListOfAlarms>((event, emit) async {
      emit(ListLoading());
      try {
        await Future.delayed(Duration(seconds: 2));
        List<ListItem> items = [];
        emit(ListLoaded(items));
      } catch (e) {
        emit(ListError("Failed to fetch list items"));
      }
    });
    on<AddAlarmItem>((event, emit) {
      alarmItemList.add(event.alarmItem);
      emit(ListLoaded(alarmItemList));
    });
    on<RemoveAlarmItem>((event, emit) {
      if (alarmItemList.length>0) {
        alarmItemList.removeAt(event.index); // Remove the item by index
        emit(ListLoaded(alarmItemList)); // Emit the updated list
      } else {
        emit(ListError("Failed to fetch list items"));
      }
    });
  }
}

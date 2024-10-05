import 'dart:async';
import 'dart:developer' as developer;
import 'dart:isolate';
import 'dart:math';
import 'dart:ui';

import 'package:alarm/alarmservicemanager.dart';
import 'package:alarm/bloc/alarm_bloc.dart';
import 'package:alarm/bloc/list_item.dart';
import 'package:alarm/constant.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

/// The [SharedPreferences] key to access the alarm fire count.
const String countKey = 'count';

/// The name associated with the UI isolate's [SendPort].
const String isolateName = 'isolate';

/// A port used to communicate from a background isolate to the UI isolate.
ReceivePort port = ReceivePort();

/// Global [SharedPreferences] object.
SharedPreferences? prefs;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Register the UI isolate's SendPort to allow for communication from the
  // background isolate.
  IsolateNameServer.registerPortWithName(
    port.sendPort,
    isolateName,
  );
  prefs = await SharedPreferences.getInstance();
  if (!prefs!.containsKey(countKey)) {
    await prefs!.setInt(countKey, 0);
  }
// Initialize the local notification plugin
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('app_icon');

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  // Initialize the Android Alarm Manager
  await AndroidAlarmManager.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_context) => AlarmBloc()..add(FetchListOfAlarms()),
      child: MaterialApp(
        title: Constant.ALARM_MANAGER,
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        // home: ,
        home: const AlarmPage(title: Constant.ALARM_MANAGER),
      ),
    );
  }
}

class AlarmPage extends StatefulWidget {
  const AlarmPage({super.key, required this.title});

  final String title;

  @override
  State<AlarmPage> createState() => _AlarmPageState();
}

class _AlarmPageState extends State<AlarmPage> {
  TimeOfDay? selectedTime;
  TimePickerEntryMode entryMode = TimePickerEntryMode.dial;
  Orientation? orientation;
  TextDirection textDirection = TextDirection.ltr;
  MaterialTapTargetSize tapTargetSize = MaterialTapTargetSize.padded;
  bool use24HourTime = false;

  Future<void> showAlarmNotification() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'alarm_channel',
      'Alarm',
      channelDescription: 'This is your alarm notification',
      importance: Importance.max,
      priority: Priority.high,
      sound: RawResourceAndroidNotificationSound('alarm_sound'),
      playSound: true,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      0,
      'Alarm',
      'Your alarm is ringing!',
      platformChannelSpecifics,
    );
  }

  Future<TimeOfDay?> showTimePicker({
    required BuildContext context,
    required TimeOfDay initialTime,
    TransitionBuilder? builder,
    bool barrierDismissible = true,
    Color? barrierColor,
    String? barrierLabel,
    bool useRootNavigator = true,
    TimePickerEntryMode initialEntryMode = TimePickerEntryMode.dial,
    String? cancelText,
    String? confirmText,
    String? helpText,
    String? errorInvalidText,
    String? hourLabelText,
    String? minuteLabelText,
    RouteSettings? routeSettings,
    EntryModeChangeCallback? onEntryModeChanged,
    Offset? anchorPoint,
    Orientation? orientation,
  }) async {
    assert(debugCheckHasMaterialLocalizations(context));

    final Widget dialog = TimePickerDialog(
      initialTime: initialTime,
      initialEntryMode: initialEntryMode,
      cancelText: cancelText,
      confirmText: confirmText,
      helpText: helpText,
      errorInvalidText: errorInvalidText,
      hourLabelText: hourLabelText,
      minuteLabelText: minuteLabelText,
      orientation: orientation,
      onEntryModeChanged: onEntryModeChanged,
    );
    return showDialog<TimeOfDay>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierColor: barrierColor,
      barrierLabel: barrierLabel,
      useRootNavigator: useRootNavigator,
      builder: (BuildContext context) {
        return builder == null ? dialog : builder(context, dialog);
      },
      routeSettings: routeSettings,
      anchorPoint: anchorPoint,
    );
  }

  Future<void> requestAlarmPermission() async {
    if (_exactAlarmPermissionStatus.isDenied) {
      await Permission.scheduleExactAlarm
          .onGrantedCallback(() => setState(() {
                _exactAlarmPermissionStatus = PermissionStatus.granted;
              }))
          .request();
    } else {
      openTimePicker();
    }
  }

  Future<void> setAlarmNow() async {
    await AndroidAlarmManager.oneShot(
      const Duration(seconds: 15),
      // Ensure we have a unique alarm ID.
      Random().nextInt(pow(2, 31) as int),
      callback,
      exact: true,
      wakeup: true,
    );
  }

  Future<void> setAlarmAt() async {
    final now = DateTime.now();
    DateTime selectedTimeInMili = DateTime(now.year, now.month, now.day, selectedTime!.hour,selectedTime!.minute);
    print(selectedTimeInMili.millisecondsSinceEpoch);
    AlarmServiceManager.startAlarmService(selectedTimeInMili.millisecondsSinceEpoch);
    var notificationID = Random().nextInt(pow(2, 31) as int);
    final item = ListItem(notificationId : notificationID, alarmTIme: selectedTime, isAlarmOn: true,);
    BlocProvider.of<AlarmBloc>(context).add(AddAlarmItem(item));
   /* final now = DateTime.now();
    await AndroidAlarmManager.oneShotAt(
      DateTime(now.year, now.month, now.day, selectedTime!.hour,
          selectedTime!.minute),
      notificationID,
      callback,
      exact: true,
      wakeup: true,
    );*/
  }

  Future<void> openTimePicker() async {
    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: selectedTime ?? TimeOfDay.now(),
      initialEntryMode: entryMode,
      orientation: orientation,
      cancelText: Constant.CANCEL_BTN_TXT,
      confirmText: Constant.SELECT_ALARM_TIME_OK,
      helpText: Constant.ALARM_TITLE,
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            materialTapTargetSize: tapTargetSize,
          ),
          child: Directionality(
            textDirection: textDirection,
            child: MediaQuery(
              data: MediaQuery.of(context).copyWith(
                alwaysUse24HourFormat: use24HourTime,
              ),
              child: child!,
            ),
          ),
        );
      },
    );
    selectedTime = time;
    setAlarmAt();
    // setAlarmNow();
  }

  void _checkExactAlarmPermission() async {
    final currentStatus = await Permission.scheduleExactAlarm.status;
    setState(() {
      _exactAlarmPermissionStatus = currentStatus;
    });
  }

  Future<void> _incrementCounter() async {
    developer.log('Increment counter!');
    // Ensure we've loaded the updated count from the background isolate.
    await prefs?.reload();
    // showAlarmNotification();
    setState(() {
      _counter++;
    });
  }

  // The background
  static SendPort? uiSendPort;

  // The callback for our alarm
  @pragma('vm:entry-point')
  static Future<void> callback() async {
    // Get the previous cached count and increment it.
    final prefs = await SharedPreferences.getInstance();
    final currentCount = prefs.getInt(countKey) ?? 0;
    await prefs.setInt(countKey, currentCount + 1);

    // This will be null if we're running in the background.
    uiSendPort ??= IsolateNameServer.lookupPortByName(isolateName);
    uiSendPort?.send(null);
  }

  int _counter = 0;
  PermissionStatus _exactAlarmPermissionStatus = PermissionStatus.granted;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    AndroidAlarmManager.initialize();
    _checkExactAlarmPermission();

    // Register for events from the background isolate. These messages will
    // always coincide with an alarm firing.
    port.listen((_) async => await _incrementCounter());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: IconButton(
              icon: const Icon(Icons.alarm_add),
              onPressed: () {
                requestAlarmPermission();
              },
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        child: Container(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          decoration: BoxDecoration(color: Color(0xF7C4DFF)),
          child: BlocBuilder<AlarmBloc, AlarmState>(
            builder: (context, state) {
              if (state is ListLoading) {
                return Center(child: CircularProgressIndicator());
              } else if (state is ListLoaded && state.items.length > 0) {
                return ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: state.items.length,
                  itemBuilder: (context, index) {
                    final item = state.items[index];
                    return Container(
                      height: 100,
                      child: Card(
                        color: Colors.white60,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Padding(
                              padding: EdgeInsets.only(left: 20, right: 20),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    item.alarmTIme!.hourOfPeriod.toString() +
                                        ":" +
                                        item.alarmTIme!.minute.toString() +
                                        " ",
                                    style: TextStyle(fontSize: 40.0),
                                  ),
                                  Text(item.alarmTIme!.period.name,
                                      style: TextStyle(fontSize: 20.0)),
                                ],
                              ),
                            ),
                            Switch(
                                value: item.isAlarmOn,
                                activeColor: Colors.amber,
                                activeTrackColor: Colors.cyan,
                                inactiveThumbColor: Colors.blueGrey.shade600,
                                inactiveTrackColor: Colors.grey.shade400,
                                splashRadius: 50.0,
                                onChanged: (value) => (){
                                  BlocProvider.of<AlarmBloc>(context).add(RemoveAlarmItem(index));

                                })
                          ],
                        ),
                      ),
                    );
                  },
                );
              } else if (state is ListError) {
                return Center(child: Text(state.errorMessage));
              } else {
                return Center(
                    child: Text(
                  "No Alarms set yet",
                  style: TextStyle(fontSize: 30.0),
                ));
              }
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          requestAlarmPermission();
        },
        tooltip: 'Increment',
        child: const Icon(Icons.alarm_add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

package com.example.alarm

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.widget.Toast
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.AlarmReceiver

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.alarm/alarm_service"
    private fun scheduleExactAlarm(timeInMillis: Long, message: String) {
        val alarmManager = this.getSystemService(Context.ALARM_SERVICE) as AlarmManager?
        val intent: Intent = Intent(this, AlarmReceiver::class.java)
        intent.putExtra("alarmMessage", message)

        val pendingIntent =
            PendingIntent.getBroadcast(this, 0, intent, PendingIntent.FLAG_MUTABLE )

        if (alarmManager != null) {
            // Schedule an exact alarm, ensuring backward compatibility
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                Toast.makeText(this, "Sandeep Mali: $timeInMillis", Toast.LENGTH_SHORT).show()
                alarmManager.setExactAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP,
                    timeInMillis,
                    pendingIntent
                )
            } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
                alarmManager.setExact(AlarmManager.RTC_WAKEUP, timeInMillis, pendingIntent)
            } else {
                alarmManager[AlarmManager.RTC_WAKEUP, timeInMillis] = pendingIntent
            }
        }
    }
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        MethodChannel(flutterEngine!!.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "scheduleAlarm" -> {

//                    val hour: Int? = call.argument("hour")
//                    val minute: Int? = call.argument("minute")
                    val selectedTime: Long? = call.argument("selectedTime")
                    if (selectedTime != null) {
//                        scheduleExactAlarm(selectedTime, "Alarm ringing")
                    };
                    startAlarmService(selectedTime)
                    result.success("Foreground Service Started")
                }
                "stopAlarmService" -> {
                    stopAlarmService()
                    result.success("Foreground Service Stopped")
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun startAlarmService(selectedTime : Long?) {
        lateinit var serviceIntent: Intent;
        serviceIntent = Intent(this, AlarmForegroundService::class.java)
//        serviceIntent.putExtra("hour",hour)
//        serviceIntent.putExtra("minute",minute)
        serviceIntent.putExtra("selectedTime",selectedTime)
        startForegroundService(serviceIntent)
    }

    private fun stopAlarmService() {
        val serviceIntent = Intent(this, AlarmForegroundService::class.java)
        stopService(serviceIntent)
    }
}

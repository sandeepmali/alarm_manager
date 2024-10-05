package com.example.alarm
import android.app.*
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.icu.util.Calendar
import android.os.Build
import android.os.IBinder
import android.os.PowerManager
import android.os.SystemClock
import android.provider.Settings
import android.widget.Toast
import androidx.core.app.NotificationCompat
import io.flutter.plugins.AlarmReceiver


class AlarmForegroundService : Service() {

    override fun onCreate() {
        super.onCreate()
    }

    private fun startForegroundService() {
        // Create a notification channel if API 26+
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                "alarm_service_channel",
                "Alarm Service",
                NotificationManager.IMPORTANCE_DEFAULT
            ).apply {
                description = "This is used to keep the alarm service running in the background"
            }
            val manager = getSystemService(NotificationManager::class.java)
            manager?.createNotificationChannel(channel)
        }

        // Build the notification
        val notification = NotificationCompat.Builder(this, "alarm_service_channel")
            .setContentTitle("Alarm is Active")
            .setContentText("The alarm service is running in the background")
//            .setSmallIcon(R.mipmap.ic_launcher)
            .build()

        // Start the service in the foreground with the notification
        startForeground(1, notification)
    }

    private fun scheduleAlarm(timeInMillis1: Long) {
        val calendar = Calendar.getInstance()
        val alarmManager = getSystemService(ALARM_SERVICE) as AlarmManager
        val intent = Intent(this, AlarmReceiver::class.java)
        intent.putExtra("alarmMessage", "alarmMessage")
        val powerManager = getSystemService(Context.POWER_SERVICE)as PowerManager
//
//            // Check if the app is already ignoring battery optimizations
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                if (!powerManager.isIgnoringBatteryOptimizations(getPackageName())) {
                    // If not, prompt the user to disable it
                    val intent = Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS);
                    startActivity(intent);
                }
            }
        val pendingIntent = PendingIntent.getBroadcast(
            this,
            timeInMillis1.toInt(),
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE // Required for Android 12+
        )

        if (alarmManager != null) {
            print(timeInMillis1);
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                alarmManager.setExactAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP,
                    timeInMillis1,
                    pendingIntent
                )

            } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
                alarmManager.setExact(AlarmManager.RTC_WAKEUP, timeInMillis1, pendingIntent)
            } else {
                alarmManager[AlarmManager.RTC_WAKEUP, timeInMillis1] = pendingIntent
            }
        }else {
            Toast.makeText(this, "alaram manger is null: ", Toast.LENGTH_SHORT).show()
        }
    }
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        // You can do your alarm-related logic here
        // Triggered when the alarm goes off
        val message = intent!!.getStringExtra("alarmMessage")
//        val hour = intent!!.getIntExtra("hour",0)
//        val minute = intent!!.getIntExtra("minute",0)
        val selectedTime = intent!!.getLongExtra("selectedTime",0)
//        Toast.makeText(this, "Alarm Triggeredservice: $hour", Toast.LENGTH_SHORT).show()
//        Toast.makeText(this, "Alarm Triggeredservice: $minute", Toast.LENGTH_SHORT).show()
        val date = Calendar.getInstance()
        val millisecondsDate = date.timeInMillis

        // Set the alarm to start at approximately 2:00 p.m.
//        val calendar = Calendar.getInstance()
////        calendar.timeInMillis = System.currentTimeMillis()
////        calendar[Calendar.HOUR_OF_DAY] = hour
////        calendar[Calendar.MINUTE] = minute
//        val alarmMgr = this.getSystemService(ALARM_SERVICE) as AlarmManager
//
//        val pendingIntent =
//            PendingIntent.getBroadcast(this, calendar.timeInMillis.toInt(), intent!!, PendingIntent.FLAG_MUTABLE)
//
//        alarmMgr.setInexactRepeating(
//            AlarmManager.RTC_WAKEUP, selectedTime,
//            AlarmManager.INTERVAL_DAY, pendingIntent
//        )
//        val ac =
//            AlarmManager.AlarmClockInfo(
//                selectedTime,
//                pendingIntent
//            )
//        alarmMgr.setAlarmClock(ac, pendingIntent)
//        alarmMgr.setAndAllowWhileIdle(
//            AlarmManager.RTC_WAKEUP,
//                    calendar.getTimeInMillis(),
//                    pendingIntent)

        scheduleAlarm(selectedTime);
        startForegroundService();
//        if (alarmMgr != null) {
//            // Schedule an exact alarm, ensuring backward compatibility
//            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
//                Toast.makeText(this, "Sandeep Mali: $calendar.getTimeInMillis()", Toast.LENGTH_SHORT).show()
//                alarmMgr.setExactAndAllowWhileIdle(
//                    AlarmManager.RTC_WAKEUP,
//                    calendar.getTimeInMillis(),
//                    pendingIntent
//                )
//            } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
//                alarmMgr.setExact(AlarmManager.RTC_WAKEUP, calendar.getTimeInMillis(), pendingIntent)
//            } else {
//                alarmMgr[AlarmManager.RTC_WAKEUP, calendar.getTimeInMillis()] = pendingIntent
//            }
//        }
        return START_STICKY // Ensures the service stays active if it's killed by the system
    }

    override fun onBind(intent: Intent?): IBinder? {
        Toast.makeText(this, "onbind: ", Toast.LENGTH_SHORT).show()
        return null
    }

    override fun stopService(name: Intent?): Boolean {
        Toast.makeText(this, "stop ", Toast.LENGTH_SHORT).show()
        return super.stopService(name)
    }

    override fun onDestroy() {
        super.onDestroy()
        Toast.makeText(this, "destroy ", Toast.LENGTH_SHORT).show()
    }
}
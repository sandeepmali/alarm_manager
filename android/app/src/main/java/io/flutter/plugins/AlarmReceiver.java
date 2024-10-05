package io.flutter.plugins;

import android.app.AlarmManager;
import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.icu.util.Calendar;
import android.media.AudioAttributes;
import android.media.AudioManager;
import android.media.MediaPlayer;
import android.net.Uri;
import android.os.Build;
import android.os.Handler;
import android.provider.Settings;
import android.widget.Toast;
import androidx.core.app.NotificationCompat;

public class AlarmReceiver extends BroadcastReceiver {
    private MediaPlayer mediaPlayer;
    private static final String CHANNEL_ID = "alarm_channel_id";
    private void showNotification(Context context) {
        // Create a NotificationManager to manage notifications
        NotificationManager notificationManager = (NotificationManager) context.getSystemService(Context.NOTIFICATION_SERVICE);

        // For Android 8.0 (API 26) and higher, create a notification channel
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            CharSequence name = "Alarm Notification";
            String description = "Notification for alarm";
            int importance = NotificationManager.IMPORTANCE_HIGH;

            NotificationChannel channel = new NotificationChannel(CHANNEL_ID, name, importance);
            channel.setDescription(description);

            // Register the channel with the system
            if (notificationManager != null) {
                notificationManager.createNotificationChannel(channel);
            }
        }

        // Build the notification
        NotificationCompat.Builder builder = new NotificationCompat.Builder(context, CHANNEL_ID)
                .setSmallIcon(android.R.drawable.ic_dialog_alert) // Notification icon
                .setContentTitle("Alarm Ringing")  // Notification title
                .setContentText("Your alarm is ringing!") // Notification message
                .setPriority(NotificationCompat.PRIORITY_HIGH) // Set priority for the notification
                .setAutoCancel(true);  // Dismiss the notification when clicked

        // Show the notification
        if (notificationManager != null) {
            notificationManager.notify(0, builder.build());
        }
    }
    @Override
    public void onReceive(Context context, Intent intent) {
        // Triggered when the alarm goes off
        String message = intent.getStringExtra("alarmMessage");
        Toast.makeText(context, "Alarm Triggered receiver: " + message, Toast.LENGTH_SHORT).show();
        playAlarmSound(context);
        showNotification(context);

        // Stop the alarm sound after 5 seconds
        new Handler().postDelayed(new Runnable() {
            @Override
            public void run() {
                stopAlarmSound();  // Stop the alarm after 5 seconds
            }
        }, 5000);
    }
    private void playAlarmSound(Context context) {
        // Get the system default alarm sound URI
        Uri alarmSound = Settings.System.DEFAULT_ALARM_ALERT_URI;

        // Initialize the MediaPlayer to play the alarm sound
        mediaPlayer = new MediaPlayer();

        try {
            mediaPlayer.setDataSource(context, alarmSound);

            // For devices running Android Lollipop (API 21) and above, set audio attributes
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                AudioAttributes audioAttributes = new AudioAttributes.Builder()
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .setUsage(AudioAttributes.USAGE_ALARM)
                        .build();
                mediaPlayer.setAudioAttributes(audioAttributes);
            } else {
                mediaPlayer.setAudioStreamType(AudioManager.STREAM_ALARM);
            }

            mediaPlayer.setLooping(true); // Loop the alarm sound
            mediaPlayer.prepare();
            mediaPlayer.start();
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    // Stop playing the alarm when the service or activity is destroyed
    public void stopAlarmSound() {
        if (mediaPlayer != null && mediaPlayer.isPlaying()) {
            mediaPlayer.stop();
            mediaPlayer.release();
            mediaPlayer = null;
        }
    }
}

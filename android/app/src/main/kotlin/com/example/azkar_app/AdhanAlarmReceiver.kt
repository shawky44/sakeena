package com.example.azkar_app

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat

class AdhanAlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_MY_PACKAGE_REPLACED,
            "android.intent.action.QUICKBOOT_POWERON",
            Intent.ACTION_TIME_CHANGED,
            Intent.ACTION_TIMEZONE_CHANGED,
            "android.app.action.SCHEDULE_EXACT_ALARM_PERMISSION_STATE_CHANGED",
            ACTION_RESCHEDULE -> AdhanAlarmScheduler.rescheduleStoredAlarms(context)

            ACTION_PRAYER_REMINDER -> showPrayerReminder(context, intent)
            ACTION_ACTIVITY_REMINDER -> showActivityReminder(context, intent)

            ACTION_PLAY_ADHAN -> {
                val serviceIntent = Intent(context, AdhanPlaybackService::class.java).apply {
                    action = AdhanPlaybackService.ACTION_PLAY
                    putExtras(intent)
                }
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    context.startForegroundService(serviceIntent)
                } else {
                    context.startService(serviceIntent)
                }
            }
        }
    }

    private fun showActivityReminder(context: Context, intent: Intent) {
        val title = intent.getStringExtra("title").orEmpty().ifBlank { "تذكير اليوم" }
        val body = intent.getStringExtra("body").orEmpty()
        val notificationManager =
            context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                ACTIVITY_CHANNEL_ID,
                "تذكيرات الأذكار والعبادات",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "تذكيرات أذكار الصباح والمساء والضحى وقيام الليل"
                enableVibration(true)
            }
            notificationManager.createNotificationChannel(channel)
        }

        val launchIntent = context.packageManager
            .getLaunchIntentForPackage(context.packageName)
            ?: Intent()
        val contentIntent = PendingIntent.getActivity(
            context,
            intent.getIntExtra("id", 0) + 80_000,
            launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val notification = NotificationCompat.Builder(context, ACTIVITY_CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(title)
            .setContentText(body)
            .setStyle(NotificationCompat.BigTextStyle().bigText(body))
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setCategory(NotificationCompat.CATEGORY_REMINDER)
            .setAutoCancel(true)
            .setContentIntent(contentIntent)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .build()

        notificationManager.notify(intent.getIntExtra("id", 0), notification)
    }

    private fun showPrayerReminder(context: Context, intent: Intent) {
        val prayerName = intent.getStringExtra("prayerName").orEmpty().ifBlank { "الصلاة" }
        val minutesBefore = intent.getIntExtra("minutesBefore", 15).coerceAtLeast(1)
        val notificationManager =
            context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                REMINDER_CHANNEL_ID,
                "تذكير قبل الصلاة",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "إشعار قبل دخول وقت الصلاة"
                enableVibration(true)
            }
            notificationManager.createNotificationChannel(channel)
        }

        val launchIntent = context.packageManager
            .getLaunchIntentForPackage(context.packageName)
            ?: Intent()
        val contentIntent = PendingIntent.getActivity(
            context,
            intent.getIntExtra("id", 0) + 70_000,
            launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val notification = NotificationCompat.Builder(context, REMINDER_CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle("متبقي $minutesBefore دقيقة على صلاة $prayerName")
            .setContentText("استعد للصلاة، اقترب وقت $prayerName.")
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setCategory(NotificationCompat.CATEGORY_REMINDER)
            .setAutoCancel(true)
            .setContentIntent(contentIntent)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .build()

        notificationManager.notify(intent.getIntExtra("id", 0), notification)
    }

    companion object {
        const val ACTION_PLAY_ADHAN = "com.example.azkar_app.PLAY_ADHAN"
        const val ACTION_PRAYER_REMINDER = "com.example.azkar_app.PRAYER_REMINDER"
        const val ACTION_ACTIVITY_REMINDER = "com.example.azkar_app.ACTIVITY_REMINDER"
        const val ACTION_RESCHEDULE = "com.example.azkar_app.RESCHEDULE_ADHAN"
        const val REMINDER_CHANNEL_ID = "prayer_reminder_v1"
        const val ACTIVITY_CHANNEL_ID = "worship_activity_reminder_v1"
    }
}

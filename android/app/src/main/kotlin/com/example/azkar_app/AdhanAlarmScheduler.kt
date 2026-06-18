package com.example.azkar_app

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import org.json.JSONArray
import org.json.JSONObject

object AdhanAlarmScheduler {
    private const val PREFS_NAME = "adhan_alarm_schedule"
    private const val KEY_ALARMS = "alarms"

    fun schedulePrayerAlarms(context: Context, alarms: List<Map<String, Any>>): Boolean {
        if (!canScheduleExactAlarms(context)) return false

        cancelPrayerAlarms(context)
        persist(context, alarms)

        val now = System.currentTimeMillis()
        try {
            for (alarm in alarms) {
                val timeMillis = (alarm["timeMillis"] as? Number)?.toLong() ?: continue
                if (timeMillis <= now) continue
                scheduleSingleAlarm(context, alarm)
            }
        } catch (e: Exception) {
            rescheduleStoredAlarms(context)
            return false
        }
        return true
    }

    fun rescheduleStoredAlarms(context: Context) {
        if (!canScheduleExactAlarms(context)) return

        val alarms = readPersisted(context)
        val now = System.currentTimeMillis()
        for (alarm in alarms) {
            val timeMillis = (alarm["timeMillis"] as? Number)?.toLong() ?: continue
            if (timeMillis > now) {
                try {
                    scheduleSingleAlarm(context, alarm)
                } catch (_: Exception) {
                }
            }
        }
    }

    fun cancelPrayerAlarms(context: Context) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        for (alarm in readPersisted(context)) {
            val id = (alarm["id"] as? Number)?.toInt() ?: continue
            alarmManager.cancel(pendingIntent(context, id, alarm))
        }
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .edit()
            .remove(KEY_ALARMS)
            .apply()
    }

    private fun scheduleSingleAlarm(context: Context, alarm: Map<String, Any>) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val id = (alarm["id"] as? Number)?.toInt() ?: return
        val timeMillis = (alarm["timeMillis"] as? Number)?.toLong() ?: return
        val operation = pendingIntent(context, id, alarm)
        val launchIntent = context.packageManager
            .getLaunchIntentForPackage(context.packageName)
            ?: Intent()
        val showIntent = PendingIntent.getActivity(
            context,
            id + 50_000,
            launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        if (alarm["action"] == AdhanAlarmReceiver.ACTION_ACTIVITY_REMINDER) {
            alarmManager.setExactAndAllowWhileIdle(
                AlarmManager.RTC_WAKEUP,
                timeMillis,
                operation
            )
        } else {
            alarmManager.setAlarmClock(
                AlarmManager.AlarmClockInfo(timeMillis, showIntent),
                operation
            )
        }
    }

    private fun pendingIntent(context: Context, id: Int, alarm: Map<String, Any>): PendingIntent {
        val intent = Intent(context, AdhanAlarmReceiver::class.java).apply {
            action = alarm["action"] as? String ?: AdhanAlarmReceiver.ACTION_PLAY_ADHAN
            putExtra("id", id)
            putExtra("prayerKey", alarm["prayerKey"] as? String ?: "")
            putExtra("prayerName", alarm["prayerName"] as? String ?: "")
            putExtra("timeMillis", (alarm["timeMillis"] as? Number)?.toLong() ?: 0L)
            putExtra("playShort", alarm["playShort"] as? Boolean ?: false)
            putExtra("minutesBefore", (alarm["minutesBefore"] as? Number)?.toInt() ?: 0)
            putExtra("title", alarm["title"] as? String ?: "")
            putExtra("body", alarm["body"] as? String ?: "")
        }
        return PendingIntent.getBroadcast(
            context,
            id,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }

    private fun canScheduleExactAlarms(context: Context): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) return true
        val alarmManager = context.getSystemService(AlarmManager::class.java)
        return alarmManager.canScheduleExactAlarms()
    }

    private fun persist(context: Context, alarms: List<Map<String, Any>>) {
        val json = JSONArray()
        for (alarm in alarms) {
            json.put(JSONObject().apply {
                put("id", (alarm["id"] as? Number)?.toInt() ?: 0)
                put("action", alarm["action"] as? String ?: AdhanAlarmReceiver.ACTION_PLAY_ADHAN)
                put("prayerKey", alarm["prayerKey"] as? String ?: "")
                put("prayerName", alarm["prayerName"] as? String ?: "")
                put("timeMillis", (alarm["timeMillis"] as? Number)?.toLong() ?: 0L)
                put("playShort", alarm["playShort"] as? Boolean ?: false)
                put("minutesBefore", (alarm["minutesBefore"] as? Number)?.toInt() ?: 0)
                put("title", alarm["title"] as? String ?: "")
                put("body", alarm["body"] as? String ?: "")
            })
        }
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .edit()
            .putString(KEY_ALARMS, json.toString())
            .apply()
    }

    private fun readPersisted(context: Context): List<Map<String, Any>> {
        val raw = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .getString(KEY_ALARMS, "[]") ?: "[]"
        val json = JSONArray(raw)
        return List(json.length()) { index ->
            val item = json.getJSONObject(index)
            mapOf(
                "id" to item.optInt("id"),
                "action" to item.optString("action", AdhanAlarmReceiver.ACTION_PLAY_ADHAN),
                "prayerKey" to item.optString("prayerKey"),
                "prayerName" to item.optString("prayerName"),
                "timeMillis" to item.optLong("timeMillis"),
                "playShort" to item.optBoolean("playShort"),
                "minutesBefore" to item.optInt("minutesBefore"),
                "title" to item.optString("title"),
                "body" to item.optString("body")
            )
        }
    }
}

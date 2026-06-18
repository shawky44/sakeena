package com.example.azkar_app

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.AudioManager
import android.media.MediaPlayer
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.PowerManager
import android.util.Log
import androidx.core.app.NotificationCompat

class AdhanPlaybackService : Service() {
    private var mediaPlayer: MediaPlayer? = null
    private var wakeLock: PowerManager.WakeLock? = null
    private var initialVolumes: Map<Int, Int> = emptyMap()
    private val handler = Handler(Looper.getMainLooper())
    private val stopRunnable = Runnable { stopSelf() }
    private val volumeMonitorRunnable = object : Runnable {
        override fun run() {
            if (hasVolumeChanged()) {
                stopSelf()
                return
            }
            handler.postDelayed(this, VOLUME_CHECK_INTERVAL_MS)
        }
    }

    override fun onCreate() {
        super.onCreate()
        createChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_STOP) {
            stopPlayback()
            stopSelf()
            return START_NOT_STICKY
        }

        val prayerName = intent?.getStringExtra("prayerName").orEmpty().ifBlank { "الصلاة" }
        val playShort = intent?.getBooleanExtra("playShort", false) ?: false

        resetPlaybackForNewRequest()
        acquireWakeLock(playShort)
        startForeground(NOTIFICATION_ID, buildNotification(prayerName))
        playAdhan(playShort)
        return START_NOT_STICKY
    }

    override fun onDestroy() {
        handler.removeCallbacks(stopRunnable)
        stopPlayback()
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun stopPlayback() {
        handler.removeCallbacks(stopRunnable)
        handler.removeCallbacks(volumeMonitorRunnable)
        releaseMediaPlayer()
        initialVolumes = emptyMap()
        wakeLock?.takeIf { it.isHeld }?.release()
        wakeLock = null
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            stopForeground(STOP_FOREGROUND_REMOVE)
        } else {
            @Suppress("DEPRECATION")
            stopForeground(true)
        }
    }

    private fun resetPlaybackForNewRequest() {
        handler.removeCallbacks(stopRunnable)
        handler.removeCallbacks(volumeMonitorRunnable)
        releaseMediaPlayer()
        initialVolumes = emptyMap()
    }

    private fun releaseMediaPlayer() {
        val player = mediaPlayer ?: return
        mediaPlayer = null
        try {
            player.setOnPreparedListener(null)
            player.setOnCompletionListener(null)
            player.setOnErrorListener(null)
            player.stop()
        } catch (_: IllegalStateException) {
            // The player may still be preparing or already stopped.
        } finally {
            try {
                player.release()
            } catch (error: Exception) {
                Log.w(TAG, "Unable to release Adhan MediaPlayer", error)
            }
        }
    }

    private fun playAdhan(playShort: Boolean) {
        try {
            val player = MediaPlayer()
            mediaPlayer = player
            resources.openRawResourceFd(R.raw.adhan).use { afd ->
                player.setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_ALARM)
                        .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                        .build()
                )
                player.setDataSource(afd.fileDescriptor, afd.startOffset, afd.length)
            }
            player.setOnPreparedListener { preparedPlayer ->
                if (mediaPlayer !== preparedPlayer) return@setOnPreparedListener
                try {
                    startVolumeMonitor()
                    preparedPlayer.start()
                    val maximumDuration = if (playShort) {
                        SHORT_ADHAN_DURATION_MS
                    } else {
                        MAX_PLAYBACK_DURATION_MS
                    }
                    handler.postDelayed(stopRunnable, maximumDuration)
                } catch (error: Exception) {
                    handlePlaybackError("Unable to start Adhan", error)
                }
            }
            player.setOnCompletionListener { completedPlayer ->
                if (mediaPlayer === completedPlayer) stopSelf()
            }
            player.setOnErrorListener { failedPlayer, what, extra ->
                if (mediaPlayer === failedPlayer) {
                    handlePlaybackError(
                        "MediaPlayer error what=$what extra=$extra",
                        null,
                    )
                }
                true
            }
            player.prepareAsync()
        } catch (error: Exception) {
            handlePlaybackError("Unable to prepare Adhan", error)
        }
    }

    private fun handlePlaybackError(message: String, error: Throwable?) {
        if (error == null) {
            Log.e(TAG, message)
        } else {
            Log.e(TAG, message, error)
        }
        stopPlayback()
        stopSelf()
    }

    private fun startVolumeMonitor() {
        val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        initialVolumes = MONITORED_VOLUME_STREAMS.associateWith { stream ->
            audioManager.getStreamVolume(stream)
        }
        handler.removeCallbacks(volumeMonitorRunnable)
        handler.postDelayed(volumeMonitorRunnable, VOLUME_CHECK_INTERVAL_MS)
    }

    private fun hasVolumeChanged(): Boolean {
        if (initialVolumes.isEmpty()) return false
        val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        return initialVolumes.any { (stream, initialVolume) ->
            audioManager.getStreamVolume(stream) != initialVolume
        }
    }

    private fun acquireWakeLock(playShort: Boolean) {
        wakeLock?.takeIf { it.isHeld }?.release()
        val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
        wakeLock = powerManager.newWakeLock(
            PowerManager.PARTIAL_WAKE_LOCK,
            "$packageName:AdhanPlayback"
        ).apply {
            setReferenceCounted(false)
            acquire(if (playShort) SHORT_ADHAN_DURATION_MS + 10_000L else FULL_ADHAN_WAKELOCK_MS)
        }
    }

    private fun buildNotification(prayerName: String) =
        NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle("حان الآن وقت صلاة $prayerName")
            .setContentText("الأذان يعمل الآن. اضغط إيقاف عند الحاجة.")
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setOngoing(true)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .addAction(0, "إيقاف الأذان", stopPendingIntent())
            .build()

    private fun stopPendingIntent(): PendingIntent {
        val intent = Intent(this, AdhanPlaybackService::class.java).apply {
            action = ACTION_STOP
        }
        return PendingIntent.getService(
            this,
            NOTIFICATION_ID,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }

    private fun createChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val channel = NotificationChannel(
            CHANNEL_ID,
            "تشغيل الأذان",
            NotificationManager.IMPORTANCE_HIGH
        ).apply {
            description = "إشعار تشغيل الأذان مع زر إيقاف"
            setSound(null, null)
            enableVibration(true)
        }
        getSystemService(NotificationManager::class.java).createNotificationChannel(channel)
    }

    companion object {
        const val CHANNEL_ID = "adhan_playback_v1"
        const val ACTION_PLAY = "com.example.azkar_app.ADhan_PLAY"
        const val ACTION_STOP = "com.example.azkar_app.ADhan_STOP"
        private const val NOTIFICATION_ID = 7001
        private const val SHORT_ADHAN_DURATION_MS = 70_000L
        private const val MAX_PLAYBACK_DURATION_MS = 7 * 60_000L
        private const val FULL_ADHAN_WAKELOCK_MS = MAX_PLAYBACK_DURATION_MS + 10_000L
        private const val VOLUME_CHECK_INTERVAL_MS = 300L
        private const val TAG = "AdhanPlaybackService"
        private val MONITORED_VOLUME_STREAMS = intArrayOf(
            AudioManager.STREAM_ALARM,
            AudioManager.STREAM_MUSIC,
            AudioManager.STREAM_RING,
            AudioManager.STREAM_NOTIFICATION
        )

        fun stop(context: Context) {
            val intent = Intent(context, AdhanPlaybackService::class.java).apply {
                action = ACTION_STOP
            }
            context.startService(intent)
        }
    }
}

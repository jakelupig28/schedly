package com.schedly.schedly

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.schedly.app/native"
    private val NOTIFICATION_CHANNEL_ID = "schedly_downloads"
    private val NOTIFICATION_ID = 1001

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        createNotificationChannel()

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "showDownloadingNotification" -> {
                    val title = call.argument<String>("title") ?: "Downloading Schedule... 📥"
                    val message = call.argument<String>("message") ?: "Rendering high-resolution poster for your gallery."
                    showDownloadingNotification(title, message)
                    result.success(true)
                }
                "showDownloadFinishedNotification" -> {
                    val title = call.argument<String>("title") ?: "Download Complete 🖼️"
                    val message = call.argument<String>("message") ?: "Schedule wallpaper saved to your Gallery."
                    showDownloadFinishedNotification(title, message)
                    result.success(true)
                }
                "updateWidgetData" -> {
                    val dataJson = call.argument<String>("data")
                    if (dataJson != null) {
                        val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                        prefs.edit().putString("flutter.schedly_widget_data", dataJson).apply()
                    }

                    // Update all widgets
                    val widgetManager = AppWidgetManager.getInstance(this)
                    val widgetIds = widgetManager.getAppWidgetIds(
                        ComponentName(this, ScheduleAppWidgetProvider::class.java)
                    )
                    for (id in widgetIds) {
                        ScheduleAppWidgetProvider.updateAppWidget(this, widgetManager, id)
                    }
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val name = "Schedly Downloads"
            val descriptionText = "Notifications for schedule download progress and updates"
            val importance = NotificationManager.IMPORTANCE_LOW
            val channel = NotificationChannel(NOTIFICATION_CHANNEL_ID, name, importance).apply {
                description = descriptionText
            }
            val notificationManager: NotificationManager =
                getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }

    private fun showDownloadingNotification(title: String, message: String) {
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        val intent = Intent(this, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val builder = NotificationCompat.Builder(this, NOTIFICATION_CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(title)
            .setContentText(message)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setOngoing(true)
            .setProgress(0, 0, true) // Indeterminate progress bar
            .setContentIntent(pendingIntent)

        notificationManager.notify(NOTIFICATION_ID, builder.build())
    }

    private fun showDownloadFinishedNotification(title: String, message: String) {
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        val intent = Intent(this, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val builder = NotificationCompat.Builder(this, NOTIFICATION_CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(title)
            .setContentText(message)
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .setAutoCancel(true)
            .setProgress(0, 0, false)
            .setContentIntent(pendingIntent)

        notificationManager.notify(NOTIFICATION_ID, builder.build())
    }
}

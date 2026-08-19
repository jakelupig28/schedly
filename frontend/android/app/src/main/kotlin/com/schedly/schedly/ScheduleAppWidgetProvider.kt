package com.schedly.schedly

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import org.json.JSONObject

class ScheduleAppWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    companion object {
        fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val widgetDataJson = prefs.getString("flutter.schedly_widget_data", null)

            val views = RemoteViews(context.packageName, R.layout.schedule_app_widget)

            // Setup click intent to launch the Schedly app
            val intent = Intent(context, MainActivity::class.java)
            val pendingIntent = PendingIntent.getActivity(
                context,
                0,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_container, pendingIntent)

            if (widgetDataJson != null) {
                try {
                    val json = JSONObject(widgetDataJson)
                    val subjectName = json.optString("subjectName", "No Upcoming Class")
                    val subjectCode = json.optString("subjectCode", "SCHEDLY")
                    val time = json.optString("time", "Enjoy your break!")
                    val room = json.optString("room", "")
                    val day = json.optString("day", "TODAY")

                    views.setTextViewText(R.id.widget_day, day.uppercase())
                    views.setTextViewText(R.id.widget_subject_code, "$subjectCode • Next Class")
                    views.setTextViewText(R.id.widget_subject_name, subjectName)
                    views.setTextViewText(R.id.widget_time, time)
                    views.setTextViewText(R.id.widget_room, if (room.isNotEmpty()) "Room $room" else "")
                } catch (e: Exception) {
                    views.setTextViewText(R.id.widget_subject_name, "Tap to open Schedly")
                }
            } else {
                views.setTextViewText(R.id.widget_subject_code, "SCHEDLY")
                views.setTextViewText(R.id.widget_subject_name, "Tap to scan your schedule")
                views.setTextViewText(R.id.widget_time, "No active schedule")
                views.setTextViewText(R.id.widget_room, "")
            }

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}

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
            try {
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

                val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                val widgetDataJson = prefs.getString("flutter.schedly_widget_data", null)
                val widgetSize = prefs.getString("flutter.widget_size", "Small (2x2)")
                val isSmall2x2 = widgetSize?.contains("2x2") == true

                if (widgetDataJson != null && widgetDataJson.isNotEmpty()) {
                    try {
                        val json = JSONObject(widgetDataJson)
                        val subjectName = json.optString("subjectName", "No Upcoming Class")
                        val subjectCode = json.optString("subjectCode", "SCHEDLY")
                        val time = json.optString("time", "Enjoy your break!")
                        val room = json.optString("room", "")
                        val instructor = json.optString("instructor", "")
                        val day = json.optString("day", "TODAY")

                        views.setTextViewText(R.id.widget_day, day.uppercase())
                        views.setTextViewText(R.id.widget_subject_code, if (isSmall2x2) subjectCode else "$subjectCode • Next Class")
                        views.setTextViewText(R.id.widget_subject_name, subjectName)
                        views.setTextViewText(R.id.widget_time, time)

                        val detailsText = when {
                            room.isNotEmpty() && instructor.isNotEmpty() -> if (isSmall2x2) "Rm $room • $instructor" else "Room $room • $instructor"
                            room.isNotEmpty() -> if (isSmall2x2) "Rm $room" else "Room $room"
                            instructor.isNotEmpty() -> instructor
                            else -> ""
                        }
                        views.setTextViewText(R.id.widget_room, detailsText)
                    } catch (e: Exception) {
                        views.setTextViewText(R.id.widget_day, "SCHEDLY")
                        views.setTextViewText(R.id.widget_subject_code, "CLASS SCHEDULE")
                        views.setTextViewText(R.id.widget_subject_name, "Tap to open Schedly")
                        views.setTextViewText(R.id.widget_time, "Tap to view classes")
                        views.setTextViewText(R.id.widget_room, "")
                    }
                } else {
                    views.setTextViewText(R.id.widget_day, "TODAY")
                    views.setTextViewText(R.id.widget_subject_code, "SCHEDLY")
                    views.setTextViewText(R.id.widget_subject_name, "Tap to set up schedule")
                    views.setTextViewText(R.id.widget_time, "Ready to organize classes")
                    views.setTextViewText(R.id.widget_room, "")
                }

                appWidgetManager.updateAppWidget(appWidgetId, views)
            } catch (e: Throwable) {
                // Failsafe to ensure no unhandled exception reaches AppWidgetService
            }
        }
    }
}

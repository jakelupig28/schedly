package com.schedly.schedly

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.util.SizeF
import android.view.View
import android.widget.RemoteViews
import org.json.JSONArray
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

    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle
    ) {
        updateAppWidget(context, appWidgetManager, appWidgetId, newOptions)
    }

    companion object {
        fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int,
            options: Bundle? = null
        ) {
            try {
                // Setup click intent to launch the Schedly app
                val intent = Intent(context, MainActivity::class.java)
                val pendingIntent = PendingIntent.getActivity(
                    context,
                    0,
                    intent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )

                val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                val widgetDataJson = prefs.getString("flutter.schedly_widget_data", null)

                val json = if (widgetDataJson != null && widgetDataJson.isNotEmpty()) {
                    try { JSONObject(widgetDataJson) } catch (_: Exception) { null }
                } else null

                val smallViews = buildSmallViews(context, json, pendingIntent)
                val mediumViews = buildMediumViews(context, json, pendingIntent)
                val largeViews = buildLargeViews(context, json, pendingIntent)

                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    val viewMapping = mapOf(
                        SizeF(100f, 70f) to smallViews,
                        SizeF(200f, 70f) to mediumViews,
                        SizeF(200f, 150f) to largeViews
                    )
                    val responsiveViews = RemoteViews(viewMapping)
                    appWidgetManager.updateAppWidget(appWidgetId, responsiveViews)
                } else {
                    val widgetOptions = options ?: appWidgetManager.getAppWidgetOptions(appWidgetId)
                    val minWidth = widgetOptions.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 0)
                    val minHeight = widgetOptions.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 0)

                    val selectedViews = when {
                        minHeight >= 150 -> largeViews
                        minWidth >= 200 -> mediumViews
                        else -> smallViews
                    }
                    appWidgetManager.updateAppWidget(appWidgetId, selectedViews)
                }
            } catch (e: Throwable) {
                // Failsafe to ensure no unhandled exception reaches AppWidgetService
            }
        }

        private fun buildSmallViews(context: Context, json: JSONObject?, pendingIntent: PendingIntent): RemoteViews {
            val views = RemoteViews(context.packageName, R.layout.schedule_app_widget_small)
            views.setOnClickPendingIntent(R.id.widget_container, pendingIntent)

            if (json != null) {
                val day = json.optString("day", "TODAY")
                val subjectCode = json.optString("subjectCode", "SCHEDLY")
                val subjectName = json.optString("subjectName", "No Upcoming Class")
                val time = json.optString("time", "Enjoy your break!")
                val room = json.optString("room", "")

                views.setTextViewText(R.id.widget_day, day.uppercase())
                views.setTextViewText(R.id.widget_subject_code, subjectCode)
                views.setTextViewText(R.id.widget_subject_name, subjectName)
                views.setTextViewText(R.id.widget_time, time)
                views.setTextViewText(R.id.widget_room, if (room.isNotEmpty()) "Rm $room" else "")
            } else {
                views.setTextViewText(R.id.widget_day, "TODAY")
                views.setTextViewText(R.id.widget_subject_code, "SCHEDLY")
                views.setTextViewText(R.id.widget_subject_name, "Tap to setup schedule")
                views.setTextViewText(R.id.widget_time, "Ready to organize classes")
                views.setTextViewText(R.id.widget_room, "")
            }
            return views
        }

        private fun buildMediumViews(context: Context, json: JSONObject?, pendingIntent: PendingIntent): RemoteViews {
            val views = RemoteViews(context.packageName, R.layout.schedule_app_widget_medium)
            views.setOnClickPendingIntent(R.id.widget_container, pendingIntent)

            if (json != null) {
                val day = json.optString("day", "TODAY")
                val date = json.optString("date", "TODAY")
                val isRestDay = json.optBoolean("isRestDay", false)
                val subjectCode = json.optString("subjectCode", "SCHEDLY")
                val subjectName = json.optString("subjectName", "No Upcoming Class")
                val time = json.optString("time", "Enjoy your break!")
                val room = json.optString("room", "")
                val instructor = json.optString("instructor", "")
                val secondCode = json.optString("secondSubjectCode", "")
                val secondTime = json.optString("secondTime", "")

                views.setTextViewText(R.id.widget_day, day.uppercase())
                views.setTextViewText(R.id.widget_date_tag, date)
                views.setTextViewText(R.id.widget_subject_code, if (isRestDay) "FREE" else "$subjectCode • Next Class")
                views.setTextViewText(R.id.widget_subject_name, subjectName)
                views.setTextViewText(R.id.widget_time, time)

                views.setTextViewText(R.id.widget_room, if (room.isNotEmpty()) "Room $room" else "")
                views.setTextViewText(R.id.widget_instructor, instructor)

                if (secondCode.isNotEmpty()) {
                    views.setTextViewText(R.id.widget_second_hint, "Next: $secondCode")
                } else {
                    val upcoming = json.optJSONArray("upcomingSessions")
                    if (upcoming != null && upcoming.length() > 0) {
                        val firstUpcoming = upcoming.optJSONObject(0)
                        val uDay = firstUpcoming?.optString("day", "") ?: ""
                        val uCode = firstUpcoming?.optString("subjectCode", "") ?: ""
                        views.setTextViewText(R.id.widget_second_hint, if (uCode.isNotEmpty()) "Next: $uDay $uCode" else "")
                    } else {
                        views.setTextViewText(R.id.widget_second_hint, "")
                    }
                }
            } else {
                views.setTextViewText(R.id.widget_day, "TODAY")
                views.setTextViewText(R.id.widget_date_tag, "SCHEDLY")
                views.setTextViewText(R.id.widget_subject_code, "CLASS SCHEDULE")
                views.setTextViewText(R.id.widget_subject_name, "Tap to open Schedly")
                views.setTextViewText(R.id.widget_time, "Tap to view classes")
                views.setTextViewText(R.id.widget_room, "")
                views.setTextViewText(R.id.widget_instructor, "")
                views.setTextViewText(R.id.widget_second_hint, "")
            }
            return views
        }

        private fun buildLargeViews(context: Context, json: JSONObject?, pendingIntent: PendingIntent): RemoteViews {
            val views = RemoteViews(context.packageName, R.layout.schedule_app_widget_large)
            views.setOnClickPendingIntent(R.id.widget_container, pendingIntent)

            if (json != null) {
                val day = json.optString("day", "TODAY")
                val date = json.optString("date", "TODAY")
                val isRestDay = json.optBoolean("isRestDay", false)
                val todaySessions = json.optJSONArray("todaySessions") ?: JSONArray()
                val totalToday = json.optInt("totalTodayClasses", 0)

                views.setTextViewText(R.id.widget_day, day.uppercase())
                views.setTextViewText(
                    R.id.widget_status_tag,
                    if (isRestDay) "REST DAY" else "$totalToday CLASSES"
                )

                if (todaySessions.length() > 0) {
                    views.setViewVisibility(R.id.widget_classes_container, View.VISIBLE)
                    views.setViewVisibility(R.id.widget_rest_container, View.GONE)

                    val rowIds = listOf(
                        Triple(R.id.widget_row_1, Triple(R.id.widget_row_1_time, R.id.widget_row_1_code, R.id.widget_row_1_name), R.id.widget_row_1_room),
                        Triple(R.id.widget_row_2, Triple(R.id.widget_row_2_time, R.id.widget_row_2_code, R.id.widget_row_2_name), R.id.widget_row_2_room),
                        Triple(R.id.widget_row_3, Triple(R.id.widget_row_3_time, R.id.widget_row_3_code, R.id.widget_row_3_name), R.id.widget_row_3_room),
                        Triple(R.id.widget_row_4, Triple(R.id.widget_row_4_time, R.id.widget_row_4_code, R.id.widget_row_4_name), R.id.widget_row_4_room)
                    )

                    for (i in rowIds.indices) {
                        val row = rowIds[i]
                        if (i < todaySessions.length()) {
                            val session = todaySessions.getJSONObject(i)
                            views.setViewVisibility(row.first, View.VISIBLE)
                            views.setTextViewText(row.second.first, session.optString("time", ""))
                            views.setTextViewText(row.second.second, session.optString("subjectCode", ""))
                            views.setTextViewText(row.second.third, session.optString("subjectName", ""))
                            val room = session.optString("room", "")
                            views.setTextViewText(row.third, if (room.isNotEmpty()) "Rm $room" else "")
                        } else {
                            views.setViewVisibility(row.first, View.GONE)
                        }
                    }
                } else {
                    views.setViewVisibility(R.id.widget_classes_container, View.GONE)
                    views.setViewVisibility(R.id.widget_rest_container, View.VISIBLE)
                    views.setTextViewText(R.id.widget_rest_title, "Rest Day Today")
                    views.setTextViewText(R.id.widget_rest_sub, "No classes scheduled for today. Take time to relax and recharge!")

                    val upcoming = json.optJSONArray("upcomingSessions")
                    if (upcoming != null && upcoming.length() > 0) {
                        val firstUpcoming = upcoming.optJSONObject(0)
                        val uDay = firstUpcoming?.optString("day", "") ?: ""
                        val uCode = firstUpcoming?.optString("subjectCode", "") ?: ""
                        val uTime = firstUpcoming?.optString("time", "") ?: ""
                        views.setTextViewText(R.id.widget_rest_next, "Upcoming: $uDay • $uCode ($uTime)")
                    } else {
                        views.setTextViewText(R.id.widget_rest_next, "Ready for next semester")
                    }
                }
            } else {
                views.setTextViewText(R.id.widget_day, "TODAY")
                views.setTextViewText(R.id.widget_status_tag, "SCHEDLY")
                views.setViewVisibility(R.id.widget_classes_container, View.GONE)
                views.setViewVisibility(R.id.widget_rest_container, View.VISIBLE)
                views.setTextViewText(R.id.widget_rest_title, "Welcome to Schedly")
                views.setTextViewText(R.id.widget_rest_sub, "Tap to scan or set up your class schedule")
                views.setTextViewText(R.id.widget_rest_next, "Tap to Open")
            }
            return views
        }
    }
}

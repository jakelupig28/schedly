import 'dart:convert';
import 'package:flutter/services.dart';
import '../providers/schedule_provider.dart';

class NativeService {
  static const MethodChannel _channel = MethodChannel('com.schedly.app/native');

  /// Displays an ongoing download notification in the Android system status bar
  static Future<void> showDownloadingNotification({
    String title = "Downloading Schedule... 📥",
    String message = "Rendering high-resolution poster for your gallery.",
  }) async {
    try {
      await _channel.invokeMethod('showDownloadingNotification', {
        'title': title,
        'message': message,
      });
    } catch (_) {}
  }

  /// Displays download completed status in the Android system status bar
  static Future<void> showDownloadFinishedNotification({
    String title = "Download Finished! 🖼️",
    String message = "Schedule wallpaper saved to your Gallery.",
  }) async {
    try {
      await _channel.invokeMethod('showDownloadFinishedNotification', {
        'title': title,
        'message': message,
      });
    } catch (_) {}
  }

  /// Syncs active schedule data to the Android native home screen widget
  static Future<void> syncNativeWidgetData(ScheduleProvider provider) async {
    try {
      final now = DateTime.now();
      const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      final currentDay = days[now.weekday - 1];

      final todaySessions = provider.activeSessions
          .where((s) => s.dayOfWeek.toLowerCase() == currentDay.toLowerCase())
          .toList();
      todaySessions.sort((a, b) => a.startTime.compareTo(b.startTime));

      final activeSession = todaySessions.isNotEmpty ? todaySessions.first : null;

      final data = {
        'day': currentDay,
        'subjectName': activeSession?.subjectName ?? (provider.activeSessions.isNotEmpty ? "Rest Day Today" : "No Active Schedule"),
        'subjectCode': activeSession?.subjectCode ?? (provider.activeSessions.isNotEmpty ? "FREE" : "SCHEDLY"),
        'time': activeSession != null ? "${activeSession.startTime} - ${activeSession.endTime}" : "Enjoy your day!",
        'room': activeSession?.room ?? "",
      };

      await _channel.invokeMethod('updateWidgetData', {
        'data': jsonEncode(data),
      });
    } catch (_) {}
  }
}

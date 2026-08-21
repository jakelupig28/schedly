import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../providers/schedule_provider.dart';

class NativeService {
  static const MethodChannel _channel = MethodChannel('com.schedly.app/native');

  /// Displays an ongoing download notification in the Android system status bar
  static Future<void> showDownloadingNotification({
    String title = "Downloading Schedule...",
    String message = "Rendering high-resolution poster for your gallery.",
  }) async {
    try {
      await _channel.invokeMethod('showDownloadingNotification', {
        'title': title,
        'message': message,
      });
    } catch (_) {}
  }

  /// Triggers immediate Android MediaStore scan so the file appears in the Gallery in milliseconds
  static Future<void> scanMediaFile(String filePath) async {
    try {
      await _channel.invokeMethod('scanMediaFile', {
        'filePath': filePath,
      });
    } catch (_) {}
  }

  /// Displays download completed status in the Android system status bar
  static Future<void> showDownloadFinishedNotification({
    String title = "Download Finished",
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
      final dateFormatted = DateFormat('MMM d').format(now).toUpperCase();

      final todaySessions = provider.activeSessions
          .where((s) => s.dayOfWeek.toLowerCase() == currentDay.toLowerCase())
          .toList();
      todaySessions.sort((a, b) => a.startTime.compareTo(b.startTime));

      // Find upcoming classes for the week if today is a rest day
      final List<Map<String, dynamic>> upcomingList = [];
      for (int i = 1; i <= 6; i++) {
        final nextDayIndex = (now.weekday - 1 + i) % 7;
        final nextDayName = days[nextDayIndex];
        final nextDaySessions = provider.activeSessions
            .where((s) => s.dayOfWeek.toLowerCase() == nextDayName.toLowerCase())
            .toList();
        if (nextDaySessions.isNotEmpty) {
          nextDaySessions.sort((a, b) => a.startTime.compareTo(b.startTime));
          for (final s in nextDaySessions) {
            upcomingList.add({
              'day': nextDayName,
              'subjectCode': s.subjectCode,
              'subjectName': s.subjectName,
              'time': "${s.startTime} - ${s.endTime}",
              'room': s.room,
              'instructor': s.instructor,
            });
          }
          break; // Next active day
        }
      }

      final activeSession = todaySessions.isNotEmpty ? todaySessions.first : null;
      final secondSession = todaySessions.length > 1 ? todaySessions[1] : null;

      final data = {
        'day': currentDay,
        'date': dateFormatted,
        'isRestDay': todaySessions.isEmpty,
        'hasSchedule': provider.activeSessions.isNotEmpty,
        'totalTodayClasses': todaySessions.length,
        'totalWeekClasses': provider.activeSessions.length,
        'course': provider.activeCourse,
        'subjectName': activeSession?.subjectName ?? (provider.activeSessions.isNotEmpty ? "Rest Day Today" : "No Active Schedule"),
        'subjectCode': activeSession?.subjectCode ?? (provider.activeSessions.isNotEmpty ? "FREE" : "SCHEDLY"),
        'time': activeSession != null ? "${activeSession.startTime} - ${activeSession.endTime}" : "Enjoy your day!",
        'room': activeSession?.room ?? "",
        'instructor': activeSession?.instructor ?? "",
        'secondSubjectCode': secondSession?.subjectCode ?? "",
        'secondSubjectName': secondSession?.subjectName ?? "",
        'secondTime': secondSession != null ? "${secondSession.startTime} - ${secondSession.endTime}" : "",
        'secondRoom': secondSession?.room ?? "",
        'todaySessions': todaySessions.map((s) => {
          'subjectCode': s.subjectCode,
          'subjectName': s.subjectName,
          'time': "${s.startTime} - ${s.endTime}",
          'room': s.room,
          'instructor': s.instructor,
        }).toList(),
        'upcomingSessions': upcomingList,
      };

      await _channel.invokeMethod('updateWidgetData', {
        'data': jsonEncode(data),
      });
    } catch (_) {}
  }

  /// Renders all pages of a PDF document to high-resolution PNG image paths via Android native PdfRenderer
  static Future<List<String>> renderPdfToImages(String pdfPath) async {
    try {
      final List<dynamic>? result = await _channel.invokeMethod('renderPdfToImages', {
        'pdfPath': pdfPath,
      });
      if (result != null) {
        return result.map((e) => e.toString()).toList();
      }
    } catch (e) {
      // ignore
    }
    return [];
  }

  /// Requests device runtime permissions (Storage, Notifications, Camera)
  static Future<void> requestAppPermissions() async {
    try {
      await _channel.invokeMethod('requestAppPermissions');
    } catch (_) {}
  }
}

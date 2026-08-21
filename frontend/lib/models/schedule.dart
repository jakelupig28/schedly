import 'dart:convert';

class ClassSession {
  final String id;
  final String subjectName;
  final String subjectCode;
  final String room;
  final String instructor;
  final String dayOfWeek; // e.g. "Monday", "Tuesday", etc.
  final String startTime; // e.g. "08:00 AM"
  final String endTime;   // e.g. "09:30 AM"
  final int colorValue;   // Hex color representation
  final int units;        // Credit / Lecture / Lab Units (e.g. 3, 2, 1)

  ClassSession({
    required this.id,
    required this.subjectName,
    required this.subjectCode,
    required this.room,
    required this.instructor,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.colorValue,
    this.units = 3,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'subjectName': subjectName,
      'subjectCode': subjectCode,
      'room': room,
      'instructor': instructor,
      'dayOfWeek': dayOfWeek,
      'startTime': startTime,
      'endTime': endTime,
      'colorValue': colorValue,
      'units': units,
    };
  }

  factory ClassSession.fromMap(Map<String, dynamic> map) {
    return ClassSession(
      id: map['id'] ?? '',
      subjectName: map['subjectName'] ?? '',
      subjectCode: map['subjectCode'] ?? '',
      room: map['room'] ?? '',
      instructor: map['instructor'] ?? '',
      dayOfWeek: map['dayOfWeek'] ?? 'Monday',
      startTime: map['startTime'] ?? '08:00 AM',
      endTime: map['endTime'] ?? '09:00 AM',
      colorValue: map['colorValue'] ?? 0xFF6C63FF,
      units: (map['units'] is num)
          ? (map['units'] as num).toInt()
          : (map['units'] != null ? int.tryParse(map['units'].toString()) ?? 3 : 3),
    );
  }

  String toJson() => json.encode(toMap());

  factory ClassSession.fromJson(String source) => ClassSession.fromMap(json.decode(source));

  ClassSession copyWith({
    String? id,
    String? subjectName,
    String? subjectCode,
    String? room,
    String? instructor,
    String? dayOfWeek,
    String? startTime,
    String? endTime,
    int? colorValue,
    int? units,
  }) {
    return ClassSession(
      id: id ?? this.id,
      subjectName: subjectName ?? this.subjectName,
      subjectCode: subjectCode ?? this.subjectCode,
      room: room ?? this.room,
      instructor: instructor ?? this.instructor,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      colorValue: colorValue ?? this.colorValue,
      units: units ?? this.units,
    );
  }
}

class ScheduleHistoryItem {
  final String id;
  final String schoolYear; // e.g. "S.Y. 2026-2027"
  final String semester;   // e.g. "1st Semester", "2nd Semester", "Summer"
  final String course;     // e.g. "BS Information Technology"
  final String year;       // e.g. "3rd Year"
  final String section;    // e.g. "Section A"
  final List<ClassSession> sessions;
  final String themeStyle; // e.g. "Pastel Sky", "Sticker Template", etc.
  final List<int> bgColors; // List of hex integers for gradient backgrounds
  final DateTime createdAt;

  ScheduleHistoryItem({
    required this.id,
    required this.schoolYear,
    this.semester = '1st Semester',
    required this.course,
    required this.year,
    required this.section,
    required this.sessions,
    required this.themeStyle,
    required this.bgColors,
    required this.createdAt,
  });

  /// Accurate total units calculated from distinct subjects (preventing double counting multi-day sessions)
  int get totalUnits {
    if (sessions.isEmpty) return 0;
    final seen = <String>{};
    int sum = 0;
    for (final s in sessions) {
      final key = s.subjectCode.isNotEmpty ? s.subjectCode.toUpperCase().replaceAll(RegExp(r'\s+'), '') : s.subjectName.toLowerCase();
      if (seen.add(key)) {
        sum += s.units > 0 ? s.units : 3;
      }
    }
    return sum > 0 ? sum : (sessions.length * 3);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'schoolYear': schoolYear,
      'semester': semester,
      'course': course,
      'year': year,
      'section': section,
      'sessions': sessions.map((x) => x.toMap()).toList(),
      'themeStyle': themeStyle,
      'bgColors': bgColors,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory ScheduleHistoryItem.fromMap(Map<String, dynamic> map) {
    return ScheduleHistoryItem(
      id: map['id'] ?? '',
      schoolYear: map['schoolYear'] ?? 'S.Y. 2026-2027',
      semester: map['semester'] ?? '1st Semester',
      course: map['course'] ?? 'BS Information Technology',
      year: map['year'] ?? '1st Year',
      section: map['section'] ?? 'Section A',
      sessions: List<ClassSession>.from(
        (map['sessions'] as List<dynamic>? ?? []).map((x) => ClassSession.fromMap(x as Map<String, dynamic>)),
      ),
      themeStyle: map['themeStyle'] ?? 'Sticker Template',
      bgColors: List<int>.from(map['bgColors'] ?? [0xFF6C63FF, 0xFF3F3D56]),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? DateTime.now().millisecondsSinceEpoch),
    );
  }

  String toJson() => json.encode(toMap());

  factory ScheduleHistoryItem.fromJson(String source) => ScheduleHistoryItem.fromMap(json.decode(source));

  ScheduleHistoryItem copyWith({
    String? id,
    String? schoolYear,
    String? semester,
    String? course,
    String? year,
    String? section,
    List<ClassSession>? sessions,
    String? themeStyle,
    List<int>? bgColors,
    DateTime? createdAt,
  }) {
    return ScheduleHistoryItem(
      id: id ?? this.id,
      schoolYear: schoolYear ?? this.schoolYear,
      semester: semester ?? this.semester,
      course: course ?? this.course,
      year: year ?? this.year,
      section: section ?? this.section,
      sessions: sessions ?? this.sessions,
      themeStyle: themeStyle ?? this.themeStyle,
      bgColors: bgColors ?? this.bgColors,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}


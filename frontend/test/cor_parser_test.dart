import 'package:flutter_test/flutter_test.dart';
import 'package:schedly/models/schedule.dart';
import 'package:schedly/services/cor_parser_service.dart';

void main() {
  group('ClassSession Model & Units Tests', () {
    test('ClassSession default units is 3 and serializes properly', () {
      final session = ClassSession(
        id: 's1',
        subjectName: 'Data Structures and Algorithms',
        subjectCode: 'IT 101',
        room: 'CL 3',
        instructor: 'Prof. Sison, Edgardo',
        dayOfWeek: 'Monday',
        startTime: '08:00 AM',
        endTime: '10:00 AM',
        colorValue: 0xFF6C63FF,
        units: 3,
      );

      expect(session.units, 3);
      final map = session.toMap();
      expect(map['units'], 3);

      final fromMap = ClassSession.fromMap(map);
      expect(fromMap.units, 3);
      expect(fromMap.subjectCode, 'IT 101');
      expect(fromMap.instructor, 'Prof. Sison, Edgardo');
    });

    test('ScheduleHistoryItem calculates distinct totalUnits accurately without multi-day duplication', () {
      final sessions = [
        ClassSession(
          id: 's1_mon',
          subjectName: 'System Administration',
          subjectCode: 'IT 201',
          room: 'Rm 301',
          instructor: 'Prof. Garcia',
          dayOfWeek: 'Monday',
          startTime: '08:00 AM',
          endTime: '09:30 AM',
          colorValue: 0xFF6C63FF,
          units: 3,
        ),
        ClassSession(
          id: 's1_wed',
          subjectName: 'System Administration',
          subjectCode: 'IT 201',
          room: 'Rm 301',
          instructor: 'Prof. Garcia',
          dayOfWeek: 'Wednesday',
          startTime: '08:00 AM',
          endTime: '09:30 AM',
          colorValue: 0xFF6C63FF,
          units: 3,
        ),
        ClassSession(
          id: 's2_fri',
          subjectName: 'Database Lab',
          subjectCode: 'IT 202L',
          room: 'CL 1',
          instructor: 'Engr. Navarro',
          dayOfWeek: 'Friday',
          startTime: '01:00 PM',
          endTime: '04:00 PM',
          colorValue: 0xFF4ECDC4,
          units: 1,
        ),
      ];

      final historyItem = ScheduleHistoryItem(
        id: 'h1',
        schoolYear: 'S.Y. 2026-2027',
        semester: '1st Semester',
        course: 'BS Information Technology',
        year: '2nd Year',
        section: 'BSIT-2A',
        sessions: sessions,
        themeStyle: 'Modern Clean',
        bgColors: [0xFF6C63FF, 0xFF3F3D56],
        createdAt: DateTime.now(),
      );

      // IT 201 (3 units) + IT 202L (1 unit) = 4 Total Units
      expect(historyItem.totalUnits, 4);
    });
  });
}

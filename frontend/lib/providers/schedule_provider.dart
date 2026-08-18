import 'dart:convert';
import 'package:flutter/material';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/schedule.dart';

class ScheduleProvider with ChangeNotifier {
  // Active editing schedule details
  String _activeSchoolYear = '';
  String _activeCourse = '';
  String _activeYear = '';
  String _activeSection = '';
  List<ClassSession> _activeSessions = [];

  // Student Profile Data
  String _studentFirstName = '';
  String _studentMiddleName = '';
  String _studentSurname = '';
  String _studentBirthdate = '';
  String _studentAge = '';
  String _studentEmail = '';

  // Theme mode
  ThemeMode _themeMode = ThemeMode.light;

  // History list
  List<ScheduleHistoryItem> _history = [];

  // Settings for exportation
  String _exportThemeStyle = 'Pastel Sky'; // 'Pastel Sky', 'Cyberpunk Neon', 'Minimalist Ink', 'Forest Study'
  int _exportBgColorStartIndex = 0;
  int _exportBgColorEndIndex = 1;

  // Constructor
  ScheduleProvider() {
    loadSettingsFromPrefs();
  }

  // Getters
  String get activeSchoolYear => _activeSchoolYear;
  String get activeCourse => _activeCourse.isNotEmpty ? _activeCourse : 'BS Information Technology';
  String get activeYear => _activeYear.isNotEmpty ? _activeYear : '1st Year';
  String get activeSection => _activeSection;
  List<ClassSession> get activeSessions => _activeSessions;
  ThemeMode get themeMode => _themeMode;
  List<ScheduleHistoryItem> get history => _history;
  String get exportThemeStyle => _exportThemeStyle;
  int get exportBgColorStartIndex => _exportBgColorStartIndex;
  int get exportBgColorEndIndex => _exportBgColorEndIndex;

  // Student Profile Getters
  String get studentFirstName => _studentFirstName.isNotEmpty ? _studentFirstName : 'Student';
  String get studentMiddleName => _studentMiddleName;
  String get studentSurname => _studentSurname;
  String get studentBirthdate => _studentBirthdate;
  String get studentAge => _studentAge;
  String get studentEmail => _studentEmail;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  // Setters
  void updateStudentProfile({
    required String firstName,
    required String middleName,
    required String surname,
    required String birthdate,
    required String age,
    required String email,
    required String course,
    required String year,
  }) async {
    _studentFirstName = firstName;
    _studentMiddleName = middleName;
    _studentSurname = surname;
    _studentBirthdate = birthdate;
    _studentAge = age;
    _studentEmail = email;
    _activeCourse = course;
    _activeYear = year;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('student_firstName', firstName);
    await prefs.setString('student_middleName', middleName);
    await prefs.setString('student_surname', surname);
    await prefs.setString('student_birthdate', birthdate);
    await prefs.setString('student_age', age);
    await prefs.setString('student_email', email);
    await prefs.setString('student_course', course);
    await prefs.setString('student_year', year);
  }

  void clearStudentProfile() async {
    _studentFirstName = '';
    _studentMiddleName = '';
    _studentSurname = '';
    _studentBirthdate = '';
    _studentAge = '';
    _studentEmail = '';
    _activeCourse = '';
    _activeYear = '';
    _activeSessions.clear();
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('student_firstName');
    await prefs.remove('student_middleName');
    await prefs.remove('student_surname');
    await prefs.remove('student_birthdate');
    await prefs.remove('student_age');
    await prefs.remove('student_email');
    await prefs.remove('student_course');
    await prefs.remove('student_year');
  }
  void updateActiveDetails({
    String? schoolYear,
    String? course,
    String? year,
    String? section,
  }) {
    if (schoolYear != null) _activeSchoolYear = schoolYear;
    if (course != null) _activeCourse = course;
    if (year != null) _activeYear = year;
    if (section != null) _activeSection = section;
    notifyListeners();
  }

  void setExportStyle(String style) {
    _exportThemeStyle = style;
    notifyListeners();
  }

  void setExportGradient(int startIdx, int endIdx) {
    _exportBgColorStartIndex = startIdx;
    _exportBgColorEndIndex = endIdx;
    notifyListeners();
  }

  // Toggle Theme Mode
  void toggleTheme(bool isOn) async {
    _themeMode = isOn ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', isOn);
  }

  // Manage Sessions
  void addSession(ClassSession session) {
    _activeSessions.add(session);
    notifyListeners();
  }

  void updateSession(ClassSession updatedSession) {
    final index = _activeSessions.indexWhere((s) => s.id == updatedSession.id);
    if (index != -1) {
      _activeSessions[index] = updatedSession;
      notifyListeners();
    }
  }

  void deleteSession(String id) {
    _activeSessions.removeWhere((s) => s.id == id);
    notifyListeners();
  }

  void clearActiveSessions() {
    _activeSessions.clear();
    notifyListeners();
  }

  // Save current active schedule to history
  Future<void> saveCurrentToHistory() async {
    if (_activeSessions.isEmpty) return;

    final newItem = ScheduleHistoryItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      schoolYear: _activeSchoolYear,
      course: _activeCourse,
      year: _activeYear,
      section: _activeSection,
      sessions: List<ClassSession>.from(_activeSessions),
      themeStyle: _exportThemeStyle,
      bgColors: [_exportBgColorStartIndex, _exportBgColorEndIndex],
      createdAt: DateTime.now(),
    );

    // Remove if duplicate ID (highly unlikely)
    _history.removeWhere((item) => item.id == newItem.id);
    // Add to top of the history list
    _history.insert(0, newItem);
    notifyListeners();

    await saveHistoryToPrefs();
  }

  // Load a schedule from history to active workspace
  void loadHistoryItem(ScheduleHistoryItem item) {
    _activeSchoolYear = item.schoolYear;
    _activeCourse = item.course;
    _activeYear = item.year;
    _activeSection = item.section;
    _activeSessions = List<ClassSession>.from(item.sessions);
    _exportThemeStyle = item.themeStyle;
    if (item.bgColors.length >= 2) {
      _exportBgColorStartIndex = item.bgColors[0];
      _exportBgColorEndIndex = item.bgColors[1];
    }
    notifyListeners();
  }

  // Delete a history item
  Future<void> deleteHistoryItem(String id) async {
    _history.removeWhere((item) => item.id == id);
    notifyListeners();
    await saveHistoryToPrefs();
  }

  // Shared Preferences logic
  Future<void> loadSettingsFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load Dark Mode
    final isDark = prefs.getBool('isDarkMode') ?? false;
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;

    // Load Student Profile
    _studentFirstName = prefs.getString('student_firstName') ?? '';
    _studentMiddleName = prefs.getString('student_middleName') ?? '';
    _studentSurname = prefs.getString('student_surname') ?? '';
    _studentBirthdate = prefs.getString('student_birthdate') ?? '';
    _studentAge = prefs.getString('student_age') ?? '';
    _studentEmail = prefs.getString('student_email') ?? '';
    _activeCourse = prefs.getString('student_course') ?? _activeCourse;
    _activeYear = prefs.getString('student_year') ?? _activeYear;

    // Load History
    final historyJson = prefs.getString('schedule_history');
    if (historyJson != null) {
      try {
        final List<dynamic> decoded = json.decode(historyJson);
        _history = decoded.map((x) => ScheduleHistoryItem.fromMap(x)).toList();
      } catch (e) {
        // Handle decoding error elegantly
        _history = [];
      }
    }
    notifyListeners();
  }

  Future<void> saveHistoryToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final historyListMap = _history.map((x) => x.toMap()).toList();
    await prefs.setString('schedule_history', json.encode(historyListMap));
  }

  // Mock OCR Parsing Simulation
  Future<void> simulateOcrScan(String filePath, {String scanType = 'scan'}) async {
    // Simulate a 2-second extraction delay
    await Future.delayed(const Duration(seconds: 2));

    // Clear previous sessions for fresh parsing
    _activeSessions.clear();

    // Populate mock scanned data based on standard COR formats
    final mockSessions = [
      ClassSession(
        id: '1',
        subjectName: 'The Contemporary World',
        subjectCode: 'GECONTWO',
        room: 'Rm TBA',
        instructor: 'LAGDA, LAGDA',
        dayOfWeek: 'Monday',
        startTime: '01:00 PM',
        endTime: '02:30 PM',
        colorValue: 0xFF8E94F2,
      ),
      ClassSession(
        id: '2',
        subjectName: 'System Administration & Maintenance Lab',
        subjectCode: 'SYSADMLB',
        room: 'Rm TBA',
        instructor: 'LAGDA, LAGDA',
        dayOfWeek: 'Monday',
        startTime: '03:00 PM',
        endTime: '06:00 PM',
        colorValue: 0xFFE27396,
      ),
      ClassSession(
        id: '3',
        subjectName: 'Information Assurance & Security 2 Lab',
        subjectCode: 'IAASLAB2',
        room: 'Rm TBA',
        instructor: 'LAGDA, LAGDA',
        dayOfWeek: 'Tuesday',
        startTime: '07:00 AM',
        endTime: '10:00 AM',
        colorValue: 0xFFFFB703,
      ),
      ClassSession(
        id: '4',
        subjectName: 'Information Assurance & Security 2 Lecture',
        subjectCode: 'IAASLEC2',
        room: 'Rm TBA',
        instructor: 'LAGDA, LAGDA',
        dayOfWeek: 'Thursday',
        startTime: '07:00 AM',
        endTime: '09:00 AM',
        colorValue: 0xFFFFB703,
      ),
      ClassSession(
        id: '5',
        subjectName: 'IT Capstone Project & Thesis 2',
        subjectCode: 'ITTHESI2',
        room: 'Rm TBA',
        instructor: 'Anuncio, Hazel Anuncio',
        dayOfWeek: 'Tuesday',
        startTime: '12:00 PM',
        endTime: '02:00 PM',
        colorValue: 0xFF4ECDC4,
      ),
      ClassSession(
        id: '6',
        subjectName: 'IT Capstone Project & Thesis 2 Lab',
        subjectCode: 'ITTHESL2',
        room: 'Rm TBA',
        instructor: 'Anuncio, Hazel Anuncio',
        dayOfWeek: 'Thursday',
        startTime: '03:00 PM',
        endTime: '06:00 PM',
        colorValue: 0xFF4ECDC4,
      ),
      ClassSession(
        id: '7',
        subjectName: 'Systems Architecture & Integration 2',
        subjectCode: 'SYSARCH2',
        room: 'Rm TBA',
        instructor: 'Sison, Edgardo Sison',
        dayOfWeek: 'Tuesday',
        startTime: '06:00 PM',
        endTime: '08:00 PM',
        colorValue: 0xFF9D4EDD,
      ),
      ClassSession(
        id: '8',
        subjectName: 'System Administration & Maintenance Lecture',
        subjectCode: 'SYSADMLC',
        room: 'Rm TBA',
        instructor: 'Sison, Edgardo Sison',
        dayOfWeek: 'Thursday',
        startTime: '10:00 AM',
        endTime: '12:00 PM',
        colorValue: 0xFFE27396,
      ),
      ClassSession(
        id: '9',
        subjectName: 'The Contemporary World',
        subjectCode: 'GECONTWO',
        room: 'Rm TBA',
        instructor: 'LAGDA, LAGDA',
        dayOfWeek: 'Thursday',
        startTime: '01:00 PM',
        endTime: '02:30 PM',
        colorValue: 0xFF8E94F2,
      ),
      ClassSession(
        id: '10',
        subjectName: 'Social & Professional Issues in Computing',
        subjectCode: 'SPISSUESS',
        room: 'Rm TBA',
        instructor: 'LAGDA, LAGDA',
        dayOfWeek: 'Thursday',
        startTime: '06:00 PM',
        endTime: '09:00 PM',
        colorValue: 0xFF9D4EDD,
      ),
    ];

    _activeSessions.addAll(mockSessions);
    notifyListeners();
  }
}

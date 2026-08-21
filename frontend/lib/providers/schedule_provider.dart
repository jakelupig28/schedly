import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/schedule.dart';
import '../services/native_service.dart';
import '../services/cor_parser_service.dart';

class ScheduleProvider with ChangeNotifier {
  // Available Dropdown Options
  static const List<String> availableCourses = [
    'BS Information Technology',
    'BS Computer Science',
    'BS Information Systems',
    'BS Software Engineering',
    'BS Computer Engineering',
    'BS Electronics Engineering',
    'BS Civil Engineering',
    'BS Mechanical Engineering',
    'BS Electrical Engineering',
    'BS Industrial Engineering',
    'BS Architecture',
    'BS Accountancy',
    'BS Business Administration - Marketing',
    'BS Business Administration - Financial Management',
    'BS Business Administration - Human Resource Management',
    'BS Business Administration - Operations Management',
    'BS Hospitality Management',
    'BS Tourism Management',
    'BS Psychology',
    'Bachelor of Secondary Education - English',
    'Bachelor of Secondary Education - Mathematics',
    'Bachelor of Secondary Education - Science',
    'Bachelor of Elementary Education',
    'BS Nursing',
    'BS Medical Technology',
    'BS Biology',
    'BS Criminology',
    'BS Customs Administration',
    'AB Communication',
    'AB Political Science',
    'Bachelor of Fine Arts',
  ];

  static const List<String> availableSchoolYears = [
    'S.Y. 2026-2027',
    'S.Y. 2025-2026',
    'S.Y. 2024-2025',
    'S.Y. 2027-2028',
    'S.Y. 2028-2029',
  ];

  static const List<String> availableSemesters = [
    '1st Semester',
    '2nd Semester',
    'Summer / Midyear',
  ];

  static const List<String> availableYears = [
    '1st Year',
    '2nd Year',
    '3rd Year',
    '4th Year',
    '5th Year+',
  ];

  // Active editing schedule details
  String? _activeScheduleId;
  String _activeSchoolYear = 'S.Y. 2026-2027';
  String _activeSemester = '1st Semester';
  String _activeCourse = 'BS Information Technology';
  String _activeYear = '4th Year';
  String _activeSection = 'Section A';
  List<ClassSession> _activeSessions = [];

  // Student Profile Data
  String _studentFirstName = '';
  String _studentMiddleName = '';
  String _studentSurname = '';
  String _studentBirthdate = '';
  String _studentAge = '';
  String _studentEmail = '';
  String _studentSemester = '1st Semester';

  // Auth & Session Persistence
  bool _isInitialized = false;
  bool _isLoggedIn = false;
  bool _hasSeenOnboarding = false;
  int _lastActiveTimestamp = 0;
  bool _rememberMe = false;
  String _savedEmail = '';
  bool _sessionExpiredNotice = false;

  // Theme mode
  ThemeMode _themeMode = ThemeMode.light;

  // History list
  List<ScheduleHistoryItem> _history = [];

  // Settings for exportation
  String _exportThemeStyle = 'Sticker Template'; // Default to Sticker Template
  int _exportBgColorStartIndex = 0;
  int _exportBgColorEndIndex = 1;
  String? _customBgImagePath;

  // Homescreen Widget Settings
  String _widgetSize = 'Medium (4x2)';
  String _widgetBgStyle = 'Glassmorphism';
  bool _showWidgetTime = true;
  bool _showWidgetRoom = true;
  bool _showWidgetProfessor = true;

  // Constructor
  ScheduleProvider() {
    loadSettingsFromPrefs();
  }

  // Getters
  String? get activeScheduleId => _activeScheduleId;
  String get activeSchoolYear => _activeSchoolYear.isNotEmpty ? _activeSchoolYear : 'S.Y. 2026-2027';
  String get activeSemester => _activeSemester.isNotEmpty ? _activeSemester : '1st Semester';
  String get activeCourse => _activeCourse.isNotEmpty ? _activeCourse : 'BS Information Technology';
  String get activeYear => _activeYear.isNotEmpty ? _activeYear : '4th Year';
  String get activeSection => _activeSection.isNotEmpty ? _activeSection : 'Section A';
  List<ClassSession> get activeSessions => _activeSessions;
  ThemeMode get themeMode => _themeMode;
  List<ScheduleHistoryItem> get history => _history;
  String get exportThemeStyle => _exportThemeStyle;
  int get exportBgColorStartIndex => _exportBgColorStartIndex;
  int get exportBgColorEndIndex => _exportBgColorEndIndex;
  String? get customBgImagePath => _customBgImagePath;

  // Homescreen Widget Getters
  String get widgetSize => _widgetSize;
  String get widgetBgStyle => _widgetBgStyle;
  bool get showWidgetTime => _showWidgetTime;
  bool get showWidgetRoom => _showWidgetRoom;
  bool get showWidgetProfessor => _showWidgetProfessor;

  // Auth & Session Getters
  bool get isInitialized => _isInitialized;
  bool get isLoggedIn => _isLoggedIn;
  bool get hasSeenOnboarding => _hasSeenOnboarding;
  int get lastActiveTimestamp => _lastActiveTimestamp;
  bool get rememberMe => _rememberMe;
  String get savedEmail => _savedEmail;
  bool get sessionExpiredNotice => _sessionExpiredNotice;

  // Student Profile Getters
  String get studentFirstName => _studentFirstName.isNotEmpty ? _studentFirstName : 'Student';
  String get studentMiddleName => _studentMiddleName;
  String get studentSurname => _studentSurname;
  String get studentBirthdate => _studentBirthdate;
  String get studentAge => _studentAge;
  String get studentEmail => _studentEmail;
  String get studentSemester => _studentSemester.isNotEmpty ? _studentSemester : '1st Semester';

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  // Setters
  Future<void> updateStudentProfile({
    required String firstName,
    required String middleName,
    required String surname,
    required String birthdate,
    required String age,
    required String email,
    required String course,
    required String year,
    required String semester,
  }) async {
    _studentFirstName = firstName;
    _studentMiddleName = middleName;
    _studentSurname = surname;
    _studentBirthdate = birthdate;
    _studentAge = age;
    _studentEmail = email;
    _activeCourse = course;
    _activeYear = year;
    _studentSemester = semester;
    _activeSemester = semester;
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
    await prefs.setString('student_semester', semester);
    await prefs.setInt('student_profile_updated_at', DateTime.now().millisecondsSinceEpoch);

    // Save profile snapshot under email key for multi-account/persistent retrieval
    if (email.isNotEmpty) {
      final sanitizedEmail = email.toLowerCase().trim();
      final profileMap = {
        'firstName': firstName,
        'middleName': middleName,
        'surname': surname,
        'birthdate': birthdate,
        'age': age,
        'email': email,
        'course': course,
        'year': year,
        'semester': semester,
        'updatedAt': DateTime.now().toIso8601String(),
      };
      await prefs.setString('user_profile_$sanitizedEmail', json.encode(profileMap));
    }

    NativeService.syncNativeWidgetData(this);

    // Sync to Firebase Realtime Database
    _syncProfileToFirebase(
      firstName: firstName,
      middleName: middleName,
      surname: surname,
      birthdate: birthdate,
      age: age,
      email: email,
      course: course,
      year: year,
      semester: semester,
    );
  }

  // Firebase Realtime Database Sync
  Future<void> _syncProfileToFirebase({
    required String firstName,
    required String middleName,
    required String surname,
    required String birthdate,
    required String age,
    required String email,
    required String course,
    required String year,
    required String semester,
  }) async {
    if (email.isEmpty) return;
    try {
      final sanitizedKey = email.replaceAll(RegExp(r'[.#$\[\]]'), '_');
      final uri = Uri.parse('https://schedly-751cb-default-rtdb.firebaseio.com/users/$sanitizedKey.json');
      
      final client = HttpClient();
      final request = await client.patchUrl(uri);
      request.headers.contentType = ContentType.json;
      
      final body = json.encode({
        'firstName': firstName,
        'middleName': middleName,
        'surname': surname,
        'birthdate': birthdate,
        'age': age,
        'email': email,
        'course': course,
        'year': year,
        'semester': semester,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      
      request.write(body);
      final response = await request.close();
      await response.drain();
      client.close();
    } catch (_) {}
  }

  Future<void> _fetchProfileFromFirebase(String email) async {
    if (email.isEmpty) return;
    try {
      final sanitizedKey = email.replaceAll(RegExp(r'[.#$\[\]]'), '_');
      final uri = Uri.parse('https://schedly-751cb-default-rtdb.firebaseio.com/users/$sanitizedKey.json');
      
      final client = HttpClient();
      final request = await client.getUrl(uri);
      final response = await request.close();
      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        if (responseBody != 'null' && responseBody.isNotEmpty) {
          final data = json.decode(responseBody);
          if (data is Map<String, dynamic>) {
            bool changed = false;
            if (data['firstName'] != null && data['firstName'].toString().isNotEmpty && (_studentFirstName.isEmpty || _studentFirstName == 'Student')) {
              _studentFirstName = data['firstName'];
              changed = true;
            }
            if (data['middleName'] != null && data['middleName'].toString().isNotEmpty && _studentMiddleName.isEmpty) {
              _studentMiddleName = data['middleName'];
              changed = true;
            }
            if (data['surname'] != null && data['surname'].toString().isNotEmpty && _studentSurname.isEmpty) {
              _studentSurname = data['surname'];
              changed = true;
            }
            if (data['birthdate'] != null && data['birthdate'].toString().isNotEmpty && _studentBirthdate.isEmpty) {
              _studentBirthdate = data['birthdate'];
              changed = true;
            }
            if (data['age'] != null && data['age'].toString().isNotEmpty && _studentAge.isEmpty) {
              _studentAge = data['age'];
              changed = true;
            }
            if (data['course'] != null && data['course'].toString().isNotEmpty && _activeCourse.isEmpty) {
              _activeCourse = data['course'];
              changed = true;
            }
            if (data['year'] != null && data['year'].toString().isNotEmpty && _activeYear.isEmpty) {
              _activeYear = data['year'];
              changed = true;
            }
            if (data['semester'] != null && data['semester'].toString().isNotEmpty && _studentSemester.isEmpty) {
              _studentSemester = data['semester'];
              _activeSemester = _studentSemester;
              changed = true;
            }
            if (changed) {
              notifyListeners();
            }
          }
        }
      }
      client.close();
    } catch (_) {}
  }

  void clearStudentProfile() async {
    _studentFirstName = '';
    _studentMiddleName = '';
    _studentSurname = '';
    _studentBirthdate = '';
    _studentAge = '';
    _studentEmail = '';
    _studentSemester = '1st Semester';
    _activeCourse = '';
    _activeYear = '';
    _isLoggedIn = false;
    _lastActiveTimestamp = 0;
    _activeSessions.clear();
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_logged_in', false);
    await prefs.remove('last_active_timestamp');
    await prefs.remove('student_firstName');
    await prefs.remove('student_middleName');
    await prefs.remove('student_surname');
    await prefs.remove('student_birthdate');
    await prefs.remove('student_age');
    await prefs.remove('student_email');
    await prefs.remove('student_course');
    await prefs.remove('student_year');
    await prefs.remove('student_semester');
  }

  void updateActiveDetails({
    String? schoolYear,
    String? semester,
    String? course,
    String? year,
    String? section,
  }) {
    if (schoolYear != null) _activeSchoolYear = schoolYear;
    if (semester != null) _activeSemester = semester;
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

  void setCustomBgImagePath(String? path) {
    _customBgImagePath = path;
    notifyListeners();
  }

  // Widget Preferences
  void updateWidgetPreferences({
    String? size,
    String? bgStyle,
    bool? showTime,
    bool? showRoom,
    bool? showProfessor,
  }) async {
    if (size != null) _widgetSize = size;
    if (bgStyle != null) _widgetBgStyle = bgStyle;
    if (showTime != null) _showWidgetTime = showTime;
    if (showRoom != null) _showWidgetRoom = showRoom;
    if (showProfessor != null) _showWidgetProfessor = showProfessor;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('widget_size', _widgetSize);
    await prefs.setString('widget_bg_style', _widgetBgStyle);
    await prefs.setBool('widget_show_time', _showWidgetTime);
    await prefs.setBool('widget_show_room', _showWidgetRoom);
    await prefs.setBool('widget_show_professor', _showWidgetProfessor);
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
    NativeService.syncNativeWidgetData(this);
  }

  void updateSession(ClassSession updatedSession) {
    final index = _activeSessions.indexWhere((s) => s.id == updatedSession.id);
    if (index != -1) {
      _activeSessions[index] = updatedSession;
      notifyListeners();
      NativeService.syncNativeWidgetData(this);
    }
  }

  void deleteSession(String id) {
    _activeSessions.removeWhere((s) => s.id == id);
    notifyListeners();
    NativeService.syncNativeWidgetData(this);
  }

  void clearActiveSessions() {
    _activeScheduleId = null;
    _activeSessions.clear();
    notifyListeners();
    NativeService.syncNativeWidgetData(this);
  }

  // Save current active schedule to history / collection
  Future<void> saveCurrentToHistory() async {
    if (_activeSessions.isEmpty) return;

    final newId = DateTime.now().millisecondsSinceEpoch.toString();
    final newItem = ScheduleHistoryItem(
      id: newId,
      schoolYear: _activeSchoolYear,
      semester: _activeSemester,
      course: _activeCourse,
      year: _activeYear,
      section: _activeSection,
      sessions: List<ClassSession>.from(_activeSessions),
      themeStyle: _exportThemeStyle,
      bgColors: [_exportBgColorStartIndex, _exportBgColorEndIndex],
      createdAt: DateTime.now(),
    );

    _activeScheduleId = newId;
    // Remove if duplicate ID
    _history.removeWhere((item) => item.id == newItem.id);
    // Add to top of the history list
    _history.insert(0, newItem);
    notifyListeners();

    await saveHistoryToPrefs();
  }

  // Load a schedule from history to active workspace
  void loadHistoryItem(ScheduleHistoryItem item) {
    _activeScheduleId = item.id;
    _activeSchoolYear = item.schoolYear;
    _activeSemester = item.semester;
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
    NativeService.syncNativeWidgetData(this);
  }

  // Helper to check if history item matches active sessions
  bool _hasMatchingSessions(ScheduleHistoryItem item) {
    if (_activeSessions.length != item.sessions.length) return false;
    for (int i = 0; i < _activeSessions.length; i++) {
      if (_activeSessions[i].subjectCode != item.sessions[i].subjectCode ||
          _activeSessions[i].dayOfWeek != item.sessions[i].dayOfWeek ||
          _activeSessions[i].startTime != item.sessions[i].startTime) {
        return false;
      }
    }
    return true;
  }

  // Delete a history item and update active workspace/calendar accordingly
  Future<void> deleteHistoryItem(String id) async {
    final bool isCurrentActive = (_activeScheduleId == id) ||
        (_history.length == 1 && _history.first.id == id) ||
        (_activeSessions.isNotEmpty && _history.any((item) => item.id == id && _hasMatchingSessions(item)));

    _history.removeWhere((item) => item.id == id);

    if (isCurrentActive) {
      if (_history.isNotEmpty) {
        // Automatically switch to the next available schedule in history
        loadHistoryItem(_history.first);
      } else {
        // All schedules removed: clear active sessions, calendar, and native widgets
        _activeScheduleId = null;
        _activeSessions.clear();
        notifyListeners();
        NativeService.syncNativeWidgetData(this);
      }
    } else {
      notifyListeners();
    }

    await saveHistoryToPrefs();
  }

  // Auth Actions
  Future<void> loginUser(String email, bool rememberMe) async {
    _isLoggedIn = true;
    _studentEmail = email.trim();
    _rememberMe = rememberMe;
    _savedEmail = rememberMe ? email.trim() : '';
    _lastActiveTimestamp = DateTime.now().millisecondsSinceEpoch;
    _sessionExpiredNotice = false;
    _hasSeenOnboarding = true;

    final prefs = await SharedPreferences.getInstance();

    // Check if there is an existing saved profile for this user
    final sanitizedEmail = email.toLowerCase().trim();
    final cachedProfileJson = prefs.getString('user_profile_$sanitizedEmail');
    if (cachedProfileJson != null && cachedProfileJson.isNotEmpty) {
      try {
        final profileData = json.decode(cachedProfileJson);
        if (profileData is Map<String, dynamic>) {
          if (profileData['firstName'] != null && profileData['firstName'].toString().isNotEmpty) {
            _studentFirstName = profileData['firstName'];
          }
          if (profileData['middleName'] != null) _studentMiddleName = profileData['middleName'];
          if (profileData['surname'] != null) _studentSurname = profileData['surname'];
          if (profileData['birthdate'] != null) _studentBirthdate = profileData['birthdate'];
          if (profileData['age'] != null) _studentAge = profileData['age'];
          if (profileData['course'] != null && profileData['course'].toString().isNotEmpty) {
            _activeCourse = profileData['course'];
          }
          if (profileData['year'] != null && profileData['year'].toString().isNotEmpty) {
            _activeYear = profileData['year'];
          }
          if (profileData['semester'] != null && profileData['semester'].toString().isNotEmpty) {
            _studentSemester = profileData['semester'];
            _activeSemester = _studentSemester;
          }
        }
      } catch (_) {}
    } else {
      // Check general SharedPreferences
      final savedFirstName = prefs.getString('student_firstName');
      if (savedFirstName != null && savedFirstName.isNotEmpty && savedFirstName != 'Student') {
        _studentFirstName = savedFirstName;
        _studentMiddleName = prefs.getString('student_middleName') ?? _studentMiddleName;
        _studentSurname = prefs.getString('student_surname') ?? _studentSurname;
        _studentBirthdate = prefs.getString('student_birthdate') ?? _studentBirthdate;
        _studentAge = prefs.getString('student_age') ?? _studentAge;
        _activeCourse = prefs.getString('student_course') ?? _activeCourse;
        _activeYear = prefs.getString('student_year') ?? _activeYear;
        _studentSemester = prefs.getString('student_semester') ?? _studentSemester;
        _activeSemester = _studentSemester;
      } else if (_studentFirstName.isEmpty || _studentFirstName == 'Student') {
        _studentFirstName = email.split('@').first;
      }
    }

    // Load per-user history if exists
    final userHistoryKey = 'schedule_history_$sanitizedEmail';
    if (prefs.containsKey(userHistoryKey)) {
      final userHistoryJson = prefs.getString(userHistoryKey);
      if (userHistoryJson != null) {
        try {
          final List<dynamic> decoded = json.decode(userHistoryJson);
          _history = decoded.map((x) => ScheduleHistoryItem.fromMap(x)).toList();
        } catch (_) {
          _history = [];
        }
      } else {
        _history = [];
      }
      if (_history.isNotEmpty) {
        loadHistoryItem(_history.first);
      } else {
        _activeScheduleId = null;
        _activeSessions.clear();
      }
    }

    notifyListeners();

    await prefs.setBool('is_logged_in', true);
    await prefs.setBool('has_seen_onboarding', true);
    await prefs.setInt('last_active_timestamp', _lastActiveTimestamp);
    await prefs.setBool('remember_me', rememberMe);
    await prefs.setString('saved_email', _savedEmail);
    await prefs.setString('student_email', _studentEmail);
    await prefs.setString('student_firstName', _studentFirstName);
    await prefs.setString('student_middleName', _studentMiddleName);
    await prefs.setString('student_surname', _studentSurname);
    await prefs.setString('student_birthdate', _studentBirthdate);
    await prefs.setString('student_age', _studentAge);
    await prefs.setString('student_course', _activeCourse);
    await prefs.setString('student_year', _activeYear);
    await prefs.setString('student_semester', _studentSemester);

    _fetchProfileFromFirebase(_studentEmail);
  }

  Future<void> logoutUser() async {
    _isLoggedIn = false;
    _lastActiveTimestamp = 0;
    _sessionExpiredNotice = false;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_logged_in', false);
    await prefs.remove('last_active_timestamp');
    if (!_rememberMe) {
      await prefs.remove('saved_email');
    }
  }

  Future<void> markOnboardingCompleted() async {
    _hasSeenOnboarding = true;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_onboarding', true);
  }

  void touchActivity() async {
    if (!_isLoggedIn) return;
    _lastActiveTimestamp = DateTime.now().millisecondsSinceEpoch;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('last_active_timestamp', _lastActiveTimestamp);
  }

  void clearSessionExpiredNotice() {
    _sessionExpiredNotice = false;
    notifyListeners();
  }

  // Shared Preferences logic
  Future<void> loadSettingsFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load Dark Mode
    final isDark = prefs.getBool('isDarkMode') ?? false;
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;

    // Load Auth & Onboarding State
    _hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;
    _rememberMe = prefs.getBool('remember_me') ?? false;
    _savedEmail = prefs.getString('saved_email') ?? '';
    _isLoggedIn = prefs.getBool('is_logged_in') ?? false;
    _lastActiveTimestamp = prefs.getInt('last_active_timestamp') ?? 0;

    // 5-Day Inactivity Check (5 days = 5 * 24 * 60 * 60 * 1000 ms = 432,000,000 ms)
    if (_isLoggedIn) {
      final now = DateTime.now().millisecondsSinceEpoch;
      const fiveDaysInMillis = 5 * 24 * 60 * 60 * 1000;
      if (_lastActiveTimestamp > 0 && (now - _lastActiveTimestamp) >= fiveDaysInMillis) {
        _isLoggedIn = false;
        _sessionExpiredNotice = true;
        await prefs.setBool('is_logged_in', false);
      } else {
        _lastActiveTimestamp = now;
        await prefs.setInt('last_active_timestamp', now);
      }
    }

    // Load Student Profile
    _studentFirstName = prefs.getString('student_firstName') ?? '';
    _studentMiddleName = prefs.getString('student_middleName') ?? '';
    _studentSurname = prefs.getString('student_surname') ?? '';
    _studentBirthdate = prefs.getString('student_birthdate') ?? '';
    _studentAge = prefs.getString('student_age') ?? '';
    _studentEmail = prefs.getString('student_email') ?? (_rememberMe ? _savedEmail : '');
    _studentSemester = prefs.getString('student_semester') ?? '1st Semester';
    _activeCourse = prefs.getString('student_course') ?? _activeCourse;
    _activeYear = prefs.getString('student_year') ?? _activeYear;
    _activeSemester = _studentSemester;

    if (_studentEmail.isNotEmpty) {
      final sanitizedEmail = _studentEmail.toLowerCase().trim();
      final cachedProfileJson = prefs.getString('user_profile_$sanitizedEmail');
      if (cachedProfileJson != null && cachedProfileJson.isNotEmpty) {
        try {
          final profileData = json.decode(cachedProfileJson);
          if (profileData is Map<String, dynamic>) {
            if (_studentFirstName.isEmpty && profileData['firstName'] != null) {
              _studentFirstName = profileData['firstName'];
            }
            if (_studentMiddleName.isEmpty && profileData['middleName'] != null) {
              _studentMiddleName = profileData['middleName'];
            }
            if (_studentSurname.isEmpty && profileData['surname'] != null) {
              _studentSurname = profileData['surname'];
            }
            if (_studentBirthdate.isEmpty && profileData['birthdate'] != null) {
              _studentBirthdate = profileData['birthdate'];
            }
            if (_studentAge.isEmpty && profileData['age'] != null) {
              _studentAge = profileData['age'];
            }
            if (profileData['course'] != null && profileData['course'].toString().isNotEmpty) {
              _activeCourse = profileData['course'];
            }
            if (profileData['year'] != null && profileData['year'].toString().isNotEmpty) {
              _activeYear = profileData['year'];
            }
            if (profileData['semester'] != null && profileData['semester'].toString().isNotEmpty) {
              _studentSemester = profileData['semester'];
              _activeSemester = _studentSemester;
            }
          }
        } catch (_) {}
      }
      _fetchProfileFromFirebase(_studentEmail);
    }

    // Load Widget settings
    _widgetSize = prefs.getString('widget_size') ?? _widgetSize;
    _widgetBgStyle = prefs.getString('widget_bg_style') ?? _widgetBgStyle;
    _showWidgetTime = prefs.getBool('widget_show_time') ?? _showWidgetTime;
    _showWidgetRoom = prefs.getBool('widget_show_room') ?? _showWidgetRoom;
    _showWidgetProfessor = prefs.getBool('widget_show_professor') ?? _showWidgetProfessor;

    // Load History
    final historyJson = prefs.getString('schedule_history');
    if (historyJson != null) {
      try {
        final List<dynamic> decoded = json.decode(historyJson);
        _history = decoded.map((x) => ScheduleHistoryItem.fromMap(x)).toList();
      } catch (e) {
        _history = [];
      }
    }

    final hasInitializedDefault = prefs.getBool('has_initialized_default') ?? false;

    // If active sessions are empty and history has items, load the first history item
    if (_activeSessions.isEmpty && _history.isNotEmpty) {
      loadHistoryItem(_history.first);
    } else if (_activeSessions.isEmpty && _history.isEmpty && !hasInitializedDefault && !_hasSeenOnboarding) {
      // Create initial starter sample schedule only on very first app run
      _populateDefaultInitialSchedule();
      await prefs.setBool('has_initialized_default', true);
      await saveHistoryToPrefs();
    }

    _isInitialized = true;
    notifyListeners();
    NativeService.syncNativeWidgetData(this);
  }

  void _populateDefaultInitialSchedule() {
    final mockSessions = _createStandardMockSessions();
    _activeSessions = List<ClassSession>.from(mockSessions);
    _activeCourse = 'BS Information Technology';
    _activeYear = '4th Year';
    _activeSemester = '1st Semester';
    _activeSchoolYear = 'S.Y. 2026-2027';
    _activeSection = 'Section A';

    final initialHistory = ScheduleHistoryItem(
      id: 'default_initial_1',
      schoolYear: _activeSchoolYear,
      semester: _activeSemester,
      course: _activeCourse,
      year: _activeYear,
      section: _activeSection,
      sessions: List<ClassSession>.from(mockSessions),
      themeStyle: 'Sticker Template',
      bgColors: [0, 1],
      createdAt: DateTime.now(),
    );
    _history.add(initialHistory);
  }

  List<ClassSession> _createStandardMockSessions() {
    return [
      ClassSession(
        id: '1',
        subjectName: 'The Contemporary World',
        subjectCode: 'GECONTWO',
        room: 'Rm 302',
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
        room: 'CL 4',
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
        room: 'CL 2',
        instructor: 'LAGDA, LAGDA',
        dayOfWeek: 'Tuesday',
        startTime: '07:00 AM',
        endTime: '10:00 AM',
        colorValue: 0xFFFFB703,
      ),
      ClassSession(
        id: '4',
        subjectName: 'IT Capstone Project & Thesis 2',
        subjectCode: 'ITTHESI2',
        room: 'Rm 405',
        instructor: 'Anuncio, Hazel',
        dayOfWeek: 'Tuesday',
        startTime: '12:00 PM',
        endTime: '02:00 PM',
        colorValue: 0xFF4ECDC4,
      ),
      ClassSession(
        id: '5',
        subjectName: 'Systems Architecture & Integration 2',
        subjectCode: 'SYSARCH2',
        room: 'Rm 208',
        instructor: 'Sison, Edgardo',
        dayOfWeek: 'Tuesday',
        startTime: '06:00 PM',
        endTime: '08:00 PM',
        colorValue: 0xFF9D4EDD,
      ),
      ClassSession(
        id: '6',
        subjectName: 'Information Assurance & Security 2 Lecture',
        subjectCode: 'IAASLEC2',
        room: 'Rm 301',
        instructor: 'LAGDA, LAGDA',
        dayOfWeek: 'Thursday',
        startTime: '07:00 AM',
        endTime: '09:00 AM',
        colorValue: 0xFFFFB703,
      ),
      ClassSession(
        id: '7',
        subjectName: 'System Administration & Maintenance Lecture',
        subjectCode: 'SYSADMLC',
        room: 'Rm 304',
        instructor: 'Sison, Edgardo',
        dayOfWeek: 'Thursday',
        startTime: '10:00 AM',
        endTime: '12:00 PM',
        colorValue: 0xFFE27396,
      ),
      ClassSession(
        id: '8',
        subjectName: 'The Contemporary World',
        subjectCode: 'GECONTWO',
        room: 'Rm 302',
        instructor: 'LAGDA, LAGDA',
        dayOfWeek: 'Thursday',
        startTime: '01:00 PM',
        endTime: '02:30 PM',
        colorValue: 0xFF8E94F2,
      ),
      ClassSession(
        id: '9',
        subjectName: 'IT Capstone Project & Thesis 2 Lab',
        subjectCode: 'ITTHESL2',
        room: 'CL 3',
        instructor: 'Anuncio, Hazel',
        dayOfWeek: 'Thursday',
        startTime: '03:00 PM',
        endTime: '06:00 PM',
        colorValue: 0xFF4ECDC4,
      ),
      ClassSession(
        id: '10',
        subjectName: 'Social & Professional Issues in Computing',
        subjectCode: 'SPISSUES',
        room: 'Rm 502',
        instructor: 'LAGDA, LAGDA',
        dayOfWeek: 'Thursday',
        startTime: '06:00 PM',
        endTime: '09:00 PM',
        colorValue: 0xFF9D4EDD,
      ),
    ];
  }

  Future<void> saveHistoryToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final historyListMap = _history.map((x) => x.toMap()).toList();
    final historyJson = json.encode(historyListMap);
    await prefs.setString('schedule_history', historyJson);
    await prefs.setBool('has_initialized_default', true);

    if (_studentEmail.isNotEmpty) {
      final sanitizedEmail = _studentEmail.toLowerCase().trim();
      await prefs.setString('schedule_history_$sanitizedEmail', historyJson);
      await prefs.setBool('user_history_initialized_$sanitizedEmail', true);
    }
  }

  // OCR Parsing Simulation & Accurate Academic Profile Auto-Population
  Future<CorScanResult> simulateOcrScan(String filePath, {String scanType = 'scan'}) async {
    // High-accuracy COR OCR and multi-modal document extraction
    final scanResult = await CorParserService.parseCorDocument(
      filePath: filePath,
      scanType: scanType,
      currentFirstName: _studentFirstName,
      currentMiddleName: _studentMiddleName,
      currentSurname: _studentSurname,
      currentBirthdate: _studentBirthdate,
      currentAge: _studentAge,
      currentEmail: _studentEmail,
      currentCourse: _activeCourse,
      currentYear: _activeYear,
      currentSemester: _activeSemester,
    );

    // Clear previous sessions and load freshly extracted accurate sessions
    _activeSessions.clear();
    _activeSessions.addAll(scanResult.sessions);

    // Synchronize extracted academic metadata
    _activeCourse = scanResult.course;
    _activeYear = scanResult.yearLevel;
    _activeSemester = scanResult.semester;
    _activeSchoolYear = scanResult.schoolYear;
    _activeSection = scanResult.section;
    _studentSemester = _activeSemester;

    if (scanResult.isOfficialCorComplete) {
      // Official COR document: Auto-populates ALL personal & academic info in Edit Profile
      await updateStudentProfile(
        firstName: scanResult.studentFirstName,
        middleName: scanResult.studentMiddleName,
        surname: scanResult.studentSurname,
        birthdate: scanResult.birthdate,
        age: scanResult.age,
        email: scanResult.email.isNotEmpty ? scanResult.email : _studentEmail,
        course: _activeCourse,
        year: _activeYear,
        semester: _activeSemester,
      );
    } else {
      // Camera photo or image screenshot: update academic program/section,
      // keep existing profile info without forcing defaults so user completes in Edit Profile.
      await updateStudentProfile(
        firstName: _studentFirstName,
        middleName: _studentMiddleName,
        surname: _studentSurname,
        birthdate: _studentBirthdate,
        age: _studentAge,
        email: _studentEmail,
        course: _activeCourse,
        year: _activeYear,
        semester: _activeSemester,
      );
    }

    notifyListeners();
    NativeService.syncNativeWidgetData(this);
    return scanResult;
  }
}

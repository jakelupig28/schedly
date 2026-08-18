import 'package:flutter/material';
import 'package:provider/provider';
import '../providers/schedule_provider.dart';
import '../models/schedule.dart';
import '../theme/app_theme.dart';
import 'schedule_parser_screen.dart';
import 'schedule_exporter_screen.dart';
import 'history_screen.dart';
import 'onboarding_screen.dart';
import '../widgets/mock_widget_preview.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

  final List<String> _motivationalQuotes = [
    "The secret of getting ahead is getting started. 🚀",
    "Focus on progress, not perfection. ✨",
    "Your future is created by what you do today! 📚",
    "Believe you can and you're halfway there. 💪",
    "Make today your masterpiece. 🎨",
  ];
  late String _activeQuote;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _activeQuote = _motivationalQuotes[DateTime.now().second % _motivationalQuotes.length];
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ScheduleProvider>(context);
    final theme = Theme.of(context);
    final sessions = provider.activeSessions;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Schedly"),
        actions: [
          IconButton(
            icon: Icon(
              provider.isDarkMode ? Icons.wb_sunny_rounded : Icons.nightlight_round,
              color: provider.isDarkMode ? Colors.amber : theme.colorScheme.primary,
            ),
            onPressed: () {
              provider.toggleTheme(!provider.isDarkMode);
            },
            tooltip: "Toggle Theme",
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            // Simulated reload
            await Future.delayed(const Duration(milliseconds: 500));
            setState(() {
              _activeQuote = _motivationalQuotes[DateTime.now().second % _motivationalQuotes.length];
            });
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Motivational / Welcome Card
                _buildWelcomeCard(theme, provider),
                const SizedBox(height: 24),

                // Quick Navigation Grid
                Text(
                  "Quick Actions",
                  style: theme.textTheme.titleLarge?.copyWith(fontSize: 18),
                ),
                const SizedBox(height: 12),
                _buildQuickActions(context, theme, sessions.isNotEmpty),
                const SizedBox(height: 28),

                // Active Schedule Header and Tabs
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Schedule Planner",
                      style: theme.textTheme.titleLarge?.copyWith(fontSize: 18),
                    ),
                    if (sessions.isNotEmpty)
                      Chip(
                        label: Text(
                          "${provider.activeYear} • ${provider.activeSection}",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                        side: BorderSide.none,
                        padding: EdgeInsets.zero,
                      ),
                  ],
                ),
                const SizedBox(height: 8),

                if (sessions.isEmpty)
                  _buildEmptyStateCard(context, theme)
                else ...[
                  TabBar(
                    controller: _tabController,
                    indicatorColor: theme.colorScheme.primary,
                    labelColor: theme.colorScheme.primary,
                    unselectedLabelColor: theme.textTheme.bodyMedium?.color,
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                    tabs: const [
                      Tab(text: "Today"),
                      Tab(text: "Weekly Calendar"),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 380,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildTodayClasses(theme, sessions),
                        _buildWeeklyCalendar(theme, sessions),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeCard(ThemeData theme, ScheduleProvider provider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: provider.isDarkMode 
              ? [const Color(0xFF2E2B5C), const Color(0xFF1E1A3C)]
              : [const Color(0xFFE8E7FF), const Color(0xFFC7C4FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Hello, ${provider.studentFirstName}!",
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: provider.isDarkMode ? Colors.white : const Color(0xFF2D2E49),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    provider.activeCourse,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 14,
                      color: provider.isDarkMode ? Colors.white70 : const Color(0xFF5D5F7E),
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () => _showProfileDialog(context, provider),
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center, // Strictly center the child icon
                  child: Icon(
                    Icons.person_rounded, // Changed to profile icon
                    color: theme.colorScheme.primary,
                    size: 26,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 24, thickness: 1, color: Colors.white24),
          Row(
            children: [
              const Icon(Icons.lightbulb_outline_rounded, color: Colors.amber, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _activeQuote,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                    fontSize: 13,
                    color: provider.isDarkMode ? Colors.white60 : const Color(0xFF5D5F7E),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, ThemeData theme, bool hasSchedule) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildActionCard(
          theme,
          icon: Icons.add_photo_alternate_rounded,
          title: "Upload & Scan",
          subtitle: "Import new COR",
          color: const Color(0xFF6C63FF),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ScheduleParserScreen()),
            );
          },
        ),
        _buildActionCard(
          theme,
          icon: Icons.palette_rounded,
          title: "Customize & Save",
          subtitle: "Export wallpaper",
          color: const Color(0xFFFF6584),
          onTap: hasSchedule ? () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ScheduleExporterScreen()),
            );
          } : () => _showNoScheduleSnackbar(context),
        ),
        _buildActionCard(
          theme,
          icon: Icons.history_rounded,
          title: "Schedule History",
          subtitle: "Past semesters",
          color: const Color(0xFF4ECDC4),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HistoryScreen()),
            );
          },
        ),
        _buildActionCard(
          theme,
          icon: Icons.widgets_rounded,
          title: "Homescreen Widget",
          subtitle: "Widget simulator",
          color: const Color(0xFFFFB703),
          onTap: hasSchedule ? () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MockWidgetPreview()),
            );
          } : () => _showNoScheduleSnackbar(context),
        ),
      ],
    );
  }

  Widget _buildActionCard(
    ThemeData theme, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = theme.brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? color.withOpacity(0.12) : color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? color.withOpacity(0.3) : color.withOpacity(0.2),
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  subtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 11,
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyStateCard(BuildContext context, ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
        child: Column(
          children: [
            Icon(
              Icons.calendar_today_rounded,
              size: 64,
              color: theme.colorScheme.primary.withOpacity(0.4),
            ),
            const SizedBox(height: 16),
            Text(
              "No Active Schedule Yet",
              style: theme.textTheme.titleLarge?.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              "To generate, customize, and export your weekly planner, please scan or upload your Certificate of Registration.",
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ScheduleParserScreen()),
                );
              },
              icon: const Icon(Icons.camera_alt_rounded),
              label: const Text("Scan Your Schedule"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayClasses(ThemeData theme, List<ClassSession> sessions) {
    // Determine the current day of the week
    final int weekdayIndex = DateTime.now().weekday; // 1 = Monday, 7 = Sunday
    final String currentDay = _days[weekdayIndex - 1];
    
    final todaySessions = sessions.where((s) => s.dayOfWeek.toLowerCase() == currentDay.toLowerCase()).toList();

    // Sort sessions by start time
    todaySessions.sort((a, b) => a.startTime.compareTo(b.startTime));

    if (todaySessions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.weekend_rounded,
              size: 48,
              color: theme.colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 12),
            Text(
              "Rest Day! No classes today.",
              style: theme.textTheme.titleLarge?.copyWith(fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              "Enjoy your break or review your notes.",
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: todaySessions.length,
      itemBuilder: (context, index) {
        final session = todaySessions[index];
        final cardColor = Color(session.colorValue);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Color strip on left
                Container(
                  width: 6,
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      bottomLeft: Radius.circular(20),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                session.subjectName,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: cardColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                session.subjectCode,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: cardColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.access_time_rounded, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              "${session.startTime} - ${session.endTime}",
                              style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.room_rounded, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              session.room,
                              style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
                            ),
                            const SizedBox(width: 16),
                            const Icon(Icons.person_rounded, size: 14),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                session.instructor,
                                style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWeeklyCalendar(ThemeData theme, List<ClassSession> sessions) {
    return DefaultTabController(
      length: _days.length,
      child: Column(
        children: [
          // Miniature days tab bar
          TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicatorSize: TabBarIndicatorSize.label,
            labelPadding: const EdgeInsets.symmetric(horizontal: 16),
            tabs: _days.map((day) => Tab(text: day.substring(0, 3))).toList(),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: TabBarView(
              children: _days.map((day) {
                final daySessions = sessions.where((s) => s.dayOfWeek.toLowerCase() == day.toLowerCase()).toList();
                daySessions.sort((a, b) => a.startTime.compareTo(b.startTime));

                if (daySessions.isEmpty) {
                  return Center(
                    child: Text(
                      "No classes scheduled for $day.",
                      style: theme.textTheme.bodyMedium,
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const ClampingScrollPhysics(),
                  itemCount: daySessions.length,
                  itemBuilder: (context, index) {
                    final session = daySessions[index];
                    final cardColor = Color(session.colorValue);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: cardColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        title: Text(
                          session.subjectName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        subtitle: Text(
                          "${session.startTime} - ${session.endTime} | Room: ${session.room} | Prof: ${session.instructor}",
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: Text(
                          session.subjectCode,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: cardColor,
                          ),
                        ),
                      ),
                    );
                  },
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  void _showNoScheduleSnackbar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Please upload a Certificate of Registration (CoR) first!"),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showProfileDialog(BuildContext context, ScheduleProvider provider) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return _ProfileEditDialog(provider: provider);
      },
    );
  }
}

class _ProfileEditDialog extends StatefulWidget {
  final ScheduleProvider provider;
  const _ProfileEditDialog({required this.provider});

  @override
  State<_ProfileEditDialog> createState() => _ProfileEditDialogState();
}

class _ProfileEditDialogState extends State<_ProfileEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstNameController;
  late TextEditingController _middleNameController;
  late TextEditingController _surnameController;
  late TextEditingController _birthdateController;
  late TextEditingController _ageController;
  late TextEditingController _emailController;
  late TextEditingController _courseController;
  late String _selectedYear;
  DateTime? _selectedBirthdate;

  final List<String> _years = ['1st Year', '2nd Year', '3rd Year', '4th Year', '5th Year+'];

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(
        text: widget.provider.studentFirstName == 'Student' ? '' : widget.provider.studentFirstName);
    _middleNameController = TextEditingController(text: widget.provider.studentMiddleName);
    _surnameController = TextEditingController(text: widget.provider.studentSurname);
    _birthdateController = TextEditingController(text: widget.provider.studentBirthdate);
    _ageController = TextEditingController(text: widget.provider.studentAge);
    _emailController = TextEditingController(text: widget.provider.studentEmail);
    _courseController = TextEditingController(text: widget.provider.activeCourse);
    _selectedYear = widget.provider.activeYear;

    if (widget.provider.studentBirthdate.isNotEmpty) {
      try {
        final parts = widget.provider.studentBirthdate.split('/');
        if (parts.length == 3) {
          _selectedBirthdate = DateTime(int.parse(parts[2]), int.parse(parts[0]), int.parse(parts[1]));
        }
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _middleNameController.dispose();
    _surnameController.dispose();
    _birthdateController.dispose();
    _ageController.dispose();
    _emailController.dispose();
    _courseController.dispose();
    super.dispose();
  }

  String _capitalize(String text) {
    if (text.trim().isEmpty) return '';
    return text.trim().split(RegExp(r'\s+')).map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  Future<void> _selectBirthdate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedBirthdate ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).brightness == Brightness.dark
                ? const ColorScheme.dark(
                    primary: Color(0xFF6C63FF),
                    onPrimary: Colors.white,
                    surface: Color(0xFF1F1C3F),
                    onSurface: Colors.white,
                  )
                : const ColorScheme.light(
                    primary: Color(0xFF6C63FF),
                    onPrimary: Colors.white,
                    surface: Colors.white,
                    onSurface: Colors.black,
                  ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedBirthdate = picked;
        _birthdateController.text = "${picked.month.toString().padLeft(2, '0')}/${picked.day.toString().padLeft(2, '0')}/${picked.year}";
        
        // Calculate age
        DateTime today = DateTime.now();
        int age = today.year - picked.year;
        if (today.month < picked.month || (today.month == picked.month && today.day < picked.day)) {
          age--;
        }
        _ageController.text = age.toString();
      });
    }
  }

  void _saveProfile() {
    if (_formKey.currentState!.validate()) {
      final fName = _capitalize(_firstNameController.text);
      final mName = _capitalize(_middleNameController.text);
      final lName = _capitalize(_surnameController.text);

      widget.provider.updateStudentProfile(
        firstName: fName,
        middleName: mName,
        surname: lName,
        birthdate: _birthdateController.text,
        age: _ageController.text,
        email: _emailController.text,
        course: _courseController.text,
        year: _selectedYear,
      );

      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Profile updated successfully!"),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _logout() {
    Navigator.of(context).pop();
    widget.provider.clearStudentProfile();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Logged out successfully!"),
      ),
    );
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      backgroundColor: isDark ? const Color(0xFF1F1C3F) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Edit Profile",
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // First Name
                TextFormField(
                  controller: _firstNameController,
                  textCapitalization: TextCapitalization.words,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                  decoration: const InputDecoration(
                    labelText: "First Name",
                    prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty ? "First name is required" : null,
                ),
                const SizedBox(height: 12),

                // Middle Name
                TextFormField(
                  controller: _middleNameController,
                  textCapitalization: TextCapitalization.words,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                  decoration: const InputDecoration(
                    labelText: "Middle Name",
                    prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                  ),
                ),
                const SizedBox(height: 12),

                // Surname
                TextFormField(
                  controller: _surnameController,
                  textCapitalization: TextCapitalization.words,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                  decoration: const InputDecoration(
                    labelText: "Surname",
                    prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty ? "Surname is required" : null,
                ),
                const SizedBox(height: 12),

                // Email
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                  decoration: const InputDecoration(
                    labelText: "Email Address",
                    prefixIcon: Icon(Icons.email_outlined, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return "Email is required";
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                      return "Enter a valid email address";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // Birthdate + Age Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        controller: _birthdateController,
                        readOnly: true,
                        style: TextStyle(color: isDark ? Colors.white : Colors.black),
                        decoration: const InputDecoration(
                          labelText: "Birthdate",
                          prefixIcon: Icon(Icons.cake_outlined, size: 20),
                          border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                        ),
                        onTap: _selectBirthdate,
                        validator: (value) => value == null || value.isEmpty ? "Required" : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _ageController,
                        keyboardType: TextInputType.number,
                        style: TextStyle(color: isDark ? Colors.white : Colors.black),
                        decoration: const InputDecoration(
                          labelText: "Age",
                          prefixIcon: Icon(Icons.calendar_today_outlined, size: 18),
                          border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) return "Required";
                          final parsedAge = int.tryParse(value);
                          if (parsedAge == null || parsedAge <= 0) return "Invalid";
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Course
                TextFormField(
                  controller: _courseController,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                  decoration: const InputDecoration(
                    labelText: "Course / Major",
                    prefixIcon: Icon(Icons.book_outlined, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty ? "Course is required" : null,
                ),
                const SizedBox(height: 12),

                // Year Level Dropdown
                DropdownButtonFormField<String>(
                  value: _selectedYear,
                  dropdownColor: isDark ? const Color(0xFF1F1C3F) : Colors.white,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                  decoration: const InputDecoration(
                    labelText: "Year Level",
                    prefixIcon: Icon(Icons.calendar_month_outlined, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                  ),
                  items: _years.map((year) {
                    return DropdownMenuItem(value: year, child: Text(year));
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedYear = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 24),

                // Save Profile Button
                ElevatedButton(
                  onPressed: _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Save Changes", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 12),

                // Logout Button
                OutlinedButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                  label: const Text("Logout", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                    side: const BorderSide(color: Colors.redAccent, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

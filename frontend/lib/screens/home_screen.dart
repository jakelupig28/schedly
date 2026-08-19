import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/schedule_provider.dart';
import '../models/schedule.dart';
import '../widgets/top_notification.dart';
import 'schedule_parser_screen.dart';
import 'schedule_exporter_screen.dart';
import 'history_screen.dart';
import 'onboarding_screen.dart';
import '../widgets/mock_widget_preview.dart';

class HomeScreen extends StatefulWidget {
  final bool showWelcomeBackDialog;
  const HomeScreen({super.key, this.showWelcomeBackDialog = false});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedNavIndex = 0;
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

    // Refresh activity on open
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<ScheduleProvider>(context, listen: false).touchActivity();
        if (widget.showWelcomeBackDialog) {
          _showWelcomeBackPopUp(context);
        }
      }
    });
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
    final isDark = theme.brightness == Brightness.dark;
    final sessions = provider.activeSessions;

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          IndexedStack(
            index: _selectedNavIndex,
            children: [
              _buildDashboard(context, theme, provider, sessions),
              const ScheduleParserScreen(),
              const ScheduleExporterScreen(),
              const HistoryScreen(),
            ],
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 16,
            child: SafeArea(
              top: false,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(36),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                  child: Container(
                    height: 66,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      // Pure floating glassmorphism capsule
                      color: isDark
                          ? const Color(0xFF1E1A3C).withValues(alpha: 0.70)
                          : Colors.white.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(36),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.25)
                            : Colors.white.withValues(alpha: 0.85),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.10),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildCapsuleNavItem(
                          index: 0,
                          icon: Icons.home_outlined,
                          activeIcon: Icons.home_rounded,
                          label: "Home",
                          isDark: isDark,
                        ),
                        _buildCapsuleNavItem(
                          index: 1,
                          icon: Icons.document_scanner_outlined,
                          activeIcon: Icons.document_scanner_rounded,
                          label: "Scan",
                          isDark: isDark,
                        ),
                        _buildCapsuleNavItem(
                          index: 2,
                          icon: Icons.palette_outlined,
                          activeIcon: Icons.palette_rounded,
                          label: "Export",
                          isDark: isDark,
                        ),
                        _buildCapsuleNavItem(
                          index: 3,
                          icon: Icons.history_rounded,
                          activeIcon: Icons.history_rounded,
                          label: "History",
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCapsuleNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required bool isDark,
  }) {
    final isSelected = _selectedNavIndex == index;
    const activeColor = Color(0xFF6C63FF);

    return InkWell(
      onTap: () {
        setState(() {
          _selectedNavIndex = index;
        });
      },
      borderRadius: BorderRadius.circular(26),
      splashColor: activeColor.withValues(alpha: 0.12),
      highlightColor: Colors.transparent,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 16 : 14,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withValues(alpha: isDark ? 0.32 : 0.18)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(26),
          border: isSelected
              ? Border.all(
                  color: activeColor.withValues(alpha: isDark ? 0.55 : 0.35),
                  width: 1.2,
                )
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              size: 22,
              color: isSelected
                  ? (isDark ? const Color(0xFF9D95FF) : activeColor)
                  : (isDark ? Colors.grey[300] : Colors.grey[700]),
            ),
            if (isSelected) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: isDark ? const Color(0xFF9D95FF) : activeColor,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDashboard(BuildContext context, ThemeData theme, ScheduleProvider provider, List<ClassSession> sessions) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          "Schedly",
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.8,
            color: theme.colorScheme.primary,
          ),
        ),
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
            await Future.delayed(const Duration(milliseconds: 500));
            setState(() {
              _activeQuote = _motivationalQuotes[DateTime.now().second % _motivationalQuotes.length];
            });
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 120.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Motivational / Welcome Card
                _buildWelcomeCard(theme, provider),
                const SizedBox(height: 24),

                // Quick Actions
                Text(
                  "Quick Actions",
                  style: theme.textTheme.titleLarge?.copyWith(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _buildQuickActions(context, theme, sessions.isNotEmpty),
                const SizedBox(height: 28),

                // My Collection Section
                _buildCollectionSection(context, theme, provider),
                const SizedBox(height: 28),

                // Active Schedule Header and Tabs
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Schedule Planner",
                      style: theme.textTheme.titleLarge?.copyWith(fontSize: 18, fontWeight: FontWeight.bold),
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
                        backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
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
                    dividerColor: Colors.transparent,
                    dividerHeight: 0,
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
                    height: 420,
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

  Widget _buildCollectionSection(BuildContext context, ThemeData theme, ScheduleProvider provider) {
    final historyList = provider.history;
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  "My Collection",
                  style: theme.textTheme.titleLarge?.copyWith(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [theme.colorScheme.primary, const Color(0xFF9D4EDD)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "${historyList.length}",
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedNavIndex = 3; // Open History Tab
                });
              },
              child: const Text("View All", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 10),

        if (historyList.isEmpty)
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF252147).withValues(alpha: 0.5) : const Color(0xFFF7F8FC),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: isDark ? Colors.white12 : Colors.grey[300]!),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.collections_bookmark_rounded, size: 28, color: theme.colorScheme.primary),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "No Saved Schedules",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        "Scan your COR to catalog your semester schedule.",
                        style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _selectedNavIndex = 1;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text("Scan", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          )
        else
          SizedBox(
            height: 126,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: historyList.length,
              itemBuilder: (context, idx) {
                final item = historyList[idx];
                final isCurrentActive = provider.activeCourse == item.course &&
                    provider.activeSchoolYear == item.schoolYear &&
                    provider.activeSemester == item.semester &&
                    provider.activeYear == item.year;

                return GestureDetector(
                  onTap: () {
                    _showScheduleDetailModal(context, provider, item);
                  },
                  child: Container(
                    width: 265,
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF252147) : Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isCurrentActive
                            ? theme.colorScheme.primary
                            : (isDark ? Colors.white12 : const Color(0xFFE8EAF2)),
                        width: isCurrentActive ? 2.0 : 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isCurrentActive
                              ? theme.colorScheme.primary.withValues(alpha: 0.18)
                              : Colors.black.withValues(alpha: isDark ? 0.35 : 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                "${item.semester} • ${item.schoolYear}",
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                            if (isCurrentActive)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981).withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(7),
                                  border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.check_circle, size: 9, color: Color(0xFF10B981)),
                                    SizedBox(width: 3),
                                    Text(
                                      "ACTIVE",
                                      style: TextStyle(
                                        fontSize: 8.5,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFF10B981),
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        Text(
                          item.course,
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13.5),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF3F4F8),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "${item.year} • ${item.sessions.length} Subjects",
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white70 : Colors.grey[700],
                                ),
                              ),
                              Text(
                                "${item.totalUnits} Units",
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
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
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.person_rounded,
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
            setState(() {
              _selectedNavIndex = 1;
            });
          },
        ),
        _buildActionCard(
          theme,
          icon: Icons.palette_rounded,
          title: "Customize & Save",
          subtitle: "Export wallpaper",
          color: const Color(0xFFFF6584),
          onTap: hasSchedule ? () {
            setState(() {
              _selectedNavIndex = 2;
            });
          } : () => _showNoScheduleSnackbar(context),
        ),
        _buildActionCard(
          theme,
          icon: Icons.history_rounded,
          title: "Schedule History",
          subtitle: "Past semesters",
          color: const Color(0xFF4ECDC4),
          onTap: () {
            setState(() {
              _selectedNavIndex = 3;
            });
          },
        ),
        _buildActionCard(
          theme,
          icon: Icons.widgets_rounded,
          title: "Homescreen Widget",
          subtitle: "Widget simulator",
          color: const Color(0xFFFFB703),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MockWidgetPreview()),
            );
          },
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
          color: isDark ? color.withValues(alpha: 0.12) : color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? color.withValues(alpha: 0.3) : color.withValues(alpha: 0.2),
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
                color: color.withValues(alpha: 0.2),
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
              color: theme.colorScheme.primary.withValues(alpha: 0.4),
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
    final int weekdayIndex = DateTime.now().weekday; // 1 = Monday, 7 = Sunday
    final String currentDay = _days[weekdayIndex - 1];

    final todaySessions = sessions.where((s) => s.dayOfWeek.toLowerCase() == currentDay.toLowerCase()).toList();
    todaySessions.sort((a, b) => a.startTime.compareTo(b.startTime));

    if (todaySessions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.weekend_rounded,
              size: 48,
              color: theme.colorScheme.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 12),
            Text(
              "Rest Day! No classes today ($currentDay).",
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
          child: InkWell(
            onTap: () => _showSubjectDetailModal(context, session, theme),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Clean rounded vertical color accent pill
                  Container(
                    width: 5,
                    height: 56,
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          session.subjectName,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
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
                            const SizedBox(width: 14),
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
                  const SizedBox(width: 10),
                  // Vertically & Horizontally centered Subject Code badge
                  Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: cardColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      session.subjectCode,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: cardColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildWeeklyCalendar(ThemeData theme, List<ClassSession> sessions) {
    final now = DateTime.now();
    // Monday of this week
    final mondayOfThisWeek = now.subtract(Duration(days: now.weekday - 1));
    final monthName = DateFormat('MMMM yyyy').format(now);

    return DefaultTabController(
      length: _days.length,
      initialIndex: now.weekday - 1, // Start on current day
      child: Column(
        children: [
          // Month Label Banner
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "📅 $monthName",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.primary,
                  ),
                ),
                Text(
                  "Week ${((now.day - 1) ~/ 7) + 1}",
                  style: TextStyle(fontSize: 12, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),

          // Days Tab Bar with Month Name & Date Numbers (No bottom divider)
          TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            dividerHeight: 0,
            indicator: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(16),
            ),
            labelColor: Colors.white,
            unselectedLabelColor: theme.textTheme.bodyMedium?.color,
            labelPadding: const EdgeInsets.symmetric(horizontal: 6),
            tabs: List.generate(_days.length, (idx) {
              final dateForDay = mondayOfThisWeek.add(Duration(days: idx));
              final dayShort = _days[idx].substring(0, 3).toUpperCase();
              final dayNum = dateForDay.day.toString();
              final isToday = now.day == dateForDay.day && now.month == dateForDay.month;

              return Tab(
                height: 52,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        dayShort,
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            dayNum,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
                          ),
                          if (isToday) ...[
                            const SizedBox(width: 2),
                            Container(
                              width: 4,
                              height: 4,
                              decoration: const BoxDecoration(
                                color: Colors.amber,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),

          Expanded(
            child: TabBarView(
              children: List.generate(_days.length, (idx) {
                final day = _days[idx];
                final dateForDay = mondayOfThisWeek.add(Duration(days: idx));
                final formattedFullDate = DateFormat('EEEE, MMMM d').format(dateForDay);

                final daySessions = sessions.where((s) => s.dayOfWeek.toLowerCase() == day.toLowerCase()).toList();
                daySessions.sort((a, b) => a.startTime.compareTo(b.startTime));

                if (daySessions.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.event_busy_rounded, size: 40, color: theme.colorScheme.primary.withValues(alpha: 0.3)),
                        const SizedBox(height: 8),
                        Text(
                          "No classes scheduled for $formattedFullDate",
                          style: theme.textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ],
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
                      child: InkWell(
                        onTap: () => _showSubjectDetailModal(context, session, theme),
                        borderRadius: BorderRadius.circular(20),
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
                      ),
                    );
                  },
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  void _showSubjectDetailModal(BuildContext context, ClassSession session, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = Color(session.colorValue);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: isDark ? const Color(0xFF1E1A3C) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // Header Badge & Code
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: cardColor.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: cardColor.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        session.subjectCode,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: cardColor,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Full Subject Name
                Text(
                  session.subjectName,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 20),

                // Details Grid / List
                _buildSubjectDetailRow(
                  icon: Icons.calendar_today_rounded,
                  label: "Day of Week",
                  value: session.dayOfWeek,
                  color: cardColor,
                  isDark: isDark,
                ),
                const SizedBox(height: 12),
                _buildSubjectDetailRow(
                  icon: Icons.access_time_rounded,
                  label: "Schedule Time",
                  value: "${session.startTime} - ${session.endTime}",
                  color: const Color(0xFF6C63FF),
                  isDark: isDark,
                ),
                const SizedBox(height: 12),
                _buildSubjectDetailRow(
                  icon: Icons.room_rounded,
                  label: "Room / Building",
                  value: session.room,
                  color: const Color(0xFFFF6584),
                  isDark: isDark,
                ),
                const SizedBox(height: 12),
                _buildSubjectDetailRow(
                  icon: Icons.person_rounded,
                  label: "Instructor / Professor",
                  value: session.instructor,
                  color: const Color(0xFF4ECDC4),
                  isDark: isDark,
                ),
                const SizedBox(height: 24),

                // Close Button
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text("Got It", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSubjectDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252147) : const Color(0xFFF7F8FC),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white60 : Colors.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showScheduleDetailModal(BuildContext context, ScheduleProvider provider, ScheduleHistoryItem item) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final activeDays = days.where((dayName) {
      return item.sessions.any((s) => s.dayOfWeek.toLowerCase() == dayName.toLowerCase());
    }).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1E1A3C) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (sheetContext, scrollController) {
            return Column(
              children: [
                // Modal Drag Handle
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Modal Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.course,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "${item.year} • ${item.semester} • ${item.schoolYear}",
                              style: TextStyle(
                                fontSize: 13,
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(sheetContext),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // Quick Stat Badges
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  color: isDark ? const Color(0xFF252147) : const Color(0xFFF7F8FC),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatBadge("Subjects", "${item.sessions.length}", theme),
                      _buildStatBadge("Total Units", "${item.totalUnits}", theme),
                      _buildStatBadge("Section", item.section, theme),
                      _buildStatBadge("Active Days", "${activeDays.length}", theme),
                    ],
                  ),
                ),

                // Class Sessions by Day
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.all(20),
                    itemCount: activeDays.length,
                    itemBuilder: (context, dayIdx) {
                      final dayName = activeDays[dayIdx];
                      final daySessions = item.sessions
                          .where((s) => s.dayOfWeek.toLowerCase() == dayName.toLowerCase())
                          .toList();
                      daySessions.sort((a, b) => a.startTime.compareTo(b.startTime));

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF252147).withValues(alpha: 0.6)
                              : Colors.grey[50],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark ? Colors.white12 : Colors.grey[200]!,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              dayName.toUpperCase(),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 10),
                            ...daySessions.map((session) {
                              final sessionColor = Color(session.colorValue);
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10.0),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 10,
                                      height: 10,
                                      decoration: BoxDecoration(
                                        color: sessionColor,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            session.subjectName,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            "${session.subjectCode} • ${session.startTime} - ${session.endTime} | Room: ${session.room}",
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: isDark ? Colors.white60 : Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // Bottom Action Buttons
                Container(
                  padding: EdgeInsets.fromLTRB(20, 12, 20, 24 + (MediaQuery.of(context).viewPadding.bottom > 0 ? MediaQuery.of(context).viewPadding.bottom : 8)),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1A3C) : Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 10,
                        offset: const Offset(0, -4),
                      )
                    ],
                  ),
                  child: Row(
                    children: [
                      // Load as Active button
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                          label: const Text("Set as Active"),
                          onPressed: () {
                            provider.loadHistoryItem(item);
                            Navigator.pop(sheetContext);
                            TopNotification.show(
                              context,
                              title: "Schedule Activated ✨",
                              message: "${item.course} (${item.year}, ${item.semester}) is now active.",
                              type: NotificationType.success,
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Customize & Export button
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.palette_outlined, size: 18),
                          label: const Text("Export Poster"),
                          onPressed: () {
                            provider.loadHistoryItem(item);
                            Navigator.pop(sheetContext);
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const ScheduleExporterScreen()),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildStatBadge(String label, String value, ThemeData theme) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w900,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  void _showNoScheduleSnackbar(BuildContext context) {
    TopNotification.show(
      context,
      title: "No Schedule Found",
      message: "Please upload or scan a Certificate of Registration (CoR) first!",
      type: NotificationType.warning,
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

  void _showWelcomeBackPopUp(BuildContext context) {
    final provider = Provider.of<ScheduleProvider>(context, listen: false);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return Dialog(
          backgroundColor: isDark ? const Color(0xFF1E1A3C) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          child: Container(
            padding: const EdgeInsets.all(24),
            constraints: const BoxConstraints(maxWidth: 380),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Glowing Icon Badge
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6C63FF), Color(0xFF9D4EDD)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6C63FF).withValues(alpha: 0.4),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      "🎉",
                      style: TextStyle(fontSize: 34),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Title
                Text(
                  "Welcome Back, ${provider.studentFirstName}! ✨",
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                    color: isDark ? Colors.white : const Color(0xFF2D2E49),
                  ),
                ),
                const SizedBox(height: 10),

                // Subtitle
                Text(
                  "Your semester schedule, saved wallpapers, and homescreen widgets are all synced and ready.",
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 14,
                    color: isDark ? Colors.white70 : Colors.grey[700],
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),

                // Motivational Quote card
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2E2B5C).withValues(alpha: 0.6) : const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.tips_and_updates_rounded, color: Colors.amber, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _activeQuote,
                          style: TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Action Button
                ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C63FF),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: const Text(
                    "Let's Get Started 🚀",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
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
}

class FirstLetterCapitalizationFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) return newValue;
    final text = newValue.text;
    final buffer = StringBuffer();
    bool capitalizeNext = true;
    for (int i = 0; i < text.length; i++) {
      final char = text[i];
      if (capitalizeNext && char != ' ' && char != '-' && char != "'") {
        buffer.write(char.toUpperCase());
        capitalizeNext = false;
      } else {
        buffer.write(char);
        if (char == ' ' || char == '-' || char == "'") {
          capitalizeNext = true;
        }
      }
    }
    final capitalizedText = buffer.toString();
    return TextEditingValue(
      text: capitalizedText,
      selection: newValue.selection,
      composing: TextRange.empty,
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
  late String _selectedCourse;
  late String _selectedYear;
  DateTime? _selectedBirthdate;

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
    _selectedCourse = ScheduleProvider.availableCourses.contains(widget.provider.activeCourse)
        ? widget.provider.activeCourse
        : ScheduleProvider.availableCourses.first;
    _selectedYear = ScheduleProvider.availableYears.contains(widget.provider.activeYear)
        ? widget.provider.activeYear
        : ScheduleProvider.availableYears.first;

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
    );
    if (picked != null) {
      setState(() {
        _selectedBirthdate = picked;
        _birthdateController.text = "${picked.month.toString().padLeft(2, '0')}/${picked.day.toString().padLeft(2, '0')}/${picked.year}";

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
        course: _selectedCourse,
        year: _selectedYear,
      );

      Navigator.of(context).pop();
      TopNotification.show(
        context,
        title: "Profile Updated ✨",
        message: "Your student profile changes have been saved.",
        type: NotificationType.success,
      );
    }
  }

  void _logout() {
    Navigator.of(context).pop();
    widget.provider.clearStudentProfile();
    TopNotification.show(
      context,
      title: "Logged Out",
      message: "You have been logged out successfully.",
      type: NotificationType.info,
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
                  inputFormatters: [FirstLetterCapitalizationFormatter()],
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
                  inputFormatters: [FirstLetterCapitalizationFormatter()],
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
                  inputFormatters: [FirstLetterCapitalizationFormatter()],
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

                // Course Dropdown
                DropdownButtonFormField<String>(
                  value: _selectedCourse,
                  isExpanded: true,
                  dropdownColor: isDark ? const Color(0xFF1F1C3F) : Colors.white,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                  decoration: const InputDecoration(
                    labelText: "Course / Major",
                    prefixIcon: Icon(Icons.book_outlined, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                  ),
                  items: ScheduleProvider.availableCourses.map((course) {
                    return DropdownMenuItem(value: course, child: Text(course, overflow: TextOverflow.ellipsis));
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedCourse = value;
                      });
                    }
                  },
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
                  items: ScheduleProvider.availableYears.map((year) {
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

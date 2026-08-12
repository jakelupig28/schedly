import 'package:flutter/material';
import 'package:provider/provider';
import '../providers/schedule_provider.dart';
import '../models/schedule.dart';
import '../theme/app_theme.dart';
import 'schedule_parser_screen.dart';
import 'schedule_exporter_screen.dart';
import 'history_screen.dart';
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
                    "Hello, Student!",
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
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    Icons.calendar_month_rounded,
                    color: theme.colorScheme.primary,
                    size: 24,
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
}

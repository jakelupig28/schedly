import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/schedule_provider.dart';
import '../models/schedule.dart';
import '../services/native_service.dart';
import 'top_notification.dart';

class MockWidgetPreview extends StatefulWidget {
  const MockWidgetPreview({super.key});

  @override
  State<MockWidgetPreview> createState() => _MockWidgetPreviewState();
}

class _MockWidgetPreviewState extends State<MockWidgetPreview> {
  // Widget size presets
  late String _widgetSize;
  final List<String> _sizes = ['Small (2x2)', 'Medium (4x2)', 'Large (4x4)'];

  // Style customization
  late bool _showTime;
  late bool _showRoom;
  late String _widgetBg; // 'Glassmorphism', 'Solid Light', 'Midnight Neon', 'Sunset Gradient'

  final List<String> _bgStyles = [
    'Glassmorphism',
    'Solid Light',
    'Midnight Neon',
    'Sunset Gradient',
  ];

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<ScheduleProvider>(context, listen: false);
    _widgetSize = provider.widgetSize;
    _widgetBg = provider.widgetBgStyle;
    _showTime = provider.showWidgetTime;
    _showRoom = provider.showWidgetRoom;
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ScheduleProvider>(context);
    final theme = Theme.of(context);
    final sessions = provider.activeSessions;

    // Determine current day sessions
    final now = DateTime.now();
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final currentDay = days[now.weekday - 1];

    final daySessions = sessions
        .where((s) => s.dayOfWeek.toLowerCase() == currentDay.toLowerCase())
        .toList();
    daySessions.sort((a, b) => a.startTime.compareTo(b.startTime));

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Homescreen Widget",
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20.0, 12.0, 20.0, 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "Live Widget Preview",
                style: theme.textTheme.titleLarge?.copyWith(fontSize: 17, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              const Text(
                "Configure how your schedule widget looks on your Android home screen.",
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),

              // 1. Phone Desktop & Widget Preview Mockup
              _buildPhoneHomescreen(theme, currentDay, daySessions.isNotEmpty ? daySessions : sessions),
              const SizedBox(height: 24),

              // 2. Customizer Form Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Size Dropdown
                      const Text("Widget Size", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _widgetSize,
                        icon: Icon(Icons.keyboard_arrow_down_rounded, color: theme.colorScheme.primary),
                        dropdownColor: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        elevation: 8,
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(14))),
                        ),
                        items: _sizes.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _widgetSize = val);
                            provider.updateWidgetPreferences(size: val);
                          }
                        },
                      ),
                      const SizedBox(height: 20),

                      // Background Styling Options
                      const Text("Widget Background Style", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _bgStyles.map((style) => _buildBgStyleChip(style, theme, provider)).toList(),
                      ),
                      const SizedBox(height: 20),

                      // Display Toggles
                      const Text("Information Displays", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 6),
                      SwitchListTile(
                        title: const Text("Show Class Timings", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        subtitle: const Text("Display start and end times", style: TextStyle(fontSize: 11, color: Colors.grey)),
                        value: _showTime,
                        onChanged: (val) {
                          setState(() => _showTime = val);
                          provider.updateWidgetPreferences(showTime: val);
                        },
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      ),
                      SwitchListTile(
                        title: const Text("Show Room / Location", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        subtitle: const Text("Display room numbers and labs", style: TextStyle(fontSize: 11, color: Colors.grey)),
                        value: _showRoom,
                        onChanged: (val) {
                          setState(() => _showRoom = val);
                          provider.updateWidgetPreferences(showRoom: val);
                        },
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Apply and Sync Button
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                icon: const Icon(Icons.check_circle_rounded),
                label: const Text("Save & Sync Widget", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                onPressed: () {
                  provider.updateWidgetPreferences(
                    size: _widgetSize,
                    bgStyle: _widgetBg,
                    showTime: _showTime,
                    showRoom: _showRoom,
                  );
                  NativeService.syncNativeWidgetData(provider);
                  TopNotification.show(
                    context,
                    title: "Widget Configured! 📱",
                    message: "$_widgetSize ($_widgetBg) saved & synced to your home screen widget.",
                    type: NotificationType.success,
                  );
                },
              ),
              const SizedBox(height: 24),

              // 3. Setup Instructions Card
              _buildSetupInstructions(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneHomescreen(ThemeData theme, String todayName, List<ClassSession> sessions) {
    return Container(
      height: 260,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        // Modern sleek dark smartphone wallpaper
        gradient: const LinearGradient(
          colors: [
            Color(0xFF131127),
            Color(0xFF231E3D),
            Color(0xFF1E1738),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          )
        ],
        border: Border.all(color: Colors.white.withValues(alpha: 0.12), width: 1.5),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      child: Column(
        children: [
          // Mock Phone Status Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "9:41",
                style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  Icon(Icons.wifi, size: 12, color: Colors.white.withValues(alpha: 0.7)),
                  const SizedBox(width: 4),
                  Icon(Icons.signal_cellular_4_bar, size: 12, color: Colors.white.withValues(alpha: 0.7)),
                  const SizedBox(width: 4),
                  Icon(Icons.battery_full_rounded, size: 13, color: Colors.white.withValues(alpha: 0.7)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Floating Widget Preview
          Expanded(
            child: Center(
              child: _buildFloatingWidget(theme, todayName, sessions),
            ),
          ),
          const SizedBox(height: 8),

          // Mock Home Screen App Dock
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildMockAppIcon(Icons.camera_alt_rounded, const Color(0xFF6C63FF)),
              _buildMockAppIcon(Icons.chat_bubble_rounded, const Color(0xFF10B981)),
              _buildMockAppIcon(Icons.language_rounded, const Color(0xFF3B82F6)),
              _buildMockAppIcon(Icons.music_note_rounded, const Color(0xFFFF6584)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMockAppIcon(IconData icon, Color color) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
      ),
      child: Icon(icon, color: color, size: 16),
    );
  }

  Widget _buildFloatingWidget(ThemeData theme, String todayName, List<ClassSession> sessions) {
    BoxDecoration decoration;
    Color titleColor;
    Color bodyColor;

    if (_widgetBg == 'Solid Light') {
      decoration = BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.20), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      );
      titleColor = const Color(0xFF6C63FF);
      bodyColor = const Color(0xFF2D2E49);
    } else if (_widgetBg == 'Midnight Neon') {
      decoration = BoxDecoration(
        color: const Color(0xFF0F0E1E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF8B84FF), width: 1.5),
        boxShadow: [
          BoxShadow(color: const Color(0xFF6C63FF).withValues(alpha: 0.35), blurRadius: 14),
        ],
      );
      titleColor = const Color(0xFF9D95FF);
      bodyColor = Colors.white;
    } else if (_widgetBg == 'Sunset Gradient') {
      decoration = BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF8A2387),
            Color(0xFFE94057),
            Color(0xFFF27121),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(color: const Color(0xFFE94057).withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      );
      titleColor = Colors.white;
      bodyColor = Colors.white.withValues(alpha: 0.92);
    } else {
      // Glassmorphism (Default)
      decoration = BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 1.2),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.20), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      );
      titleColor = const Color(0xFFB4AFFF);
      bodyColor = Colors.white;
    }

    double width = 260;
    double height = 130;

    if (_widgetSize == 'Small (2x2)') {
      width = 130;
      height = 130;
    } else if (_widgetSize == 'Large (4x4)') {
      width = 260;
      height = 155;
    }

    return Container(
      width: width,
      height: height,
      decoration: decoration,
      padding: const EdgeInsets.all(12),
      child: _widgetSize == 'Small (2x2)'
          ? _buildSmallWidgetLayout(titleColor, bodyColor, todayName, sessions)
          : _buildMediumLargeWidgetLayout(titleColor, bodyColor, todayName, sessions),
    );
  }

  Widget _buildSmallWidgetLayout(Color titleColor, Color bodyColor, String todayName, List<ClassSession> sessions) {
    final nextClass = sessions.isNotEmpty ? sessions.first : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "SCHEDLY",
              style: TextStyle(color: titleColor, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5),
            ),
            Icon(Icons.school_rounded, size: 13, color: titleColor),
          ],
        ),
        const SizedBox(height: 6),
        if (nextClass == null) ...[
          Text("No Class", style: TextStyle(color: titleColor, fontSize: 13, fontWeight: FontWeight.bold)),
          Text("Enjoy your break!", style: TextStyle(color: bodyColor.withValues(alpha: 0.8), fontSize: 9)),
        ] else ...[
          Text(
            nextClass.subjectCode,
            style: TextStyle(color: titleColor, fontSize: 13, fontWeight: FontWeight.w900),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            nextClass.subjectName,
            style: TextStyle(color: bodyColor, fontSize: 10, fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (_showTime) ...[
            const SizedBox(height: 2),
            Text(
              nextClass.startTime,
              style: TextStyle(color: bodyColor.withValues(alpha: 0.8), fontSize: 9, fontWeight: FontWeight.bold),
            ),
          ],
          if (_showRoom && nextClass.room.isNotEmpty) ...[
            Text(
              nextClass.room,
              style: TextStyle(color: bodyColor.withValues(alpha: 0.7), fontSize: 8),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildMediumLargeWidgetLayout(Color titleColor, Color bodyColor, String todayName, List<ClassSession> sessions) {
    final displayLimit = _widgetSize == 'Large (4x4)' ? 3 : 2;
    final list = sessions.take(displayLimit).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "SCHEDLY • NEXT CLASSES",
              style: TextStyle(color: titleColor, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5),
            ),
            Icon(Icons.school_rounded, size: 13, color: titleColor),
          ],
        ),
        const SizedBox(height: 8),
        if (sessions.isEmpty)
          Expanded(
            child: Center(
              child: Text(
                "Rest Day! No upcoming classes.",
                style: TextStyle(color: titleColor, fontSize: 11, fontStyle: FontStyle.italic),
              ),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              itemCount: list.length,
              itemBuilder: (context, idx) {
                final session = list[idx];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "${session.subjectCode} - ${session.subjectName}",
                              style: TextStyle(color: bodyColor, fontSize: 11, fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Row(
                        children: [
                          if (_showRoom && session.room.isNotEmpty) ...[
                            Text(
                              session.room,
                              style: TextStyle(color: bodyColor.withValues(alpha: 0.75), fontSize: 9),
                            ),
                            const SizedBox(width: 6),
                          ],
                          if (_showTime)
                            Text(
                              session.startTime.split(' ')[0],
                              style: TextStyle(color: titleColor, fontSize: 9, fontWeight: FontWeight.bold),
                            ),
                        ],
                      )
                    ],
                  ),
                );
              },
            ),
          )
      ],
    );
  }

  Widget _buildBgStyleChip(String styleName, ThemeData theme, ScheduleProvider provider) {
    final isSelected = _widgetBg == styleName;
    return InkWell(
      onTap: () {
        setState(() => _widgetBg = styleName);
        provider.updateWidgetPreferences(bgStyle: styleName);
      },
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? null
              : Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.2)),
        ),
        child: Text(
          styleName,
          style: TextStyle(
            fontSize: 12,
            color: isSelected ? Colors.white : theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildSetupInstructions(ThemeData theme) {
    return Card(
      color: theme.colorScheme.primary.withValues(alpha: 0.04),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.15), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.widgets_rounded, color: theme.colorScheme.primary),
                const SizedBox(width: 10),
                const Text(
                  "How to Add Schedly Widget to Android",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
            const Divider(height: 24),
            const Text(
              "1. Go to your phone's Home Screen.\n2. Long-press on an empty area and tap 'Widgets'.\n3. Scroll or search for 'Schedly'.\n4. Touch and hold the Schedly Schedule widget, then drag it onto your home screen.\n5. Resize the widget to your preference.",
              style: TextStyle(fontSize: 12, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

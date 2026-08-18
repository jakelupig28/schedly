import 'package:flutter/material';
import 'package:provider/provider';
import '../providers/schedule_provider.dart';
import '../models/schedule.dart';

class MockWidgetPreview extends StatefulWidget {
  const MockWidgetPreview({super.key});

  @override
  State<MockWidgetPreview> createState() => _MockWidgetPreviewState();
}

class _MockWidgetPreviewState extends State<MockWidgetPreview> {
  // Widget size presets
  String _widgetSize = 'Medium (4x2)';
  final List<String> _sizes = ['Small (2x2)', 'Medium (4x2)', 'Large (4x4)'];

  // Style customization
  bool _showTime = true;
  bool _showRoom = true;
  String _widgetBg = 'Glassmorphism'; // 'Glassmorphism', 'Solid Light', 'Midnight Neon'

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ScheduleProvider>(context);
    final theme = Theme.of(context);
    final sessions = provider.activeSessions;

    // Filter today's classes for widget display
    final int weekdayIndex = DateTime.now().weekday;
    final List<String> days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final String today = days[weekdayIndex - 1];
    final todaySessions = sessions.where((s) => s.dayOfWeek.toLowerCase() == today.toLowerCase()).toList();
    todaySessions.sort((a, b) => a.startTime.compareTo(b.startTime));

    return Scaffold(
      appBar: AppBar(
        title: const Text("Homescreen Widget"),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "Widget Simulator",
                style: theme.textTheme.titleLarge?.copyWith(fontSize: 16),
              ),
              const SizedBox(height: 4),
              const Text(
                "Customize how your class schedule appears on your device home screen.",
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 20),

              // 1. Phone Desktop & Widget Preview Container
              _buildPhoneHomescreen(theme, today, todaySessions),
              const SizedBox(height: 28),

              // 2. Customizer Form Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Size Toggle
                      const Text("Widget Size", style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _widgetSize,
                        icon: Icon(Icons.keyboard_arrow_down_rounded, color: theme.colorScheme.primary),
                        dropdownColor: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        elevation: 8,
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                        items: _sizes.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _widgetSize = val);
                        },
                      ),
                      const SizedBox(height: 16),

                      // Background Styling
                      const Text("Widget Background Style", style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildBgStyleTab('Glassmorphism', theme),
                          const SizedBox(width: 6),
                          _buildBgStyleTab('Solid Light', theme),
                          const SizedBox(width: 6),
                          _buildBgStyleTab('Midnight Neon', theme),
                          const SizedBox(width: 6),
                          _buildBgStyleTab('Sunset Gradient', theme),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Display Options
                      const Text("Information Displays", style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      SwitchListTile(
                        title: const Text("Show Class Timings", style: TextStyle(fontSize: 13)),
                        value: _showTime,
                        onChanged: (val) => setState(() => _showTime = val),
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      ),
                      SwitchListTile(
                        title: const Text("Show Room / Location", style: TextStyle(fontSize: 13)),
                        value: _showRoom,
                        onChanged: (val) => setState(() => _showRoom = val),
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 3. User Setup Instructions
              _buildSetupInstructions(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneHomescreen(ThemeData theme, String todayName, List<ClassSession> sessions) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        // Phone wallpaper style background
        gradient: const LinearGradient(
          colors: [
            Color(0xFF4158D0),
            Color(0xFFC850C0),
            Color(0xFFFFCC70),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 6),
          )
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Center(
        child: _buildFloatingWidget(theme, todayName, sessions),
      ),
    );
  }

  Widget _buildFloatingWidget(ThemeData theme, String todayName, List<ClassSession> sessions) {
    // Styling attributes
    BoxDecoration decoration;
    Color titleColor;
    Color bodyColor;

    if (_widgetBg == 'Solid Light') {
      decoration = BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)],
      );
      titleColor = const Color(0xFF6C63FF);
      bodyColor = Colors.black87;
    } else if (_widgetBg == 'Midnight Neon') {
      decoration = BoxDecoration(
        color: const Color(0xFF0F0E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFF6584).withOpacity(0.6), width: 1.5),
      );
      titleColor = const Color(0xFFFF6584);
      bodyColor = Colors.white;
    } else if (_widgetBg == 'Sunset Gradient') {
      decoration = BoxDecoration(
        borderRadius: BorderRadius.circular(16),
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
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      );
      titleColor = Colors.white;
      bodyColor = Colors.white.withOpacity(0.9);
    } else {
      // Glassmorphism
      decoration = BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.0),
      );
      titleColor = Colors.white;
      bodyColor = Colors.white70;
    }

    // Adjust size dimensions for mock preview
    double width = 230;
    double height = 110;

    if (_widgetSize == 'Small (2x2)') {
      width = 110;
      height = 110;
    } else if (_widgetSize == 'Large (4x4)') {
      width = 230;
      height = 150;
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
              "TODAY",
              style: TextStyle(color: titleColor.withOpacity(0.8), fontSize: 9, fontWeight: FontWeight.bold),
            ),
            Icon(Icons.class_rounded, size: 10, color: titleColor.withOpacity(0.8)),
          ],
        ),
        const SizedBox(height: 4),
        if (nextClass == null) ...[
          Text("No Class", style: TextStyle(color: titleColor, fontSize: 12, fontWeight: FontWeight.bold)),
          Text("Enjoy rest!", style: TextStyle(color: bodyColor.withOpacity(0.8), fontSize: 9)),
        ] else ...[
          Text(
            nextClass.subjectCode,
            style: TextStyle(color: titleColor, fontSize: 13, fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (_showTime)
            Text(
              nextClass.startTime.split(' ')[0],
              style: TextStyle(color: bodyColor, fontSize: 9),
            ),
          if (_showRoom)
            Text(
              nextClass.room,
              style: TextStyle(color: bodyColor.withOpacity(0.8), fontSize: 9),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
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
              "TODAY'S CLASSES • ${todayName.toUpperCase()}",
              style: TextStyle(color: titleColor.withOpacity(0.8), fontSize: 9, fontWeight: FontWeight.bold),
            ),
            Icon(Icons.class_rounded, size: 10, color: titleColor.withOpacity(0.8)),
          ],
        ),
        const SizedBox(height: 6),
        if (sessions.isEmpty)
          Expanded(
            child: Center(
              child: Text(
                "Rest Day! No classes scheduled.",
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
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          "${session.subjectCode} - ${session.subjectName}",
                          style: TextStyle(color: titleColor, fontSize: 11, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Row(
                        children: [
                          if (_showRoom) ...[
                            Text(
                              session.room.split(' ').last,
                              style: TextStyle(color: bodyColor.withOpacity(0.8), fontSize: 9),
                            ),
                            const SizedBox(width: 8),
                          ],
                          if (_showTime)
                            Text(
                              session.startTime.split(' ')[0],
                              style: TextStyle(color: bodyColor, fontSize: 9, fontWeight: FontWeight.bold),
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

  Widget _buildBgStyleTab(String styleName, ThemeData theme) {
    final isSelected = _widgetBg == styleName;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _widgetBg = styleName),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? theme.colorScheme.primary : theme.colorScheme.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              styleName.split(' ').first,
              style: TextStyle(
                fontSize: 11,
                color: isSelected ? Colors.white : theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSetupInstructions(ThemeData theme) {
    return Card(
      color: theme.colorScheme.primary.withOpacity(0.04),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: theme.colorScheme.primary.withOpacity(0.15), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline_rounded, color: theme.colorScheme.primary),
                const SizedBox(width: 10),
                const Text(
                  "How to Add to Homescreen",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
            const Divider(height: 24),
            const Text(
              "iOS Setup:",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
            const Text(
              "1. Press and hold an empty area on your home screen until apps jiggle.\n2. Tap the '+' button in the top corner.\n3. Search for 'Schedly', pick a size, and tap 'Add Widget'.",
              style: TextStyle(fontSize: 12, height: 1.4),
            ),
            const SizedBox(height: 12),
            const Text(
              "Android Setup:",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
            const Text(
              "1. Long press on your home screen and select 'Widgets'.\n2. Scroll to find 'Schedly'.\n3. Tap and hold the widget layout, drag it onto your screen, and resize.",
              style: TextStyle(fontSize: 12, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

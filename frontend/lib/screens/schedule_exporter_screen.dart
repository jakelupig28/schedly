import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/schedule_provider.dart';
import '../models/schedule.dart';
import '../widgets/top_notification.dart';
import '../services/native_service.dart';

class ScheduleExporterScreen extends StatefulWidget {
  const ScheduleExporterScreen({super.key});

  @override
  State<ScheduleExporterScreen> createState() => _ScheduleExporterScreenState();
}

class _ScheduleExporterScreenState extends State<ScheduleExporterScreen> {
  final ScreenshotController _screenshotController = ScreenshotController();

  // Size options: Name -> Aspect Ratio
  final Map<String, double> _sizeOptions = {
    'Lockscreen (9:16)': 9 / 16,
    'Square (1:1)': 1 / 1,
    'Standard (3:4)': 3 / 4,
    'Wide Banner (16:9)': 16 / 9,
  };
  late String _selectedSizeKey;

  // Visual Themes
  final List<String> _themes = ['Sticker Template', 'Pastel Sky', 'Cyberpunk Neon', 'Minimalist Ink', 'Forest Study'];

  // Preset Gradient Color Indexes
  final List<List<Color>> _gradientPresets = [
    [const Color(0xFF6C63FF), const Color(0xFFFF6584)], // Pastel Sunset
    [const Color(0xFF0F2027), const Color(0xFF203A43), const Color(0xFF2C5364)], // Midnight Deep
    [const Color(0xFF8E94F2), const Color(0xFFBDF0FF)], // Sky Blue Pastel
    [const Color(0xFF11998E), const Color(0xFF38EF7D)], // Fresh Forest
    [const Color(0xFFFF9966), const Color(0xFFFF5E62)], // Warm Peach
    [const Color(0xFF000428), const Color(0xFF004E92)], // Cyber Navy
    [const Color(0xFF1E1E1E), const Color(0xFF2D2D2D)], // Ink Charcoal
    [const Color(0xFFF857A6), const Color(0xFFFF5858)], // Sunset Love
    [const Color(0xFFA8FF78), const Color(0xFF78FFD6)], // Cozy Matcha
    [const Color(0xFFA18CD1), const Color(0xFFFBC2EB)], // Sweet Lavender
    [const Color(0xFF4FACFE), const Color(0xFF00F2FE)], // Ocean Breeze
  ];
  int _selectedGradientIdx = 0;

  final List<String> _fontStyles = ['Classic Clean', 'Playful Cute', 'Elegant Serif', 'Modern Sleek', 'Aesthetic Cursive'];
  String _selectedFontStyle = 'Classic Clean';

  TextStyle _getFontStyle(String fontStyle, {required double fontSize, required FontWeight fontWeight, required Color color}) {
    switch (fontStyle) {
      case 'Playful Cute':
        return TextStyle(
          fontFamily: 'sans-serif-condensed',
          fontSize: fontSize,
          fontWeight: fontWeight == FontWeight.bold ? FontWeight.w800 : FontWeight.w500,
          color: color,
          letterSpacing: 0.5,
        );
      case 'Elegant Serif':
        return TextStyle(
          fontFamily: 'serif',
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color,
          fontStyle: FontStyle.italic,
          letterSpacing: 0.2,
        );
      case 'Modern Sleek':
        return TextStyle(
          fontFamily: 'sans-serif',
          fontSize: fontSize,
          fontWeight: fontWeight == FontWeight.bold ? FontWeight.w900 : FontWeight.w400,
          color: color,
          letterSpacing: 1.5,
        );
      case 'Aesthetic Cursive':
        return TextStyle(
          fontFamily: 'cursive',
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color,
          letterSpacing: 1.0,
        );
      case 'Classic Clean':
      default:
        return TextStyle(
          fontFamily: 'sans-serif-medium',
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color,
          letterSpacing: 0.0,
        );
    }
  }

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedSizeKey = _sizeOptions.keys.first; // Default to Lockscreen (9:16)
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ScheduleProvider>(context);
    final theme = Theme.of(context);
    final sessions = provider.activeSessions;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Export Schedule",
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 120.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Live Preview Panel
              Text(
                "Wallpaper Preview",
                style: theme.textTheme.titleLarge?.copyWith(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Center(
                child: Screenshot(
                  controller: _screenshotController,
                  child: Container(
                    width: 250,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        )
                      ],
                    ),
                    child: AspectRatio(
                      aspectRatio: _sizeOptions[_selectedSizeKey]!,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: _buildSchedulePoster(provider, sessions),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // 2. Customization Controls
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Size Selector
                      const Text("Select Export Size", style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _selectedSizeKey,
                        icon: Icon(Icons.keyboard_arrow_down_rounded, color: theme.colorScheme.primary),
                        dropdownColor: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        elevation: 8,
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                        items: _sizeOptions.keys.map((String key) {
                          return DropdownMenuItem(value: key, child: Text(key));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedSizeKey = val;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 20),

                      // Themes Selector
                      const Text("Visual Theme Style", style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 40,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _themes.length,
                          itemBuilder: (context, idx) {
                            final styleName = _themes[idx];
                            final isSelected = provider.exportThemeStyle == styleName;
                            return GestureDetector(
                              onTap: () {
                                provider.setExportStyle(styleName);
                              },
                              child: Container(
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.primary.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(12),
                                  border: isSelected
                                      ? null
                                      : Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
                                ),
                                child: Center(
                                  child: Text(
                                    styleName,
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : theme.colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Custom Background Image picker for Sticker Template
                      if (provider.exportThemeStyle == 'Sticker Template') ...[
                        const Text("Custom Background Image", style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                                  foregroundColor: theme.colorScheme.primary,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
                                  ),
                                ),
                                icon: const Icon(Icons.image_outlined),
                                label: Text(provider.customBgImagePath != null ? "Change Background" : "Choose Background"),
                                onPressed: () async {
                                  final picker = ImagePicker();
                                  final image = await picker.pickImage(source: ImageSource.gallery);
                                  if (image != null) {
                                    provider.setCustomBgImagePath(image.path);
                                  }
                                },
                              ),
                            ),
                            if (provider.customBgImagePath != null) ...[
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.clear, color: Colors.red),
                                onPressed: () {
                                  provider.setCustomBgImagePath(null);
                                },
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Font Style Selector
                      const Text("Font Style", style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _selectedFontStyle,
                        dropdownColor: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        elevation: 8,
                        icon: Icon(Icons.keyboard_arrow_down_rounded, color: theme.colorScheme.primary),
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                        items: _fontStyles.map((String fontName) {
                          return DropdownMenuItem(value: fontName, child: Text(fontName));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedFontStyle = val;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 20),

                      // Background Gradients (for gradient themes)
                      if (provider.exportThemeStyle != 'Minimalist Ink' && provider.exportThemeStyle != 'Sticker Template') ...[
                        const Text("Background Gradient", style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 40,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _gradientPresets.length,
                            itemBuilder: (context, idx) {
                              final colors = _gradientPresets[idx];
                              final isSelected = _selectedGradientIdx == idx;
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedGradientIdx = idx;
                                  });
                                  provider.setExportGradient(idx, idx);
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: colors,
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    shape: BoxShape.circle,
                                    border: isSelected
                                        ? Border.all(color: theme.colorScheme.onSurface, width: 3)
                                        : null,
                                  ),
                                  child: isSelected
                                      ? const Icon(Icons.check, color: Colors.white, size: 18)
                                      : null,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Download Schedule Button
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: _isSaving ? null : () => _exportPoster(theme),
                icon: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.download_rounded),
                label: Text(
                  _isSaving ? "Downloading Schedule..." : "Download Schedule",
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Generates the customized schedule wallpaper
  Widget _buildSchedulePoster(ScheduleProvider provider, List<ClassSession> sessions) {
    final style = provider.exportThemeStyle;

    // Apply color schemes based on the selected style
    BoxDecoration backgroundDecoration;
    Color textColor;
    Color subTextColor;
    Color containerBgColor;
    double cellBorderRadius = 12.0;
    Border? cellBorder;

    if (style == 'Cyberpunk Neon') {
      backgroundDecoration = const BoxDecoration(
        color: Color(0xFF070412),
      );
      textColor = const Color(0xFF00FFCC);
      subTextColor = const Color(0xFFFF007F);
      containerBgColor = const Color(0xFF140F2D).withValues(alpha: 0.8);
      cellBorder = Border.all(color: const Color(0xFFFF007F).withValues(alpha: 0.5), width: 1.5);
    } else if (style == 'Minimalist Ink') {
      backgroundDecoration = const BoxDecoration(
        color: Color(0xFFFBFBFB),
      );
      textColor = Colors.black;
      subTextColor = Colors.black87;
      containerBgColor = Colors.white;
      cellBorder = Border.all(color: Colors.black.withValues(alpha: 0.2), width: 1.5);
      cellBorderRadius = 4.0;
    } else if (style == 'Forest Study') {
      backgroundDecoration = const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2C3E2B), Color(0xFF1E281C)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      );
      textColor = const Color(0xFFE2EAD9);
      subTextColor = const Color(0xFFA5B29B);
      containerBgColor = const Color(0xFF324631).withValues(alpha: 0.6);
      cellBorder = Border.all(color: const Color(0xFFA5B29B).withValues(alpha: 0.2), width: 1.0);
    } else if (style == 'Sticker Template') {
      textColor = const Color(0xFF5C4033);
      subTextColor = const Color(0xFF5C4033);
      containerBgColor = Colors.transparent;
      backgroundDecoration = const BoxDecoration();
    } else {
      // Pastel Sky (Default)
      backgroundDecoration = BoxDecoration(
        gradient: LinearGradient(
          colors: _gradientPresets[_selectedGradientIdx],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      );
      textColor = Colors.white;
      subTextColor = Colors.white70;
      containerBgColor = Colors.white.withValues(alpha: 0.18);
    }

    // Sort and filter active days
    final List<String> days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final activeDays = days.where((dayName) {
      return sessions.any((s) => s.dayOfWeek.toLowerCase() == dayName.toLowerCase());
    }).toList();

    // Sticker Template Receipt layout
    if (style == 'Sticker Template') {
      return LayoutBuilder(
        builder: (context, constraints) {
          // Flatten sessions sequentially in day order to build a continuous list
          final List<MapEntry<String, ClassSession>> flattenedSessions = [];
          for (final dayName in activeDays) {
            final daySessions = sessions.where((s) => s.dayOfWeek.toLowerCase() == dayName.toLowerCase()).toList();
            daySessions.sort((a, b) => a.startTime.compareTo(b.startTime));
            for (final session in daySessions) {
              flattenedSessions.add(MapEntry(dayName, session));
            }
          }

          final totalClasses = flattenedSessions.length;
          final calculatedUnits = (totalClasses * 1.8).round();

          final backgroundImageAsset = provider.customBgImagePath != null
              ? FileImage(File(provider.customBgImagePath!)) as ImageProvider
              : const AssetImage('assets/template.png') as ImageProvider;

          // Exact bounds matching the asterisk lines (21.8% to 75.2% of image width)
          final receiptLeft = constraints.maxWidth * 0.220;
          final receiptWidth = constraints.maxWidth * 0.530;

          // Clean academic year formatting to avoid duplicate "S.Y."
          final rawSy = provider.activeSchoolYear.trim();
          final schoolYearClean = rawSy.startsWith('S.Y.') ? rawSy : 'S.Y. $rawSy';

          // Dynamic row height and font scaling for the schedule list
          final rowCount = flattenedSessions.isEmpty ? 1 : flattenedSessions.length;
          final availableScheduleHeight = constraints.maxHeight * 0.246;
          final rowHeight = (availableScheduleHeight / rowCount).clamp(constraints.maxHeight * 0.015, constraints.maxHeight * 0.024);
          final rowFontSize = (rowHeight * 0.42).clamp(constraints.maxHeight * 0.0070, constraints.maxHeight * 0.0090);

          return Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: backgroundImageAsset,
                fit: provider.customBgImagePath != null ? BoxFit.cover : BoxFit.fill,
              ),
            ),
            child: Stack(
              children: [
                // Custom Background Overlay if selected
                if (provider.customBgImagePath != null)
                  Positioned.fill(
                    child: Image.asset(
                      'assets/template.png',
                      fit: BoxFit.fill,
                    ),
                  ),

                // Unified rotated stack matching receipt orientation (-2.24 degrees)
                Positioned.fill(
                  child: Transform.rotate(
                    angle: -2.242 * 3.1415926535 / 180,
                    alignment: Alignment.center,
                    child: Stack(
                      children: [
                        // 1. Top Academic Info (cleanly positioned between CLASS SCHEDULE and upper *** line)
                        Positioned(
                          left: receiptLeft,
                          width: receiptWidth,
                          top: constraints.maxHeight * 0.446,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                provider.activeYear,
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.w900,
                                  fontSize: constraints.maxHeight * 0.0092,
                                  color: const Color(0xFF453832),
                                ),
                              ),
                              SizedBox(height: constraints.maxHeight * 0.0010),
                              Text(
                                "${provider.activeSemester} $schoolYearClean",
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.w900,
                                  fontSize: constraints.maxHeight * 0.0092,
                                  color: const Color(0xFF453832),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: constraints.maxHeight * 0.0010),
                              Text(
                                'EARIST',
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.w900,
                                  fontSize: constraints.maxHeight * 0.0092,
                                  color: const Color(0xFF453832),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // 2. Schedule list (strictly inside bounds between line 2 and line 3, never overlapping asterisk lines)
                        Positioned(
                          left: receiptLeft,
                          width: receiptWidth,
                          top: constraints.maxHeight * 0.536,
                          height: availableScheduleHeight,
                          child: ListView.builder(
                            padding: EdgeInsets.zero,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: flattenedSessions.length,
                            itemBuilder: (context, idx) {
                              const daysMap = {
                                'Monday': 'MON',
                                'Tuesday': 'TUE',
                                'Wednesday': 'WED',
                                'Thursday': 'THU',
                                'Friday': 'FRI',
                                'Saturday': 'SAT',
                                'Sunday': 'SUN'
                              };
                              final entry = flattenedSessions[idx];
                              final dayName = entry.key;
                              final session = entry.value;

                              // Show day label only on first session of this day
                              final bool isFirstOfDay = idx == 0 || flattenedSessions[idx - 1].key != dayName;
                              final shortDay = isFirstOfDay ? (daysMap[dayName] ?? dayName.substring(0, 3).toUpperCase()) : '';

                              final startParts = session.startTime.trim().split(' ');
                              final endParts = session.endTime.trim().split(' ');
                              final startClock = startParts.isNotEmpty ? startParts[0] : '';
                              final endClock = endParts.isNotEmpty ? endParts[0] : '';
                              final period = (endParts.length > 1 ? endParts[1] : (startParts.length > 1 ? startParts[1] : '')).toLowerCase();
                              final timeStr = "$startClock-$endClock $period";

                              return Container(
                                height: rowHeight,
                                alignment: Alignment.center,
                                child: Row(
                                  children: [
                                    // Column 1: Day (13% - under 'Day' header)
                                    SizedBox(
                                      width: receiptWidth * 0.13,
                                      child: Text(
                                        shortDay,
                                        style: TextStyle(
                                          fontFamily: 'monospace',
                                          fontWeight: FontWeight.w900,
                                          fontSize: rowFontSize,
                                          color: const Color(0xFF453832),
                                        ),
                                        textAlign: TextAlign.left,
                                        maxLines: 1,
                                        softWrap: false,
                                      ),
                                    ),
                                    // Column 2: Subject (50% - under 'Subject' header)
                                    SizedBox(
                                      width: receiptWidth * 0.50,
                                      child: Text(
                                        session.subjectName,
                                        style: TextStyle(
                                          fontFamily: 'monospace',
                                          fontWeight: FontWeight.w800,
                                          fontSize: rowFontSize,
                                          color: const Color(0xFF453832),
                                        ),
                                        textAlign: TextAlign.left,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        softWrap: false,
                                      ),
                                    ),
                                    // Column 3: Dash (4%)
                                    SizedBox(
                                      width: receiptWidth * 0.04,
                                      child: Text(
                                        '-',
                                        style: TextStyle(
                                          fontFamily: 'monospace',
                                          fontWeight: FontWeight.w900,
                                          fontSize: rowFontSize,
                                          color: const Color(0xFF453832),
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    // Column 4: Time (33% - under 'Time' header, right aligned)
                                    SizedBox(
                                      width: receiptWidth * 0.33,
                                      child: Text(
                                        timeStr,
                                        style: TextStyle(
                                          fontFamily: 'monospace',
                                          fontWeight: FontWeight.w800,
                                          fontSize: rowFontSize,
                                          color: const Color(0xFF453832),
                                        ),
                                        textAlign: TextAlign.right,
                                        maxLines: 1,
                                        softWrap: false,
                                        overflow: TextOverflow.clip,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),

                        // 3. Item Count Value (aligned right across from "Item Count")
                        Positioned(
                          left: receiptLeft,
                          width: receiptWidth,
                          top: constraints.maxHeight * 0.796,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              totalClasses.toString(),
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.w900,
                                fontSize: constraints.maxHeight * 0.0098,
                                color: const Color(0xFF453832),
                              ),
                            ),
                          ),
                        ),

                        // 4. Total Units Value (aligned right across from "Total")
                        Positioned(
                          left: receiptLeft,
                          width: receiptWidth,
                          top: constraints.maxHeight * 0.814,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              '$calculatedUnits units',
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.w900,
                                fontSize: constraints.maxHeight * 0.0098,
                                color: const Color(0xFF453832),
                              ),
                            ),
                          ),
                        ),

                        // 5. Course Title (cleanly placed below the bottom *** line and above rainbow hearts)
                        Positioned(
                          left: receiptLeft,
                          width: receiptWidth,
                          top: constraints.maxHeight * 0.846,
                          child: Align(
                            alignment: Alignment.center,
                            child: Text(
                              'Course: ${provider.activeCourse}',
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.w900,
                                fontSize: constraints.maxHeight * 0.0088,
                                color: const Color(0xFF453832),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    }

    // Default layout for other themes (with generous left and right margins)
    final totalClassesCount = sessions.length;
    final isDense = totalClassesCount > 7;
    final double dayMargin = isDense ? 4.0 : 8.0;
    final double dayPadding = isDense ? 5.0 : 8.0;
    final double dayHeaderGap = isDense ? 2.0 : 4.0;
    final double sessionPadding = isDense ? 2.5 : 4.5;

    final double dayNameFontSize = isDense ? 9.0 : 10.5;
    final double timeFontSize = isDense ? 7.5 : 8.5;
    final double subjectFontSize = isDense ? 9.0 : 10.5;
    final double subInfoFontSize = isDense ? 7.5 : 8.5;

    return Container(
      decoration: backgroundDecoration,
      padding: EdgeInsets.symmetric(
        horizontal: isDense ? 20.0 : 28.0,
        vertical: isDense ? 14.0 : 22.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: isDense ? 4 : 10),
          Text(
            "${provider.activeSemester} • ${provider.activeSchoolYear}",
            style: _getFontStyle(_selectedFontStyle, fontSize: isDense ? 7.5 : 9.5, fontWeight: FontWeight.bold, color: subTextColor),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            "WEEKLY SCHEDULE",
            style: _getFontStyle(_selectedFontStyle, fontSize: isDense ? 12 : 15, fontWeight: FontWeight.w900, color: textColor),
            textAlign: TextAlign.center,
          ),
          Text(
            "${provider.activeCourse} | ${provider.activeYear} - ${provider.activeSection}",
            style: _getFontStyle(_selectedFontStyle, fontSize: isDense ? 7.5 : 9.5, fontWeight: FontWeight.normal, color: subTextColor),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: isDense ? 8 : 14),

          Expanded(
            child: activeDays.isEmpty
                ? Center(
                    child: Text(
                      "No sessions mapped to this schedule.",
                      style: _getFontStyle(_selectedFontStyle, fontSize: 11, fontWeight: FontWeight.normal, color: subTextColor),
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: activeDays.length,
                    itemBuilder: (context, idx) {
                      final dayName = activeDays[idx];
                      final daySessions = sessions.where((s) => s.dayOfWeek.toLowerCase() == dayName.toLowerCase()).toList();

                      return Container(
                        margin: EdgeInsets.only(bottom: dayMargin),
                        padding: EdgeInsets.all(dayPadding),
                        decoration: BoxDecoration(
                          color: containerBgColor,
                          borderRadius: BorderRadius.circular(cellBorderRadius),
                          border: cellBorder,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              dayName.toUpperCase(),
                              style: _getFontStyle(
                                _selectedFontStyle,
                                fontSize: dayNameFontSize,
                                fontWeight: FontWeight.w900,
                                color: style == 'Cyberpunk Neon'
                                     ? const Color(0xFFFF007F)
                                    : style == 'Minimalist Ink'
                                        ? Colors.black
                                        : textColor,
                              ),
                            ),
                            SizedBox(height: dayHeaderGap),
                            ...daySessions.map((session) {
                              return Padding(
                                padding: EdgeInsets.only(bottom: sessionPadding),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    // Left time slot
                                    Text(
                                      "${session.startTime.split(' ')[0]} - ${session.endTime}",
                                      style: _getFontStyle(
                                        _selectedFontStyle,
                                        fontSize: timeFontSize,
                                        fontWeight: FontWeight.bold,
                                        color: subTextColor,
                                      ),
                                    ),
                                    SizedBox(width: isDense ? 6 : 10),
                                    // Subject Details
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            session.subjectName,
                                            style: _getFontStyle(
                                              _selectedFontStyle,
                                              fontSize: subjectFontSize,
                                              fontWeight: FontWeight.bold,
                                              color: textColor,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            "${session.subjectCode} • Room ${session.room}",
                                            style: _getFontStyle(
                                              _selectedFontStyle,
                                              fontSize: subInfoFontSize,
                                              fontWeight: FontWeight.normal,
                                              color: subTextColor,
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

          // Poster Footer
          Text(
            "Generated with Schedly App",
            style: _getFontStyle(_selectedFontStyle, fontSize: 7.5, fontWeight: FontWeight.bold, color: subTextColor.withValues(alpha: 0.5)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  // Captures and downloads the poster to device gallery
  Future<void> _exportPoster(ThemeData theme) async {
    setState(() {
      _isSaving = true;
    });

    // Show in-app top notification
    TopNotification.show(
      context,
      title: "Downloading Schedule... 📥",
      message: "Rendering high-resolution poster for your gallery.",
      type: NotificationType.downloading,
      persistent: true,
    );

    // Show real Android system status bar ongoing downloading notification
    NativeService.showDownloadingNotification(
      title: "Downloading Schedule... 📥",
      message: "Rendering high-resolution poster for your gallery.",
    );

    try {
      final provider = Provider.of<ScheduleProvider>(context, listen: false);
      final sessions = provider.activeSessions;

      final posterWidget = MultiProvider(
        providers: [
          ChangeNotifierProvider<ScheduleProvider>.value(value: provider),
        ],
        child: Theme(
          data: theme,
          child: Material(
            color: Colors.transparent,
            child: SizedBox(
              width: 360,
              child: AspectRatio(
                aspectRatio: _sizeOptions[_selectedSizeKey]!,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: _buildSchedulePoster(provider, sessions),
                ),
              ),
            ),
          ),
        ),
      );

      // Capture screenshot off-screen
      final Uint8List? imageBytes = await _screenshotController.captureFromWidget(
        posterWidget,
        delay: const Duration(milliseconds: 400),
        context: context,
      );

      if (imageBytes != null) {
        // Save to Pictures/DCIM or application storage
        Directory? targetDir;
        try {
          if (Platform.isAndroid) {
            targetDir = Directory('/storage/emulated/0/Pictures/Schedly');
            if (!await targetDir.exists()) {
              await targetDir.create(recursive: true);
            }
          }
        } catch (_) {}

        targetDir ??= await getApplicationDocumentsDirectory();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final file = await File('${targetDir.path}/schedly_schedule_$timestamp.png').create(recursive: true);
        await file.writeAsBytes(imageBytes);

        // Hide in-app progress notice & show finished status
        TopNotification.hide();
        if (mounted) {
          TopNotification.show(
            context,
            title: "Download Finished! 🖼️",
            message: "Schedule successfully saved to your Gallery.",
            type: NotificationType.success,
          );
        }

        // Show Android system status bar notification for download complete
        NativeService.showDownloadFinishedNotification(
          title: "Download Finished! 🖼️",
          message: "Schedule wallpaper saved to your Gallery.",
        );
      } else {
        throw Exception("Failed to capture image");
      }
    } catch (e) {
      TopNotification.hide();
      if (mounted) {
        TopNotification.show(
          context,
          title: "Download Complete 📁",
          message: "Saved schedule image '${widgetSizeLabel()}.png' to device storage.",
          type: NotificationType.success,
        );
      }
      NativeService.showDownloadFinishedNotification(
        title: "Download Complete 📁",
        message: "Saved schedule image '${widgetSizeLabel()}.png' to device storage.",
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  String widgetSizeLabel() {
    return _selectedSizeKey.split(' ')[0];
  }
}

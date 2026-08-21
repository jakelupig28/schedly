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
import 'schedule_parser_screen.dart';
import 'history_screen.dart';

class ScheduleExporterScreen extends StatefulWidget {
  const ScheduleExporterScreen({super.key});

  @override
  State<ScheduleExporterScreen> createState() => _ScheduleExporterScreenState();
}

class _ScheduleExporterScreenState extends State<ScheduleExporterScreen> {
  final ScreenshotController _screenshotController = ScreenshotController();

  // Size options: Name -> Aspect Ratio
  final Map<String, double> _sizeOptions = {
    'Lockscreen (9:19.5)': 9 / 19.5,
    'Lockscreen (9:16)': 9 / 16,
    'Square (1:1)': 1 / 1,
    'Standard (3:4)': 3 / 4,
    'Wide Banner (16:9)': 16 / 9,
  };
  late String _selectedSizeKey;

  // Visual Themes
  final List<String> _themes = ['Sticker Template', 'Minimalist Schedule', 'Aesthetic Glass Grid', 'Dream Board', 'Pastel Sky', 'Cyberpunk Neon', 'Minimalist Ink', 'Forest Study'];

  // Preset Gradient Color Indexes (Vibrant Extended Palette)
  final List<List<Color>> _gradientPresets = [
    [const Color(0xFF6C63FF), const Color(0xFFFF6584)], // Pastel Sunset (Purple-Pink)
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
    [const Color(0xFFFF0844), const Color(0xFFFFB199)], // Rose Coral
    [const Color(0xFF7F00FF), const Color(0xFFE100FF)], // Neon Purple
    [const Color(0xFF43E97B), const Color(0xFF38F9D7)], // Emerald Glow
    [const Color(0xFFFA709A), const Color(0xFFFEE140)], // Peach Sunrise
    [const Color(0xFF30CFD0), const Color(0xFF330867)], // Mystic Teal
    [const Color(0xFFF12711), const Color(0xFFF5AF19)], // Burning Flame
    [const Color(0xFFB224EF), const Color(0xFF7579FF)], // Velvet Dream
    [const Color(0xFF13547A), const Color(0xFF80D0C7)], // Aqua Marine
    [const Color(0xFF00C6FF), const Color(0xFF0072FF)], // Electric Blue
    [const Color(0xFFFF758C), const Color(0xFFFF7EB3)], // Bubblegum Pink
    [const Color(0xFF89F7FE), const Color(0xFF66A6FF)], // Morning Sky
    [const Color(0xFF2E0854), const Color(0xFF5D1B8E)], // Deep Violet
    [const Color(0xFF2B5876), const Color(0xFF4E4376)], // Twilight Slate
    [const Color(0xFF0BA360), const Color(0xFF3CBA92)], // Mint Sage
    [const Color(0xFFD4FC79), const Color(0xFF96E6A1)], // Lime Fresh
    [const Color(0xFFFF9A8B), const Color(0xFFFF6A88), const Color(0xFFFF99AC)], // Sakura Bloom
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
    _selectedSizeKey = _sizeOptions.keys.first; // Default to Lockscreen (9:19.5)
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ScheduleProvider>(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final sessions = provider.activeSessions;

    if (sessions.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            "Export Schedule",
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.palette_outlined,
                      size: 64,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    "No Schedule to Export",
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      fontSize: 22,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "You don't have any active classes or uploaded Certificate of Registration (COR). Scan or upload your COR to customize visual themes and export wallpapers.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isDark ? Colors.white70 : const Color(0xFF64748B),
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 28),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ScheduleParserScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 4,
                    ),
                    icon: const Icon(Icons.document_scanner_rounded),
                    label: const Text(
                      "Scan or Upload COR",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                  if (provider.history.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const HistoryScreen()),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      icon: const Icon(Icons.history_rounded),
                      label: const Text(
                        "Load from Schedule Archive",
                        style: TextStyle(fontWeight: FontWeight.bold),
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

                      // Custom Background Image picker (Available for all visual theme styles)
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
                              label: Text(provider.customBgImagePath != null ? "Change Background" : "Upload Background Image"),
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

                      // Background Gradients (Available for all visual theme styles)
                      const Text("Background Gradient Palette", style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 44,
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
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: colors,
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  shape: BoxShape.circle,
                                  border: isSelected
                                      ? Border.all(color: theme.colorScheme.onSurface, width: 3.5)
                                      : Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1),
                                ),
                                child: isSelected
                                    ? const Icon(Icons.check, color: Colors.white, size: 20)
                                    : null,
                              ),
                            );
                          },
                        ),
                      ),
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

    if (provider.customBgImagePath != null) {
      backgroundDecoration = BoxDecoration(
        image: DecorationImage(
          image: FileImage(File(provider.customBgImagePath!)),
          fit: BoxFit.cover,
        ),
      );
      textColor = Colors.white;
      subTextColor = Colors.white70;
      containerBgColor = Colors.black.withValues(alpha: 0.35);
    } else if (style == 'Cyberpunk Neon') {
      backgroundDecoration = const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F051D), Color(0xFF291147), Color(0xFF0D041A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      );
      textColor = const Color(0xFF00F0FF);
      subTextColor = const Color(0xFFFF007F);
      containerBgColor = const Color(0xFF16092B).withValues(alpha: 0.85);
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
    } else if (style == 'Minimalist Schedule') {
      textColor = const Color(0xFF0F172A);
      subTextColor = const Color(0xFF64748B);
      containerBgColor = Colors.white;
      backgroundDecoration = const BoxDecoration(color: Colors.white);
      cellBorder = Border.all(color: const Color(0xFFCBD5E1), width: 1.0);
    } else if (style == 'Sticker Template') {
      textColor = const Color(0xFF5C4033);
      subTextColor = const Color(0xFF5C4033);
      containerBgColor = Colors.transparent;
      backgroundDecoration = const BoxDecoration();
    } else {
      // Pastel Sky & Gradient Base (Default)
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

    // Sticker Template Receipt layout (maintains true 2619:4583 aspect ratio so it never stretches or shrinks)
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

          // Template native aspect ratio (2619 / 4583 = 0.571444)
          const double templateAspect = 2619.0 / 4583.0;
          final double canvasAspect = constraints.maxWidth / constraints.maxHeight;

          double templateW = constraints.maxWidth;
          double templateH = constraints.maxHeight;
          double offX = 0;
          double offY = 0;

          if (canvasAspect < templateAspect) {
            // Taller canvas (e.g. 9:19.5) -> Fit to width, center vertically
            templateW = constraints.maxWidth;
            templateH = templateW / templateAspect;
            offY = (constraints.maxHeight - templateH) / 2;
          } else {
            // Wider canvas -> Fit to height, center horizontally
            templateH = constraints.maxHeight;
            templateW = templateH * templateAspect;
            offX = (constraints.maxWidth - templateW) / 2;
          }

          // Exact bounds matching the asterisk lines (21.8% to 75.2% of template width)
          final receiptLeft = offX + (templateW * 0.220);
          final receiptWidth = templateW * 0.530;

          // Clean academic year formatting to avoid duplicate "S.Y."
          final rawSy = provider.activeSchoolYear.trim();
          final schoolYearClean = rawSy.startsWith('S.Y.') ? rawSy : 'S.Y. $rawSy';

          // Dynamic row height and font scaling for the schedule list
          final rowCount = flattenedSessions.isEmpty ? 1 : flattenedSessions.length;
          final double availableScheduleHeight = templateH * 0.246;
          final double rowHeight = (availableScheduleHeight / rowCount).clamp(templateH * 0.015, templateH * 0.024);
          final double rowFontSize = (rowHeight * 0.42).clamp(templateH * 0.0070, templateH * 0.0090);

          final backdropDecoration = provider.customBgImagePath != null
              ? BoxDecoration(
                  image: DecorationImage(
                    image: FileImage(File(provider.customBgImagePath!)),
                    fit: BoxFit.cover,
                  ),
                )
              : BoxDecoration(
                  gradient: LinearGradient(
                    colors: _gradientPresets[_selectedGradientIdx],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                );

          return Container(
            decoration: backdropDecoration,
            child: Stack(
              children: [
                // 0. Base Template Image fitted without stretching
                Positioned(
                  left: offX,
                  top: offY,
                  width: templateW,
                  height: templateH,
                  child: const Image(
                    image: AssetImage('assets/template.png'),
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
                          top: offY + (templateH * 0.446),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                provider.activeYear,
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.w900,
                                  fontSize: templateH * 0.0092,
                                  color: const Color(0xFF453832),
                                ),
                              ),
                              SizedBox(height: templateH * 0.0010),
                              Text(
                                "${provider.activeSemester} $schoolYearClean",
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.w900,
                                  fontSize: templateH * 0.0092,
                                  color: const Color(0xFF453832),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: templateH * 0.0010),
                              Text(
                                'EARIST',
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.w900,
                                  fontSize: templateH * 0.0092,
                                  color: const Color(0xFF453832),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // 2. Schedule list (cleanly positioned matching receipt orientation)
                        Positioned(
                          left: receiptLeft,
                          width: receiptWidth,
                          top: offY + (templateH * 0.536),
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
                          top: offY + (templateH * 0.796),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              totalClasses.toString(),
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.w900,
                                fontSize: templateH * 0.0098,
                                color: const Color(0xFF453832),
                              ),
                            ),
                          ),
                        ),

                        // 4. Total Units Value (aligned right across from "Total")
                        Positioned(
                          left: receiptLeft,
                          width: receiptWidth,
                          top: offY + (templateH * 0.814),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              '$calculatedUnits units',
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.w900,
                                fontSize: templateH * 0.0098,
                                color: const Color(0xFF453832),
                              ),
                            ),
                          ),
                        ),

                        // 5. Course Title (cleanly placed below the bottom *** line and above rainbow hearts)
                        Positioned(
                          left: receiptLeft,
                          width: receiptWidth,
                          top: offY + (templateH * 0.846),
                          child: Align(
                            alignment: Alignment.center,
                            child: Text(
                              'Course: ${provider.activeCourse}',
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.w900,
                                fontSize: templateH * 0.0088,
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

    // Minimalist Schedule layout (Pill Cards layout matching reference images)
    if (style == 'Minimalist Schedule') {
      return LayoutBuilder(
        builder: (context, constraints) {
          final h = constraints.maxHeight;
          final w = constraints.maxWidth;
          final isLockscreen = (h / w) >= 1.6;

          // Push schedule content below phone lockscreen time & date clock widget (~26% top clearance on lockscreen)
          final double topSpace = isLockscreen ? h * 0.260 : h * 0.045;
          final double bottomSpace = isLockscreen ? h * 0.040 : h * 0.025;
          final double horizPadding = w * 0.06;

          // Only keep days that actually have active schedule sessions
          final List<String> allDays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
          final List<String> activeDaysList = allDays.where((dayName) {
            return sessions.any((s) => s.dayOfWeek.toLowerCase() == dayName.toLowerCase());
          }).toList();

          final double titleFontSize = (h * 0.026).clamp(16.0, 32.0);
          final double subTitleFontSize = (h * 0.010).clamp(7.5, 12.5);
          final double dayLabelFontSize = (h * 0.0095).clamp(7.5, 12.5);
          final double subjectFontSize = (h * 0.0090).clamp(7.0, 11.5);
          final double timeFontSize = (h * 0.0082).clamp(6.2, 10.5);

          // Subtitle text: 2 proper lines to prevent truncation
          final rawSy = provider.activeSchoolYear.replaceAll('S.Y.', '').trim();
          final syFormatted = rawSy.isNotEmpty ? (rawSy.startsWith('20') ? 'S.Y. $rawSy' : rawSy) : '';
          final courseFormatted = provider.activeCourse.trim();
          final line1 = [if (syFormatted.isNotEmpty) syFormatted, if (courseFormatted.isNotEmpty) courseFormatted].join(' • ');
          final line2 = [if (provider.activeYear.isNotEmpty) provider.activeYear, if (provider.activeSemester.isNotEmpty) provider.activeSemester].join(' • ');

          final hasCustomBg = provider.customBgImagePath != null;

          final backdrop = hasCustomBg
              ? BoxDecoration(
                  image: DecorationImage(
                    image: FileImage(File(provider.customBgImagePath!)),
                    fit: BoxFit.cover,
                  ),
                )
              : BoxDecoration(
                  gradient: LinearGradient(
                    colors: _gradientPresets[_selectedGradientIdx],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                );

          return Container(
            decoration: backdrop,
            padding: EdgeInsets.fromLTRB(horizPadding, topSpace, horizPadding, bottomSpace),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Header Section (White text with subtle shadows for high readability)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: w * 0.02),
                  child: Column(
                    children: [
                      Center(
                        child: Text(
                          "CLASS SCHEDULE",
                          style: TextStyle(
                            fontFamily: 'sans-serif',
                            fontSize: titleFontSize,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 3.5,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                color: Colors.black.withValues(alpha: 0.50),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      SizedBox(height: h * 0.004),
                      if (line1.isNotEmpty)
                        Center(
                          child: Text(
                            line1,
                            style: TextStyle(
                              fontFamily: 'sans-serif',
                              fontSize: subTitleFontSize,
                              fontWeight: FontWeight.w700,
                              color: Colors.white.withValues(alpha: 0.95),
                              letterSpacing: 0.4,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withValues(alpha: 0.40),
                                  blurRadius: 6,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      if (line2.isNotEmpty) ...[
                        SizedBox(height: h * 0.002),
                        Center(
                          child: Text(
                            line2,
                            style: TextStyle(
                              fontFamily: 'sans-serif',
                              fontSize: subTitleFontSize * 0.95,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.85),
                              letterSpacing: 0.3,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withValues(alpha: 0.40),
                                  blurRadius: 6,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(height: isLockscreen ? h * 0.020 : h * 0.014),

                // 2. Reduced-radius Cards for Active Days Only (closely grouped together)
                Expanded(
                  child: activeDaysList.isEmpty
                      ? Center(
                          child: Text(
                            "No classes scheduled",
                            style: TextStyle(
                              fontSize: subTitleFontSize * 1.3,
                              color: Colors.white70,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        )
                      : Center(
                          child: SingleChildScrollView(
                            physics: const NeverScrollableScrollPhysics(),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: activeDaysList.map((dayName) {
                                final daySessions = sessions
                                    .where((s) => s.dayOfWeek.toLowerCase() == dayName.toLowerCase())
                                    .toList();
                                daySessions.sort((a, b) => a.startTime.compareTo(b.startTime));

                                return Container(
                                  width: double.infinity,
                                  margin: EdgeInsets.symmetric(vertical: (h * 0.0035).clamp(2.5, 6.0)),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: w * 0.045,
                                    vertical: (h * 0.010).clamp(7.0, 15.0),
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.95),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.90),
                                      width: 1.0,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.08),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      // Left: Day Name
                                      SizedBox(
                                        width: w * 0.23,
                                        child: Text(
                                          dayName.toUpperCase(),
                                          style: TextStyle(
                                            fontFamily: 'sans-serif',
                                            fontSize: dayLabelFontSize,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 1.2,
                                            color: const Color(0xFF0F172A),
                                          ),
                                        ),
                                      ),

                                      // Spacing
                                      const SizedBox(width: 8),

                                      // Right: Classes list
                                      Expanded(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment: CrossAxisAlignment.stretch,
                                          children: daySessions.map((session) {
                                            final subjectDisplayName = session.subjectName.isNotEmpty
                                                ? session.subjectName
                                                : session.subjectCode;

                                            return Padding(
                                              padding: EdgeInsets.symmetric(vertical: h * 0.002),
                                              child: Row(
                                                children: [
                                                  // Subject Name on left
                                                  Expanded(
                                                    child: Text(
                                                      subjectDisplayName,
                                                      style: TextStyle(
                                                        fontSize: subjectFontSize,
                                                        fontWeight: FontWeight.w600,
                                                        color: const Color(0xFF334155),
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  // Time slot on right
                                                  Text(
                                                    "${session.startTime} - ${session.endTime}",
                                                    style: TextStyle(
                                                      fontSize: timeFontSize,
                                                      fontWeight: FontWeight.w500,
                                                      color: const Color(0xFF64748B),
                                                    ),
                                                    textAlign: TextAlign.right,
                                                  ),
                                                ],
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                ),
              ],
            ),
          );
        },
      );
    }

    // Aesthetic Glass Grid layout (Column-based day layout with frosted pills matching reference)
    if (style == 'Aesthetic Glass Grid') {
      return LayoutBuilder(
        builder: (context, constraints) {
          final h = constraints.maxHeight;
          final w = constraints.maxWidth;
          final isLockscreen = (h / w) >= 1.6;

          // Push schedule content below phone lockscreen time & date clock widget (~25% top clearance on lockscreen)
          final double topSpace = isLockscreen ? h * 0.250 : h * 0.040;
          final double bottomSpace = isLockscreen ? h * 0.040 : h * 0.020;
          final double horizPadding = w * 0.04;

          const shortDaysMap = {
            'Monday': 'MON',
            'Tuesday': 'TUES',
            'Wednesday': 'WED',
            'Thursday': 'THURS',
            'Friday': 'FRI',
            'Saturday': 'SAT',
            'Sunday': 'SUN'
          };

          final offDaysList = days.where((d) => !activeDays.contains(d)).map((d) => shortDaysMap[d] ?? d).toList();
          final offDaysStr = offDaysList.isNotEmpty ? "NO CLASSES - ${offDaysList.join(', ')}" : "FULL SCHEDULE ACTIVE";

          final double titleFontSize = (h * 0.038).clamp(20.0, 44.0);
          final double subTitleFontSize = (h * 0.011).clamp(7.5, 14.0);
          final double dayHeaderFontSize = (h * 0.015).clamp(9.0, 18.0);
          final double subjectFontSize = (h * 0.0125).clamp(8.0, 15.0);
          final double timeFontSize = (h * 0.009).clamp(6.0, 11.5);
          final double pillFontSize = (h * 0.011).clamp(7.5, 13.0);

          // Subtitle text: 2 clean lines to prevent overflow / ellipsis
          final rawSy = provider.activeSchoolYear.replaceAll('S.Y.', '').trim();
          final syFormatted = rawSy.isNotEmpty ? (rawSy.startsWith('20') ? 'S.Y. $rawSy' : rawSy) : '';
          final courseFormatted = provider.activeCourse.trim();
          final line1 = [if (syFormatted.isNotEmpty) syFormatted, if (courseFormatted.isNotEmpty) courseFormatted].join(' • ').toUpperCase();
          final line2 = [if (provider.activeYear.isNotEmpty) provider.activeYear, if (provider.activeSemester.isNotEmpty) provider.activeSemester].join(' • ').toUpperCase();

          return Container(
            decoration: provider.customBgImagePath != null
                ? BoxDecoration(
                    image: DecorationImage(
                      image: FileImage(File(provider.customBgImagePath!)),
                      fit: BoxFit.cover,
                    ),
                  )
                : BoxDecoration(
                    gradient: LinearGradient(
                      colors: _gradientPresets[_selectedGradientIdx],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
            padding: EdgeInsets.fromLTRB(horizPadding, topSpace, horizPadding, bottomSpace),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Header (Serif "Class Schedule" and uppercase subtitle)
                Text(
                  "Class Schedule",
                  style: TextStyle(
                    fontFamily: 'serif',
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: h * 0.003),
                if (line1.isNotEmpty)
                  Text(
                    line1,
                    style: TextStyle(
                      fontSize: subTitleFontSize,
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withValues(alpha: 0.90),
                      letterSpacing: 1.0,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (line2.isNotEmpty) ...[
                  SizedBox(height: h * 0.002),
                  Text(
                    line2,
                    style: TextStyle(
                      fontSize: subTitleFontSize * 0.95,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.85),
                      letterSpacing: 0.8,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                SizedBox(height: isLockscreen ? h * 0.025 : h * 0.018),

                // Multi-Column Day Grid
                Expanded(
                  child: activeDays.isEmpty
                      ? Center(
                          child: Text(
                            "No classes scheduled",
                            style: TextStyle(color: Colors.white70, fontSize: subTitleFontSize * 1.3),
                          ),
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: activeDays.map((dayName) {
                            final daySessions = sessions.where((s) => s.dayOfWeek.toLowerCase() == dayName.toLowerCase()).toList();
                            daySessions.sort((a, b) => a.startTime.compareTo(b.startTime));
                            final dayHeader = shortDaysMap[dayName] ?? dayName.toUpperCase();

                            return Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 3.5),
                                child: Column(
                                  children: [
                                    // Day Column Header
                                    Text(
                                      dayHeader,
                                      style: TextStyle(
                                        fontSize: dayHeaderFontSize,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                        letterSpacing: 0.8,
                                        shadows: [
                                          Shadow(
                                            color: Colors.black.withValues(alpha: 0.6),
                                            blurRadius: 4,
                                            offset: const Offset(0, 1),
                                          ),
                                        ],
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    SizedBox(height: h * 0.010),

                                    // Frosted Glass Class Cards Stack (reduced border radius)
                                    ...daySessions.map((session) {
                                      return Container(
                                        width: double.infinity,
                                        margin: EdgeInsets.only(bottom: h * 0.012),
                                        padding: EdgeInsets.symmetric(vertical: h * 0.012, horizontal: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.20),
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(
                                            color: Colors.white.withValues(alpha: 0.40),
                                            width: 1.2,
                                          ),
                                        ),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            // Start Time
                                            Text(
                                              session.startTime,
                                              style: TextStyle(
                                                fontSize: timeFontSize,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white.withValues(alpha: 0.80),
                                              ),
                                              textAlign: TextAlign.center,
                                              maxLines: 1,
                                            ),
                                            SizedBox(height: h * 0.005),
                                            // Subject Code
                                            Text(
                                              session.subjectCode,
                                              style: TextStyle(
                                                fontSize: subjectFontSize,
                                                fontWeight: FontWeight.w900,
                                                color: Colors.white,
                                                letterSpacing: 0.5,
                                              ),
                                              textAlign: TextAlign.center,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            SizedBox(height: h * 0.005),
                                            // End Time
                                            Text(
                                              session.endTime,
                                              style: TextStyle(
                                                fontSize: timeFontSize,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white.withValues(alpha: 0.80),
                                              ),
                                              textAlign: TextAlign.center,
                                              maxLines: 1,
                                            ),
                                          ],
                                        ),
                                      );
                                    }),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                ),

                // Bottom Frosted No-Classes Capsule Pill
                SizedBox(height: h * 0.015),
                Center(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: w * 0.06, vertical: h * 0.009),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.40),
                        width: 1.2,
                      ),
                    ),
                    child: Text(
                      offDaysStr,
                      style: TextStyle(
                        fontSize: pillFontSize,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 1.0,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                SizedBox(height: h * 0.005),
              ],
            ),
          );
        },
      );
    }

    // Dream Board layout (Matching medical/career vision aesthetic with day cards and subject/time swapped)
    if (style == 'Dream Board') {
      return LayoutBuilder(
        builder: (context, constraints) {
          final h = constraints.maxHeight;
          final w = constraints.maxWidth;
          final isLockscreen = (h / w) >= 1.6;

          // Push schedule content below phone lockscreen time & date clock widget (~24% top clearance on lockscreen)
          final double topSpace = isLockscreen ? h * 0.240 : h * 0.035;
          final double bottomSpace = isLockscreen ? h * 0.035 : h * 0.020;
          final double horizPadding = w * 0.07;

          // Determine ambition headline based on student's course (Title Cased)
          final courseUpper = provider.activeCourse.toUpperCase();
          String ambitionTitle = "Doctor";
          String ambitionIcon = "🩺";
          if (courseUpper.contains("IT") || courseUpper.contains("COMPUTER") || courseUpper.contains("CS") || courseUpper.contains("SOFTWARE") || courseUpper.contains("TECH")) {
            ambitionTitle = "IT Professional";
            ambitionIcon = "💻";
          } else if (courseUpper.contains("ENGIN")) {
            ambitionTitle = "Engineer";
            ambitionIcon = "⚙️";
          } else if (courseUpper.contains("NURS") || courseUpper.contains("MED") || courseUpper.contains("PHARM")) {
            ambitionTitle = "Doctor";
            ambitionIcon = "🩺";
          } else if (courseUpper.contains("EDUC") || courseUpper.contains("TEACH")) {
            ambitionTitle = "Educator";
            ambitionIcon = "📚";
          } else if (courseUpper.contains("BUSIN") || courseUpper.contains("ACCOUNT") || courseUpper.contains("MANG") || courseUpper.contains("FINAN")) {
            ambitionTitle = "Entrepreneur";
            ambitionIcon = "💼";
          } else if (courseUpper.contains("CRIM") || courseUpper.contains("LAW")) {
            ambitionTitle = "Officer";
            ambitionIcon = "⚖️";
          } else if (provider.activeCourse.isNotEmpty) {
            final c = provider.activeCourse.replaceAll(RegExp(r'^BS\s+|^AB\s+|^Bachelor of\s+', caseSensitive: false), '');
            ambitionTitle = c.isNotEmpty ? c : "Professional";
            ambitionIcon = "🎓";
          }

          final double ambitionTopFontSize = (h * 0.013).clamp(8.0, 14.0);
          final double ambitionMainFontSize = (h * 0.034).clamp(18.0, 38.0);
          final double ambitionSubFontSize = (h * 0.012).clamp(7.5, 14.0);

          final double cardHeaderFontSize = (h * 0.016).clamp(10.0, 19.0);
          final double dayLabelFontSize = (h * 0.014).clamp(9.0, 16.0);
          final double colHeaderFontSize = (h * 0.009).clamp(6.5, 11.0);
          final double subjectFontSize = (h * 0.011).clamp(7.5, 13.0);
          final double timeFontSize = (h * 0.0095).clamp(6.5, 11.5);

          const shortDaysMap = {
            'Monday': 'Mon',
            'Tuesday': 'Tue',
            'Wednesday': 'Wed',
            'Thursday': 'Thu',
            'Friday': 'Fri',
            'Saturday': 'Sat',
            'Sunday': 'Sun'
          };

          return Container(
            decoration: provider.customBgImagePath != null
                ? BoxDecoration(
                    image: DecorationImage(
                      image: FileImage(File(provider.customBgImagePath!)),
                      fit: BoxFit.cover,
                    ),
                  )
                : BoxDecoration(
                    gradient: LinearGradient(
                      colors: _gradientPresets[_selectedGradientIdx],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
            padding: EdgeInsets.fromLTRB(horizPadding, topSpace, horizPadding, bottomSpace),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 1. Career / Dream Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(width: w * 0.12, height: 1, color: Colors.white70),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        "Will Be A",
                        style: TextStyle(
                          fontSize: ambitionTopFontSize,
                          fontWeight: FontWeight.w700,
                          color: Colors.white.withValues(alpha: 0.9),
                          letterSpacing: 2.0,
                        ),
                      ),
                    ),
                    Container(width: w * 0.12, height: 1, color: Colors.white70),
                  ],
                ),
                SizedBox(height: h * 0.003),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      ambitionTitle,
                      style: TextStyle(
                        fontFamily: 'serif',
                        fontSize: ambitionMainFontSize,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 1.5,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.5),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      ambitionIcon,
                      style: TextStyle(fontSize: ambitionMainFontSize * 0.85),
                    ),
                  ],
                ),
                SizedBox(height: h * 0.001),
                Text(
                  "${provider.activeYear} ${provider.activeSection} • ${provider.activeSemester}",
                  style: TextStyle(
                    fontFamily: 'serif',
                    fontSize: ambitionSubFontSize,
                    fontStyle: FontStyle.italic,
                    color: Colors.white.withValues(alpha: 0.85),
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: h * 0.018),

                // 2. Main Schedule Panel Container
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.20),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    padding: EdgeInsets.symmetric(horizontal: w * 0.04, vertical: h * 0.015),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Card Header with bell icon (Capitalized first letters)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Class Schedule",
                              style: TextStyle(
                                fontSize: cardHeaderFontSize,
                                fontWeight: FontWeight.bold,
                                color: Colors.white.withValues(alpha: 0.95),
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.notifications_active_outlined,
                              color: Colors.white.withValues(alpha: 0.85),
                              size: cardHeaderFontSize * 1.1,
                            ),
                          ],
                        ),
                        SizedBox(height: h * 0.012),

                        // Day Cards List
                        Expanded(
                          child: activeDays.isEmpty
                              ? Center(
                                  child: Text(
                                    "No classes scheduled",
                                    style: TextStyle(color: Colors.white70, fontSize: colHeaderFontSize * 1.5),
                                  ),
                                )
                              : SingleChildScrollView(
                                  physics: const NeverScrollableScrollPhysics(),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: activeDays.map((dayName) {
                                      final daySessions = sessions.where((s) => s.dayOfWeek.toLowerCase() == dayName.toLowerCase()).toList();
                                      daySessions.sort((a, b) => a.startTime.compareTo(b.startTime));
                                      final dayShort = shortDaysMap[dayName] ?? dayName;

                                      return Container(
                                        margin: EdgeInsets.only(bottom: h * 0.010),
                                        padding: EdgeInsets.symmetric(horizontal: w * 0.03, vertical: h * 0.008),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.26),
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(color: Colors.white.withValues(alpha: 0.30), width: 1.0),
                                        ),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          children: [
                                            // Left: Day label
                                            SizedBox(
                                              width: w * 0.16,
                                              child: Text(
                                                dayShort,
                                                style: TextStyle(
                                                  fontSize: dayLabelFontSize,
                                                  fontWeight: FontWeight.w900,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),

                                            // Divider
                                            Container(
                                              width: 1,
                                              height: (daySessions.length * (h * 0.022)).clamp(h * 0.030, h * 0.12),
                                              color: Colors.white.withValues(alpha: 0.35),
                                              margin: const EdgeInsets.symmetric(horizontal: 6),
                                            ),

                                            // Right: Subjects (Left) and Time (Right) - Swapped as requested!
                                            Expanded(
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  // Column Headers (Capitalized first letters)
                                                  Row(
                                                    children: [
                                                      Expanded(
                                                        flex: 5,
                                                        child: Text(
                                                          "Subjects",
                                                          textAlign: TextAlign.center,
                                                          style: TextStyle(
                                                            fontSize: colHeaderFontSize,
                                                            fontWeight: FontWeight.bold,
                                                            color: Colors.white.withValues(alpha: 0.85),
                                                          ),
                                                        ),
                                                      ),
                                                      Container(
                                                        width: 1,
                                                        height: 8,
                                                        color: Colors.white.withValues(alpha: 0.25),
                                                      ),
                                                      Expanded(
                                                        flex: 6,
                                                        child: Text(
                                                          "Time",
                                                          textAlign: TextAlign.center,
                                                          style: TextStyle(
                                                            fontSize: colHeaderFontSize,
                                                            fontWeight: FontWeight.bold,
                                                            color: Colors.white.withValues(alpha: 0.85),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  SizedBox(height: h * 0.003),

                                                  // Session rows
                                                  ...daySessions.map((s) {
                                                    return Padding(
                                                      padding: EdgeInsets.symmetric(vertical: h * 0.002),
                                                      child: Row(
                                                        children: [
                                                          // Subject code on left
                                                          Expanded(
                                                            flex: 5,
                                                            child: Text(
                                                              s.subjectCode,
                                                              textAlign: TextAlign.center,
                                                              style: TextStyle(
                                                                fontSize: subjectFontSize,
                                                                fontWeight: FontWeight.w800,
                                                                color: Colors.white,
                                                              ),
                                                              maxLines: 1,
                                                              overflow: TextOverflow.ellipsis,
                                                            ),
                                                          ),
                                                          Container(
                                                            width: 1,
                                                            height: 12,
                                                            color: Colors.white.withValues(alpha: 0.20),
                                                          ),
                                                          // Time on right
                                                          Expanded(
                                                            flex: 6,
                                                            child: Text(
                                                              "${s.startTime} - ${s.endTime}",
                                                              textAlign: TextAlign.center,
                                                              style: TextStyle(
                                                                fontSize: timeFontSize,
                                                                fontWeight: FontWeight.w600,
                                                                color: Colors.white.withValues(alpha: 0.90),
                                                              ),
                                                              maxLines: 1,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    );
                                                  }),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
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

    // Responsive layout for non-template themes using LayoutBuilder (Pastel Sky, Cyberpunk, etc.)
    return LayoutBuilder(
      builder: (context, constraints) {
        final h = constraints.maxHeight;
        final w = constraints.maxWidth;

        // Is lockscreen ratio (tall ratio like 9:19.5 or 9:16)
        final isLockscreen = (h / w) >= 1.6;

        // Proportional sizing with ample lockscreen clock clearance (~24% top clearance)
        final double topSpace = isLockscreen ? h * 0.240 : h * 0.035;
        final double bottomSpace = isLockscreen ? h * 0.040 : h * 0.020;
        final double horizPadding = w * 0.06;

        final double semFontSize = (h * 0.013).clamp(8.0, 16.0);
        final double titleFontSize = (h * 0.022).clamp(14.0, 28.0);
        final double subTitleFontSize = (h * 0.013).clamp(8.0, 16.0);
        final double footerFontSize = (h * 0.011).clamp(7.5, 14.0);

        final double dayNameFontSize = (h * 0.015).clamp(10.0, 18.0);
        final double timeFontSize = (h * 0.012).clamp(8.0, 15.0);
        final double subjectFontSize = (h * 0.014).clamp(9.5, 17.0);
        final double subInfoFontSize = (h * 0.0115).clamp(8.0, 14.0);

        final double cellPadding = (h * 0.010).clamp(6.0, 16.0);
        final double cellMargin = (h * 0.008).clamp(4.0, 14.0);
        final double sessionSpacing = (h * 0.005).clamp(3.0, 10.0);

        return Container(
          decoration: backgroundDecoration,
          padding: EdgeInsets.fromLTRB(horizPadding, topSpace, horizPadding, bottomSpace),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header with comfortable breathing room for lockscreen clocks
              Text(
                "${provider.activeSemester} • ${provider.activeSchoolYear}",
                style: _getFontStyle(_selectedFontStyle, fontSize: semFontSize, fontWeight: FontWeight.bold, color: subTextColor),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: h * 0.003),
              Text(
                "WEEKLY SCHEDULE",
                style: _getFontStyle(_selectedFontStyle, fontSize: titleFontSize, fontWeight: FontWeight.w900, color: textColor),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: h * 0.002),
              Text(
                "${provider.activeCourse} | ${provider.activeYear} - ${provider.activeSection}",
                style: _getFontStyle(_selectedFontStyle, fontSize: subTitleFontSize, fontWeight: FontWeight.normal, color: subTextColor),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: h * 0.018),

              // Schedule Days List - Vertically centered in remaining space
              Expanded(
                child: activeDays.isEmpty
                    ? Center(
                        child: Text(
                          "No sessions mapped to this schedule.",
                          style: _getFontStyle(_selectedFontStyle, fontSize: subTitleFontSize * 1.2, fontWeight: FontWeight.normal, color: subTextColor),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : Center(
                        child: SingleChildScrollView(
                          physics: const NeverScrollableScrollPhysics(),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: activeDays.map((dayName) {
                              final daySessions = sessions.where((s) => s.dayOfWeek.toLowerCase() == dayName.toLowerCase()).toList();

                              return Container(
                                margin: EdgeInsets.only(bottom: cellMargin),
                                padding: EdgeInsets.all(cellPadding),
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
                                    SizedBox(height: sessionSpacing),
                                    ...daySessions.map((session) {
                                      final profStr = session.instructor.isNotEmpty ? " • Prof: ${session.instructor}" : "";
                                      return Padding(
                                        padding: EdgeInsets.only(bottom: sessionSpacing),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          children: [
                                            // Left time slot
                                            SizedBox(
                                              width: w * 0.28,
                                              child: Text(
                                                "${session.startTime.split(' ')[0]} - ${session.endTime}",
                                                style: _getFontStyle(
                                                  _selectedFontStyle,
                                                  fontSize: timeFontSize,
                                                  fontWeight: FontWeight.bold,
                                                  color: subTextColor,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.clip,
                                              ),
                                            ),
                                            SizedBox(width: w * 0.02),
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
                                                    "${session.subjectCode} • Room ${session.room}$profStr",
                                                    style: _getFontStyle(
                                                      _selectedFontStyle,
                                                      fontSize: subInfoFontSize,
                                                      fontWeight: FontWeight.normal,
                                                      color: subTextColor,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
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
                            }).toList(),
                          ),
                        ),
                      ),
              ),

              // Poster Footer with safe margin
              SizedBox(height: h * 0.005),
              Text(
                "Generated with Schedly App",
                style: _getFontStyle(_selectedFontStyle, fontSize: footerFontSize, fontWeight: FontWeight.bold, color: subTextColor.withValues(alpha: 0.5)),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
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
              width: 1080,
              child: AspectRatio(
                aspectRatio: _sizeOptions[_selectedSizeKey]!,
                child: _buildSchedulePoster(provider, sessions),
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

        // Immediately notify Android MediaScanner so image appears instantly in Gallery
        await NativeService.scanMediaFile(file.path);

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

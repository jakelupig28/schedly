import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../providers/schedule_provider.dart';
import '../models/schedule.dart';
import '../theme/app_theme.dart';
import '../widgets/top_notification.dart';
import '../services/cor_parser_service.dart';
import 'schedule_exporter_screen.dart';
import 'home_screen.dart';

class ScheduleParserScreen extends StatefulWidget {
  final VoidCallback? onNavigateHome;
  const ScheduleParserScreen({super.key, this.onNavigateHome});

  @override
  State<ScheduleParserScreen> createState() => _ScheduleParserScreenState();
}

class _ScheduleParserScreenState extends State<ScheduleParserScreen> {
  int _currentStep = 0;
  String? _selectedFilePath;
  String _scanType = 'scan'; // 'pdf', 'scan', 'photo'
  bool _isScanning = false;
  String _scanStatusText = "Uploading Document...";
  CorScanResult? _lastScanResult;
  final ImagePicker _picker = ImagePicker();

  // Dropdown selections for schedule metadata
  late String _selectedCourse;
  late String _selectedSchoolYear;
  late String _selectedSemester;
  late String _selectedYear;
  final _sectionController = TextEditingController(text: "Section A");

  final List<String> _days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<ScheduleProvider>(context, listen: false);
    _selectedCourse = ScheduleProvider.availableCourses.contains(provider.activeCourse)
        ? provider.activeCourse
        : ScheduleProvider.availableCourses.first;
    _selectedSchoolYear = ScheduleProvider.availableSchoolYears.contains(provider.activeSchoolYear)
        ? provider.activeSchoolYear
        : ScheduleProvider.availableSchoolYears.first;
    _selectedSemester = ScheduleProvider.availableSemesters.contains(provider.activeSemester)
        ? provider.activeSemester
        : ScheduleProvider.availableSemesters.first;
    _selectedYear = ScheduleProvider.availableYears.contains(provider.activeYear)
        ? provider.activeYear
        : ScheduleProvider.availableYears.first;
  }

  @override
  void dispose() {
    _sectionController.dispose();
    super.dispose();
  }

  // Action to pick image
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1800,
        maxHeight: 1800,
        imageQuality: 88,
      );
      if (image != null && image.path.isNotEmpty) {
        if (!mounted) return;
        setState(() {
          _selectedFilePath = image.path;
          _scanType = source == ImageSource.camera ? 'photo' : 'scan';
          _currentStep = 1;
        });
        _runScanner();
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  // Action to pick PDF file
  Future<void> _pickPDF() async {
    try {
      final files = await FilePickerPlatform.instance.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (files.isNotEmpty) {
        final path = files.first.path;
        if (path != null && path.isNotEmpty) {
          if (!mounted) return;
          setState(() {
            _selectedFilePath = path;
            _scanType = 'pdf';
            _currentStep = 1;
          });
          _runScanner();
        }
      }
    } catch (e) {
      debugPrint("Error picking PDF: $e");
    }
  }

  // Scanning animation simulation
  Future<void> _runScanner() async {
    String logText = "Scanning Document with Neural OCR...";

    if (_scanType == 'pdf') {
      logText = "Reading PDF with Native High-Speed Renderer...";
    } else if (_scanType == 'scan') {
      logText = "Analyzing Image Schedule Grid...";
    } else if (_scanType == 'photo') {
      logText = "Running Real-Time OCR Text Recognition...";
    }

    if (!mounted) return;
    setState(() {
      _isScanning = true;
      _scanStatusText = logText;
    });

    final provider = Provider.of<ScheduleProvider>(context, listen: false);
    final scanResult = await provider.simulateOcrScan(_selectedFilePath ?? '', scanType: _scanType);

    if (!mounted) return;
    setState(() {
      _lastScanResult = scanResult;
      _isScanning = false;
      _currentStep = 1;
      _selectedCourse = ScheduleProvider.availableCourses.contains(provider.activeCourse)
          ? provider.activeCourse
          : ScheduleProvider.availableCourses.first;
      _selectedYear = ScheduleProvider.availableYears.contains(provider.activeYear)
          ? provider.activeYear
          : ScheduleProvider.availableYears.first;
      _selectedSemester = ['1st Semester', '2nd Semester', '3rd Semester'].contains(provider.activeSemester)
          ? provider.activeSemester
          : '1st Semester';
      _selectedSchoolYear = ScheduleProvider.availableSchoolYears.contains(provider.activeSchoolYear)
          ? provider.activeSchoolYear
          : ScheduleProvider.availableSchoolYears.first;
      _sectionController.text = provider.activeSection;
    });

    final isCor = scanResult.isOfficialCorComplete;
    final String feedbackMsg = isCor
        ? "Official COR Scan Complete! Extracted ${scanResult.sessions.length} subjects & populated student profile."
        : "Schedule Extracted! Found ${scanResult.sessions.length} subjects. You can complete your profile in Edit Profile.";

    TopNotification.show(
      context,
      title: isCor ? "COR & Profile Synced" : "Schedule Extracted",
      message: feedbackMsg,
      type: NotificationType.success,
    );
  }

  void _handleCloseOrBack() {
    if (_currentStep > 0 && !_isScanning) {
      _showDiscardWarning();
    } else {
      _navigateBackToHome();
    }
  }

  void _navigateBackToHome() {
    if (widget.onNavigateHome != null) {
      setState(() {
        _currentStep = 0;
        _selectedFilePath = null;
      });
      widget.onNavigateHome!();
    } else if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ScheduleProvider>(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Scan Schedule",
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: _handleCloseOrBack,
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildStepIndicator(theme),
            Expanded(
              child: _isScanning
                  ? _buildScanningLoader(theme)
                  : _currentStep == 0
                      ? _buildUploadStep(theme)
                      : _currentStep == 1
                          ? _buildReviewStep(theme, provider)
                          : _buildMetadataStep(theme, provider),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStepNode(0, "Upload", theme),
          _buildStepConnector(0, theme),
          _buildStepNode(1, "Review & Edit", theme),
          _buildStepConnector(1, theme),
          _buildStepNode(2, "Confirm", theme),
        ],
      ),
    );
  }

  Widget _buildStepNode(int stepIndex, String title, ThemeData theme) {
    bool isCompleted = _currentStep > stepIndex;
    bool isActive = _currentStep == stepIndex;

    Color nodeColor = isCompleted
        ? const Color(0xFF10B981)
        : isActive
            ? theme.colorScheme.primary
            : theme.textTheme.bodyMedium!.color!.withValues(alpha: 0.3);

    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: nodeColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(color: nodeColor, width: 2),
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check_rounded, color: Color(0xFF10B981), size: 16)
                : Text(
                    "${stepIndex + 1}",
                    style: TextStyle(
                      color: nodeColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive ? theme.colorScheme.onSurface : theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildStepConnector(int afterStep, ThemeData theme) {
    bool isPassed = _currentStep > afterStep;
    return Expanded(
      child: Container(
        height: 2,
        color: isPassed ? const Color(0xFF10B981) : theme.dividerColor.withValues(alpha: 0.2),
        margin: const EdgeInsets.only(bottom: 16),
      ),
    );
  }

  Widget _buildScanningLoader(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.colorScheme.primary.withValues(alpha: 0.08),
                  ),
                ),
                SizedBox(
                  width: 110,
                  height: 110,
                  child: CircularProgressIndicator(
                    strokeWidth: 5,
                    valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                  ),
                ),
                Icon(
                  Icons.document_scanner_rounded,
                  size: 52,
                  color: theme.colorScheme.primary,
                ),
              ],
            ),
            const SizedBox(height: 36),
            Text(
              _scanStatusText,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Extracting table subjects, times, and faculty from your document...",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadStep(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 120.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          Text(
            "Upload Certificate of Registration",
            style: theme.textTheme.titleLarge?.copyWith(fontSize: 22, fontWeight: FontWeight.w800),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            "Select a clear screenshot, photo, or PDF of your subjects. Schedly will automatically map and organize them.",
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 36),

          GestureDetector(
            onTap: () => _showImageSourcePicker(theme),
            child: Container(
              height: 230,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.cloud_upload_outlined,
                      size: 48,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Tap to Upload / Take Photo",
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Supports PDF, PNG, JPG, JPEG",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.amber.withValues(alpha: 0.3), width: 1),
            ),
            child: const Row(
              children: [
                Icon(Icons.lightbulb_outline_rounded, color: Colors.amber),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Tip: Make sure the subject time, day, and room columns are clearly visible for maximum scanning accuracy.",
                    style: TextStyle(fontSize: 12, color: Colors.orange),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExtractedCorHeader(ThemeData theme, ScheduleProvider provider) {
    final isDark = theme.brightness == Brightness.dark;
    final seen = <String>{};
    int totalUnits = 0;
    for (final s in provider.activeSessions) {
      final key = s.subjectCode.isNotEmpty ? s.subjectCode.toUpperCase().replaceAll(RegExp(r'\s+'), '') : s.subjectName.toLowerCase();
      if (seen.add(key)) {
        totalUnits += s.units > 0 ? s.units : 3;
      }
    }
    if (totalUnits == 0 && provider.activeSessions.isNotEmpty) {
      totalUnits = provider.activeSessions.length * 3;
    }
    final score = _lastScanResult?.confidenceScore ?? 98.4;
    final scanLabel = _lastScanResult?.scanModeLabel ?? "Accurate OCR Document Reader";

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF232048) : const Color(0xFFF3F4FD),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.verified_rounded, color: Color(0xFF10B981), size: 18),
                  const SizedBox(width: 6),
                  Text(
                    "COR Extracted Successfully",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: isDark ? Colors.white : const Color(0xFF1E1A3C),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "$score% Precision",
                  style: const TextStyle(
                    color: Color(0xFF10B981),
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            (_lastScanResult?.studentFirstName.isNotEmpty ?? false)
                ? "Student: ${_lastScanResult!.studentFirstName} ${_lastScanResult!.studentMiddleName.isNotEmpty ? "${_lastScanResult!.studentMiddleName} " : ""}${_lastScanResult!.studentSurname}".trim()
                : (provider.studentFirstName.isNotEmpty && provider.studentFirstName != 'Student'
                    ? "Student: ${provider.studentFirstName} ${provider.studentMiddleName.isNotEmpty ? "${provider.studentMiddleName} " : ""}${provider.studentSurname}".trim()
                    : "Student: Official COR Enrolled Schedule"),
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            "${provider.activeCourse} • ${provider.activeYear} (${provider.activeSemester})",
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white70 : Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              _buildBadgeChip("Section: ${provider.activeSection}", theme),
              _buildBadgeChip("Units: $totalUnits", theme),
              _buildBadgeChip(scanLabel, theme),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeChip(String label, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white70 : Colors.black87,
        ),
      ),
    );
  }

  Widget _buildReviewStep(ThemeData theme, ScheduleProvider provider) {
    final sessions = provider.activeSessions;

    return Column(
      children: [
        _buildExtractedCorHeader(theme, provider),
        Container(
          color: theme.colorScheme.primary.withValues(alpha: 0.06),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Extracted Class Sessions (${sessions.length})",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              TextButton.icon(
                onPressed: () => _showSessionEditDialog(context, null),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text("Add Class", style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ),

        Expanded(
          child: sessions.isEmpty
              ? Center(
                  child: Text(
                    "No sessions extracted. Tap 'Add Class' to insert manually.",
                    style: theme.textTheme.bodyMedium,
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: sessions.length,
                  itemBuilder: (context, index) {
                    final session = sessions[index];
                    final sessionColor = Color(session.colorValue);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                color: sessionColor,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: sessionColor.withValues(alpha: 0.4),
                                    blurRadius: 6,
                                  ),
                                ],
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
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 4,
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: sessionColor.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          session.subjectCode,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: sessionColor,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.primary.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          "${session.units} Units",
                                          style: TextStyle(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.bold,
                                            color: theme.colorScheme.primary,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        "${session.dayOfWeek} • ${session.startTime} - ${session.endTime}",
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: theme.colorScheme.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Room: ${session.room} | Prof: ${session.instructor}",
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),

                            Row(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, size: 20),
                                  onPressed: () => _showSessionEditDialog(context, session),
                                  visualDensity: VisualDensity.compact,
                                  tooltip: "Edit Class",
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                                  onPressed: () {
                                    provider.deleteSession(session.id);
                                    TopNotification.show(
                                      context,
                                      title: "Class Removed",
                                      message: "${session.subjectName} removed from schedule.",
                                      type: NotificationType.info,
                                    );
                                  },
                                  visualDensity: VisualDensity.compact,
                                  tooltip: "Delete Class",
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),

        Padding(
          padding: const EdgeInsets.fromLTRB(20.0, 12.0, 20.0, 110.0),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    provider.clearActiveSessions();
                    setState(() {
                      _currentStep = 0;
                      _selectedFilePath = null;
                    });
                  },
                  child: const Text("Re-Upload"),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _currentStep = 2;
                    });
                  },
                  child: const Text("Next Step"),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetadataStep(ThemeData theme, ScheduleProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 120.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 10),
          Text(
            "Schedule Information",
            style: theme.textTheme.titleLarge?.copyWith(fontSize: 22, fontWeight: FontWeight.w800),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            "Select academic details to organize and catalog this schedule in your Collection.",
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),

          Text(
            "Course / Degree Program",
            style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedCourse,
            isExpanded: true,
            icon: Icon(Icons.keyboard_arrow_down_rounded, color: theme.colorScheme.primary),
            dropdownColor: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            elevation: 8,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.school_outlined),
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            items: ScheduleProvider.availableCourses.map((String course) {
              return DropdownMenuItem(
                value: course,
                child: Text(course, overflow: TextOverflow.ellipsis),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) setState(() => _selectedCourse = val);
            },
          ),
          const SizedBox(height: 18),

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "School Year",
                      style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedSchoolYear,
                      isExpanded: true,
                      icon: Icon(Icons.keyboard_arrow_down_rounded, color: theme.colorScheme.primary),
                      dropdownColor: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      elevation: 8,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.calendar_month_outlined, size: 18),
                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                      ),
                      items: ScheduleProvider.availableSchoolYears.map((String sy) {
                        return DropdownMenuItem(
                          value: sy,
                          child: Text(
                            sy,
                            style: const TextStyle(fontSize: 12.5),
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedSchoolYear = val);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Semester",
                      style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedSemester,
                      isExpanded: true,
                      icon: Icon(Icons.keyboard_arrow_down_rounded, color: theme.colorScheme.primary),
                      dropdownColor: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      elevation: 8,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.timelapse_rounded, size: 18),
                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                      ),
                      items: ScheduleProvider.availableSemesters.map((String sem) {
                        return DropdownMenuItem(
                          value: sem,
                          child: Text(
                            sem,
                            style: const TextStyle(fontSize: 12.5),
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedSemester = val);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Year Level",
                      style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedYear,
                      isExpanded: true,
                      icon: Icon(Icons.keyboard_arrow_down_rounded, color: theme.colorScheme.primary),
                      dropdownColor: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      elevation: 8,
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      items: ScheduleProvider.availableYears.map((String yr) {
                        return DropdownMenuItem(
                          value: yr,
                          child: Text(
                            yr,
                            style: const TextStyle(fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedYear = val);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Section",
                      style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _sectionController,
                      decoration: const InputDecoration(
                        hintText: "e.g., Section A",
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 40),

          ElevatedButton(
            onPressed: () => _saveSchedule(provider),
            child: const Text("Save & Customize Schedule"),
          ),
        ],
      ),
    );
  }

  void _showImageSourcePicker(ThemeData theme) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Select COR Source File",
                style: theme.textTheme.titleLarge?.copyWith(fontSize: 18),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildSourceButton(
                    theme,
                    icon: Icons.picture_as_pdf_rounded,
                    label: "PDF / Doc",
                    onTap: () {
                      Navigator.pop(context);
                      _pickPDF();
                    },
                  ),
                  _buildSourceButton(
                    theme,
                    icon: Icons.photo_library_rounded,
                    label: "Image Scan",
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.gallery);
                    },
                  ),
                  _buildSourceButton(
                    theme,
                    icon: Icons.camera_alt_rounded,
                    label: "Camera Photo",
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.camera);
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSourceButton(ThemeData theme, {required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: theme.colorScheme.primary, size: 32),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _showSessionEditDialog(BuildContext context, ClassSession? session) {
    final provider = Provider.of<ScheduleProvider>(context, listen: false);
    final theme = Theme.of(context);
    final bool isEditing = session != null;

    final subjectController = TextEditingController(text: session?.subjectName ?? '');
    final codeController = TextEditingController(text: session?.subjectCode ?? '');
    final unitsController = TextEditingController(text: (session?.units ?? 3).toString());
    final roomController = TextEditingController(text: session?.room ?? '');
    final teacherController = TextEditingController(text: session?.instructor ?? '');

    String selectedDay = session?.dayOfWeek ?? 'Monday';
    String startTimeStr = session?.startTime ?? '08:00 AM';
    String endTimeStr = session?.endTime ?? '09:30 AM';
    int selectedColorVal = session?.colorValue ?? AppTheme.sessionColors[0].value;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(isEditing ? "Edit Class Session" : "Add Class Session"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: subjectController,
                      decoration: const InputDecoration(labelText: "Subject Name"),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: codeController,
                            decoration: const InputDecoration(labelText: "Subject Code"),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 1,
                          child: TextField(
                            controller: unitsController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: "Units"),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    DropdownButtonFormField<String>(
                      value: selectedDay,
                      icon: Icon(Icons.keyboard_arrow_down_rounded, color: theme.colorScheme.primary),
                      dropdownColor: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      elevation: 8,
                      decoration: const InputDecoration(labelText: "Day"),
                      items: _days.map((String day) {
                        return DropdownMenuItem(value: day, child: Text(day));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setDialogState(() => selectedDay = val);
                      },
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final TimeOfDay? time = await showTimePicker(
                                context: context,
                                initialTime: const TimeOfDay(hour: 8, minute: 0),
                              );
                              if (time != null) {
                                setDialogState(() {
                                  startTimeStr = time.format(context);
                                });
                              }
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(labelText: "Start Time"),
                              child: Text(startTimeStr, style: const TextStyle(fontSize: 13)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final TimeOfDay? time = await showTimePicker(
                                context: context,
                                initialTime: const TimeOfDay(hour: 9, minute: 30),
                              );
                              if (time != null) {
                                setDialogState(() {
                                  endTimeStr = time.format(context);
                                });
                              }
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(labelText: "End Time"),
                              child: Text(endTimeStr, style: const TextStyle(fontSize: 13)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: roomController,
                      decoration: const InputDecoration(labelText: "Room / Building"),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: teacherController,
                      decoration: const InputDecoration(labelText: "Instructor"),
                    ),
                    const SizedBox(height: 16),

                    const Text("Label Color", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 40,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: AppTheme.sessionColors.length,
                        itemBuilder: (context, idx) {
                          final color = AppTheme.sessionColors[idx];
                          final isSelected = selectedColorVal == color.value;
                          return GestureDetector(
                            onTap: () {
                              setDialogState(() {
                                selectedColorVal = color.value;
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.only(right: 8),
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: isSelected
                                    ? Border.all(color: theme.colorScheme.onSurface, width: 2.5)
                                    : null,
                              ),
                              child: isSelected
                                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                                  : null,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                TextButton(
                  onPressed: () {
                    if (subjectController.text.trim().isEmpty) return;

                    final parsedUnits = int.tryParse(unitsController.text.trim()) ?? 3;

                    final newSession = ClassSession(
                      id: isEditing ? session.id : DateTime.now().millisecondsSinceEpoch.toString(),
                      subjectName: subjectController.text.trim(),
                      subjectCode: codeController.text.trim().isEmpty ? "CS 101" : codeController.text.trim(),
                      room: roomController.text.trim().isEmpty ? "TBA" : roomController.text.trim(),
                      instructor: teacherController.text.trim().isEmpty ? "TBA" : teacherController.text.trim(),
                      dayOfWeek: selectedDay,
                      startTime: startTimeStr,
                      endTime: endTimeStr,
                      colorValue: selectedColorVal,
                      units: parsedUnits > 0 ? parsedUnits : 3,
                    );

                    if (isEditing) {
                      provider.updateSession(newSession);
                    } else {
                      provider.addSession(newSession);
                    }

                    TopNotification.show(
                      context,
                      title: isEditing ? "Class Updated" : "Class Added",
                      message: "${newSession.subjectCode} - ${newSession.subjectName}",
                      type: NotificationType.success,
                    );

                    Navigator.pop(context);
                  },
                  child: Text(isEditing ? "Update" : "Add"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDiscardWarning() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Discard Changes?"),
        content: const Text("Going back now will discard all uploaded and extracted session details."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Keep Reviewing"),
          ),
          TextButton(
            onPressed: () {
              final provider = Provider.of<ScheduleProvider>(context, listen: false);
              provider.clearActiveSessions();
              Navigator.pop(dialogContext);
              _navigateBackToHome();
            },
            child: const Text("Discard", style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  Future<void> _saveSchedule(ScheduleProvider provider) async {
    final finalSection = _sectionController.text.trim().isNotEmpty ? _sectionController.text.trim() : "Section A";

    provider.updateActiveDetails(
      schoolYear: _selectedSchoolYear,
      semester: _selectedSemester,
      course: _selectedCourse,
      year: _selectedYear,
      section: finalSection,
    );

    // Auto-update student profile with confirmed course, year, and semester
    await provider.updateStudentProfile(
      firstName: provider.studentFirstName,
      middleName: provider.studentMiddleName,
      surname: provider.studentSurname,
      birthdate: provider.studentBirthdate,
      age: provider.studentAge,
      email: provider.studentEmail,
      course: _selectedCourse,
      year: _selectedYear,
      semester: _selectedSemester,
    );

    await provider.saveCurrentToHistory();

    if (!mounted) return;
    TopNotification.show(
      context,
      title: "Schedule Saved & Profile Synced!",
      message: "$_selectedCourse ($_selectedYear, $_selectedSemester) saved to your profile and collection.",
      type: NotificationType.success,
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const ScheduleExporterScreen()),
    );
  }
}

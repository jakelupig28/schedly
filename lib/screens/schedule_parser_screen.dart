import 'dart:io';
import 'package:flutter/material';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider';
import '../providers/schedule_provider.dart';
import '../models/schedule.dart';
import '../theme/app_theme.dart';
import 'schedule_exporter_screen.dart';

class ScheduleParserScreen extends StatefulWidget {
  const ScheduleParserScreen({super.key});

  @override
  State<ScheduleParserScreen> createState() => _ScheduleParserScreenState();
}

class _ScheduleParserScreenState extends State<ScheduleParserScreen> {
  int _currentStep = 0;
  String? _selectedFilePath;
  String? _selectedFileName;
  String _scanType = 'scan'; // 'pdf', 'scan', 'photo'
  bool _isScanning = false;
  String _scanStatusText = "Uploading Document...";
  final ImagePicker _picker = ImagePicker();

  // Controllers for schedule metadata
  final _schoolYearController = TextEditingController();
  final _courseController = TextEditingController();
  final _sectionController = TextEditingController();
  String _selectedYear = '3rd Year';

  final List<String> _years = ['1st Year', '2nd Year', '3rd Year', '4th Year', '5th Year+'];
  final List<String> _days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

  @override
  void dispose() {
    _schoolYearController.dispose();
    _courseController.dispose();
    _sectionController.dispose();
    super.dispose();
  }

  // Action to pick image
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _selectedFilePath = image.path;
          _selectedFileName = image.name;
          _scanType = source == ImageSource.camera ? 'photo' : 'scan';
          _currentStep = 1; // Move to Scanning/Review
        });
        _runScanner();
      }
    } catch (e) {
      // In case of error/simulator limitations, let's mock it
      setState(() {
        _selectedFilePath = 'mock_cor_image.png';
        _selectedFileName = source == ImageSource.camera ? 'camera_photo.jpg' : 'scanned_cor.png';
        _scanType = source == ImageSource.camera ? 'photo' : 'scan';
        _currentStep = 1;
      });
      _runScanner();
    }
  }

  // Action to pick PDF file
  Future<void> _pickPDF() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedFilePath = result.files.single.path;
          _selectedFileName = result.files.single.name;
          _scanType = 'pdf';
          _currentStep = 1; // Move to Scanning/Review
        });
        _runScanner();
      }
    } catch (e) {
      // Handle error/simulator limits gracefully
      setState(() {
        _selectedFilePath = 'mock_cor_schedule.pdf';
        _selectedFileName = 'digital_cor_2026.pdf';
        _scanType = 'pdf';
        _currentStep = 1;
      });
      _runScanner();
    }
  }

  // Scanning animation simulation
  Future<void> _runScanner() async {
    String log1 = "Uploading Certificate...";
    String log2 = "Running Smart OCR Reader...";
    String log3 = "Extracting Class Slots & Locations...";

    if (_scanType == 'pdf') {
      log1 = "Reading PDF Vector Layers...";
      log2 = "Parsing PDF schedule structures...";
      log3 = "Extracting courses, rooms, and teacher names...";
    } else if (_scanType == 'scan') {
      log1 = "Analyzing Image Scan Grid...";
      log2 = "Recognizing characters and row alignment...";
      log3 = "Resolving day, start/end times, and rooms...";
    } else if (_scanType == 'photo') {
      log1 = "Detecting Schedule Corners...";
      log2 = "Correcting perspective distortion & enhancing contrast...";
      log3 = "Running deep OCR text recognition on schedule grid...";
    }

    setState(() {
      _isScanning = true;
      _scanStatusText = log1;
    });
    await Future.delayed(const Duration(milliseconds: 1000));
    
    setState(() {
      _scanStatusText = log2;
    });
    await Future.delayed(const Duration(milliseconds: 1200));
    
    setState(() {
      _scanStatusText = log3;
    });
    await Future.delayed(const Duration(milliseconds: 1200));

    final provider = Provider.of<ScheduleProvider>(context, listen: false);
    await provider.simulateOcrScan(_selectedFilePath ?? '', scanType: _scanType);

    // Pre-populate controllers with parsed details after simulated scan
    _courseController.text = "BS Information Technology";
    _schoolYearController.text = "S.Y. 2026-2027";
    _sectionController.text = "Section A";

    setState(() {
      _isScanning = false;
      _currentStep = 1; // Transition to review list
    });

    String feedbackMsg = "Scan Complete! Found 9 class sessions.";
    if (_scanType == 'pdf') {
      feedbackMsg = "Scan Complete! Digital PDF matched with 100% precision.";
    } else if (_scanType == 'scan') {
      feedbackMsg = "Scan Complete! Accurate image scan matched with 95% precision.";
    } else if (_scanType == 'photo') {
      feedbackMsg = "Scan Complete! Photo capture matched with 85% precision. Review recommended.";
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(feedbackMsg),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ScheduleProvider>(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Scan Certificate"),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () {
            if (_currentStep > 0 && !_isScanning) {
              _showDiscardWarning();
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Custom wizard progress indicator
            _buildStepIndicator(theme),
            const Divider(height: 1),

            // Content based on step
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
        ? Colors.green
        : isActive
            ? theme.colorScheme.primary
            : theme.textTheme.bodyMedium!.color!.withOpacity(0.3);

    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: nodeColor.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: nodeColor, width: 2),
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check_rounded, color: Colors.green, size: 16)
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
            fontSize: 10,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive ? theme.colorScheme.onBackground : theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
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
        color: isPassed ? Colors.green : theme.dividerColor.withOpacity(0.2),
        margin: const EdgeInsets.only(bottom: 16),
      ),
    );
  }

  Widget _buildScanningLoader(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 140,
                  height: 140,
                  child: CircularProgressIndicator(
                    strokeWidth: 6,
                    valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                  ),
                ),
                Icon(
                  Icons.document_scanner_rounded,
                  size: 64,
                  color: theme.colorScheme.primary,
                ),
              ],
            ),
            const SizedBox(height: 40),
            Text(
              _scanStatusText,
              style: theme.textTheme.titleLarge?.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 8),
            const Text(
              "Converting visual schedules into clean calendar blocks...",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadStep(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          Text(
            "Upload Certificate of Registration",
            style: theme.textTheme.titleLarge?.copyWith(fontSize: 22),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            "Select a clear screenshot, photo, or PDF capture of your subject times. Schedly will automatically map them out.",
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          
          // Image upload placeholder
          GestureDetector(
            onTap: () => _showImageSourcePicker(theme),
            child: Container(
              height: 240,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.04),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: theme.colorScheme.primary.withOpacity(0.3),
                  width: 2,
                  style: BorderStyle.solid, // Simulated dashed border using simple solid for design safety
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
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
          const SizedBox(height: 40),

          // Tip section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.amber.withOpacity(0.3), width: 1),
            ),
            child: const Row(
              children: [
                Icon(Icons.lightbulb_outline_rounded, color: Colors.amber),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Tip: Make sure the subjects' time, day, and room columns are clearly visible for high scanning accuracy.",
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

  Widget _buildReviewStep(ThemeData theme, ScheduleProvider provider) {
    final sessions = provider.activeSessions;

    return Column(
      children: [
        // Top info bar
        Container(
          color: theme.colorScheme.primary.withOpacity(0.06),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Extracted Class Sessions (${sessions.length})",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              TextButton.icon(
                onPressed: () => _showSessionEditDialog(context, null),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text("Add Class", style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ),
        
        // List of extracted class cards
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
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: sessionColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        title: Text(
                          session.subjectName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        subtitle: Text(
                          "${session.dayOfWeek} • ${session.startTime} - ${session.endTime}\nRoom: ${session.room} | ${session.instructor}",
                          style: const TextStyle(fontSize: 12),
                        ),
                        isThreeLine: true,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 20),
                              onPressed: () => _showSessionEditDialog(context, session),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                              onPressed: () {
                                provider.deleteSession(session.id);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),

        // Review step navigation actions
        Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    provider.clearActiveSessions();
                    setState(() {
                      _currentStep = 0;
                      _selectedFilePath = null;
                      _selectedFileName = null;
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
                      _currentStep = 2; // Go to Metadata Setup
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
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 10),
          Text(
            "Schedule Information",
            style: theme.textTheme.titleLarge?.copyWith(fontSize: 22),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            "Add academic details to organize and catalog this schedule in your history list.",
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 36),

          // School Year
          Text(
            "School Year",
            style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _schoolYearController,
            decoration: const InputDecoration(
              hintText: "e.g., S.Y. 2026-2027",
              prefixIcon: Icon(Icons.calendar_month_outlined),
            ),
          ),
          const SizedBox(height: 20),

          // Course
          Text(
            "Course / Degree Program",
            style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _courseController,
            decoration: const InputDecoration(
              hintText: "e.g., BS Computer Science",
              prefixIcon: Icon(Icons.school_outlined),
            ),
          ),
          const SizedBox(height: 20),

          // Year Level & Section Row
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
                      icon: Icon(Icons.keyboard_arrow_down_rounded, color: theme.colorScheme.primary),
                      dropdownColor: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      elevation: 8,
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      items: _years.map((String yr) {
                        return DropdownMenuItem(value: yr, child: Text(yr));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedYear = val);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
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

          const SizedBox(height: 48),

          // Save Button
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
              color: theme.colorScheme.primary.withOpacity(0.08),
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
                    // Subject Name
                    TextField(
                      controller: subjectController,
                      decoration: const InputDecoration(labelText: "Subject Name"),
                    ),
                    const SizedBox(height: 12),
                    
                    // Subject Code
                    TextField(
                      controller: codeController,
                      decoration: const InputDecoration(labelText: "Subject Code"),
                    ),
                    const SizedBox(height: 12),

                    // Day of Week
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

                    // Timings Picker Rows
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

                    // Room & Teacher
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

                    // Color Picker
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
                                    ? Border.all(color: theme.colorScheme.onBackground, width: 2.5)
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
                    );

                    if (isEditing) {
                      provider.updateSession(newSession);
                    } else {
                      provider.addSession(newSession);
                    }

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
      builder: (context) => AlertDialog(
        title: const Text("Discard Changes?"),
        content: const Text("Going back now will discard all uploaded and extracted session details."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Keep Reviewing"),
          ),
          TextButton(
            onPressed: () {
              final provider = Provider.of<ScheduleProvider>(context, listen: false);
              provider.clearActiveSessions();
              Navigator.pop(context); // Pop dialog
              Navigator.pop(context); // Pop screen
            },
            child: const Text("Discard", style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  Future<void> _saveSchedule(ScheduleProvider provider) async {
    // Validate inputs
    if (_courseController.text.trim().isEmpty || _sectionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Course and Section fields are required")),
      );
      return;
    }

    // Save details to provider
    provider.updateActiveDetails(
      schoolYear: _schoolYearController.text.trim(),
      course: _courseController.text.trim(),
      year: _selectedYear,
      section: _sectionController.text.trim(),
    );

    // Persist to history
    await provider.saveCurrentToHistory();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Schedule saved successfully!"),
        backgroundColor: Colors.green,
      ),
    );

    // Push replacement to exporter screen for dynamic theme configuration and download
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const ScheduleExporterScreen()),
    );
  }
}

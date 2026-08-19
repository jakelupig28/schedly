import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/schedule_provider.dart';
import '../models/schedule.dart';
import '../widgets/top_notification.dart';
import 'schedule_exporter_screen.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ScheduleProvider>(context);
    final historyList = provider.history;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Schedule History",
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: historyList.isEmpty
            ? _buildEmptyHistory(theme)
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
                itemCount: historyList.length,
                itemBuilder: (context, index) {
                  final item = historyList[index];
                  final formattedDate = DateFormat('MMM d, yyyy • hh:mm a').format(item.createdAt);
                  final isCurrentActive = provider.activeCourse == item.course &&
                      provider.activeSchoolYear == item.schoolYear &&
                      provider.activeSemester == item.semester &&
                      provider.activeYear == item.year;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: isCurrentActive
                          ? BorderSide(color: theme.colorScheme.primary, width: 1.5)
                          : BorderSide.none,
                    ),
                    child: InkWell(
                      onTap: () {
                        _showScheduleDetailModal(context, provider, item);
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Calendar Icon Badge
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.calendar_month_rounded,
                                color: theme.colorScheme.primary,
                                size: 26,
                              ),
                            ),
                            const SizedBox(width: 14),

                            // Schedule metadata
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        "${item.semester} • ${item.schoolYear}",
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: theme.colorScheme.primary,
                                          fontSize: 12,
                                        ),
                                      ),
                                      if (isCurrentActive) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: const Text(
                                            "ACTIVE",
                                            style: TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w900,
                                              color: Color(0xFF10B981),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item.course,
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    "${item.year} • ${item.section} • ${item.totalUnits} Units",
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontSize: 12,
                                      color: isDark ? Colors.white70 : Colors.grey[700],
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "${item.sessions.length} subjects parsed",
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: theme.colorScheme.secondary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        formattedDate,
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: isDark ? Colors.white38 : Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // Chevron arrow to indicate tapping opens detail
                            const SizedBox(width: 8),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 16,
                              color: isDark ? Colors.white38 : Colors.grey[400],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
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
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
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
                      // Delete button
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                        tooltip: "Delete Schedule",
                        onPressed: () {
                          Navigator.pop(sheetContext);
                          _showDeleteConfirmDialog(context, provider, item.id);
                        },
                      ),
                      const SizedBox(width: 8),

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

  Widget _buildEmptyHistory(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history_toggle_off_rounded,
              size: 72,
              color: theme.colorScheme.primary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              "No Schedules in Collection",
              style: theme.textTheme.titleLarge?.copyWith(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              "Schedules you scan and generate will be cataloged here for easy viewing and wallpaper exports.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmDialog(BuildContext context, ScheduleProvider provider, String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Schedule?"),
        content: const Text("Are you sure you want to permanently remove this schedule from your archive?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              provider.deleteHistoryItem(id);
              Navigator.pop(context);
              TopNotification.show(
                context,
                title: "Schedule Deleted",
                message: "Removed from your collection archive.",
                type: NotificationType.info,
              );
            },
            child: const Text("Delete", style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}

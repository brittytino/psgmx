import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_dimens.dart';
import '../../models/attendance.dart';
import '../../services/attendance_service.dart';
import '../widgets/premium_card.dart';
import 'package:intl/intl.dart';

class StudentDetailsScreen extends StatefulWidget {
  final AttendanceSummary student;

  const StudentDetailsScreen({
    super.key,
    required this.student,
  });

  @override
  State<StudentDetailsScreen> createState() => _StudentDetailsScreenState();
}

class _StudentDetailsScreenState extends State<StudentDetailsScreen> {
  late AttendanceService _attendanceService;
  List<Attendance> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _attendanceService = AttendanceService();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    try {
      final history = await _attendanceService.getStudentAttendanceHistory(
        studentId: widget.student.studentId,
      );

      if (mounted) {
        setState(() {
          _history = history;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading history: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final summary = widget.student;
    
    final percentage = summary.attendancePercentage;
    final statusColor = percentage >= 90 
        ? Colors.green 
        : (percentage >= 75 ? Colors.orange : Colors.red);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.student.name,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        elevation: 0,
        backgroundColor: colorScheme.surface,
      ),
      body: RefreshIndicator(
        onRefresh: _loadHistory,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            // Profile Header
            Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: statusColor.withValues(alpha: 0.1),
                  child: Text(
                    summary.name.isNotEmpty ? summary.name[0].toUpperCase() : '?',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        summary.regNo,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 4),
                       Container(
                         padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                         decoration: BoxDecoration(
                           color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                           borderRadius: BorderRadius.circular(4),
                         ),
                        child: Text(
                          'Team ${summary.teamId ?? "N/A"}',
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: AppSpacing.lg),

            // Summary Card
            PremiumCard(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${percentage.toStringAsFixed(1)}%',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Overall Attendance',
                    style: GoogleFonts.inter(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const Divider(),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatColumn('Present', summary.presentCount.toString(), Colors.green),
                      _buildStatColumn('Absent', summary.absentCount.toString(), Colors.red),
                      _buildStatColumn('Total', summary.totalWorkingDays.toString(), Colors.blue),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xl),
            
            Text(
              'Attendance History',
              style: GoogleFonts.inter(
                fontSize: 11, 
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // History List
            if (_isLoading)
               const Center(child: Padding(
                 padding: EdgeInsets.all(32.0),
                 child: CircularProgressIndicator(),
               ))
            else if (_history.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Text(
                    'No attendance records found',
                    style: GoogleFonts.inter(color: Colors.grey),
                  ),
                ),
              )
            else
              ..._history.map((record) {
                final isPresent = record.status == AttendanceStatus.present;
                return Container(
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border(
                      left: BorderSide(
                        color: isPresent ? Colors.green : Colors.red,
                        width: 4,
                      ),
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md, 
                      vertical: 0
                    ),
                    title: Text(
                      DateFormat('MMMM d, yyyy (EEEE)').format(record.date),
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: (isPresent ? Colors.green : Colors.red).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        isPresent ? 'PRESENT' : 'ABSENT',
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: isPresent ? Colors.green : Colors.red,
                        ),
                      ),
                    ),
                  ),
                );
              }),
             const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 9,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}

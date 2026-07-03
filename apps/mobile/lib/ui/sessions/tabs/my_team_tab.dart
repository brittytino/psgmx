import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../providers/user_provider.dart';
import '../../../services/placement_session_service.dart';
import '../../../models/placement_session.dart';
import '../../../models/app_user.dart';

class MyTeamTab extends StatefulWidget {
  const MyTeamTab({super.key});

  @override
  State<MyTeamTab> createState() => _MyTeamTabState();
}

class _MyTeamTabState extends State<MyTeamTab> {
  late PlacementSessionService _service;
  bool _isLoading = true;
  
  PlacementSession? _todaySession;
  List<AppUser> _eligibleStudents = [];
  Map<String, PlacementAttendanceStatus> _attendanceRecords = {};
  
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _service = PlacementSessionService(Supabase.instance.client);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final user = Provider.of<UserProvider>(context, listen: false).currentUser;
    if (user == null || user.teamId == null || user.batchId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      // Find today's session for this team (or batch)
      final upcoming = await _service.fetchUpcomingForTeam(batchId: user.batchId!, teamId: user.teamId!);
      final today = DateTime.now();
      _todaySession = upcoming.cast<PlacementSession?>().firstWhere(
        (s) => s!.sessionDatetime.year == today.year && 
               s.sessionDatetime.month == today.month && 
               s.sessionDatetime.day == today.day,
        orElse: () => null,
      );

      if (_todaySession != null) {
        _eligibleStudents = await _service.fetchEligibleStudents(_todaySession!);
        
        // Load existing records
        final existingRecords = await _service.fetchSessionAttendance(_todaySession!.id);
        _attendanceRecords = {
          for (var r in existingRecords) r.userId: r.status
        };
      }

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error loading team tab: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _markAttendance(String studentId, PlacementAttendanceStatus status) async {
    if (_todaySession == null || _todaySession!.isLocked) return;
    
    final userId = Provider.of<UserProvider>(context, listen: false).currentUser?.uid;
    if (userId == null) return;

    setState(() {
      _attendanceRecords[studentId] = status;
    });

    try {
      await _service.markSessionAttendance(
        sessionId: _todaySession!.id,
        markedBy: userId,
        records: {studentId: status},
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save attendance: $e')));
      }
    }
  }

  Future<void> _lockAttendance() async {
    if (_todaySession == null) return;
    
    final userId = Provider.of<UserProvider>(context, listen: false).currentUser?.uid;
    if (userId == null) return;

    try {
      await _service.updateSession(
        sessionId: _todaySession!.id,
        updatedBy: userId,
        isLocked: true,
      );
      setState(() {
        _todaySession = PlacementSession(
          id: _todaySession!.id,
          batchId: _todaySession!.batchId,
          scheduledBy: _todaySession!.scheduledBy,
          sessionDatetime: _todaySession!.sessionDatetime,
          topic: _todaySession!.topic,
          description: _todaySession!.description,
          sessionType: _todaySession!.sessionType,
          sessionMode: _todaySession!.sessionMode,
          durationMinutes: _todaySession!.durationMinutes,
          location: _todaySession!.location,
          isLocked: true,
          targetTeamIds: _todaySession!.targetTeamIds,
          createdAt: _todaySession!.createdAt,
          updatedAt: DateTime.now(),
        );
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Attendance locked successfully.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to lock attendance: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFFF6B4A)));
    }

    if (_todaySession == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.calendarX, size: 16, color: Color(0xFFD1D5DB)),
            const SizedBox(height: 16),
            Text(
              'No Session Today',
              style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF4B5563)),
            ),
            const SizedBox(height: 8),
            Text(
              'Your team does not have any placement sessions scheduled for today.',
              style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF6B7280)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    int presentCount = _attendanceRecords.values.where((s) => s == PlacementAttendanceStatus.present).length;
    int absentCount = _attendanceRecords.values.where((s) => s == PlacementAttendanceStatus.absent).length;
    int notMarkedCount = _eligibleStudents.length - presentCount - absentCount;

    final filteredStudents = _eligibleStudents.where((s) {
      if (_searchQuery.isEmpty) return true;
      return s.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             s.regNo.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 100),
          children: [
            _buildTeamStatsCard(presentCount, absentCount, notMarkedCount),
            const SizedBox(height: 16),
            _buildSessionHeader(),
            const SizedBox(height: 16),
            _buildSearchAndFilter(),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Student', style: GoogleFonts.inter(fontSize: 9, color: const Color(0xFF9094A6))),
                Text('Status', style: GoogleFonts.inter(fontSize: 9, color: const Color(0xFF9094A6))),
              ],
            ),
            const SizedBox(height: 8),
            ...filteredStudents.map((student) {
              final status = _attendanceRecords[student.uid];
              return _buildStudentRow(student, status);
            }),
          ],
        ),
        if (!_todaySession!.isLocked)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomLockBar(notMarkedCount == 0),
          ),
      ],
    );
  }

  Widget _buildTeamStatsCard(int present, int absent, int notMarked) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF6F5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFBE4D8)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.users, color: Color(0xFFFF6B4A), size: 16),
              ),
              const SizedBox(height: 8),
              Text(
                'My Team',
                style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF2D3142)),
              ),
              Text(
                '${_eligibleStudents.length} Students',
                style: GoogleFonts.inter(fontSize: 9, color: const Color(0xFF9094A6)),
              ),
            ],
          ),
          _buildStatItem(present, 'Present', const Color(0xFF4CAF50)),
          _buildStatItem(absent, 'Absent', const Color(0xFFF44336)),
          _buildStatItem(notMarked, 'Not Marked', const Color(0xFF9E9E9E)),
        ],
      ),
    );
  }

  Widget _buildStatItem(int value, String label, Color color) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: color),
        ),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 9, color: const Color(0xFF9094A6)),
        ),
      ],
    );
  }

  Widget _buildSessionHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F0F0),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(LucideIcons.calendar, color: Color(0xFFFF6B4A), size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Today, ${DateFormat('dd MMM yyyy').format(_todaySession!.sessionDatetime)}',
                style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF2D3142)),
              ),
              Text(
                '${_todaySession!.sessionType} Session • ${DateFormat('hh:mm a').format(_todaySession!.sessionDatetime)}',
                style: GoogleFonts.inter(fontSize: 9, color: const Color(0xFF9094A6)),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: _todaySession!.isLocked ? const Color(0xFFFEE2E2) : const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: _todaySession!.isLocked ? const Color(0xFFEF4444) : const Color(0xFF4CAF50),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                _todaySession!.isLocked ? 'Locked' : 'Marking open',
                style: GoogleFonts.inter(
                  fontSize: 9, 
                  fontWeight: FontWeight.w600, 
                  color: _todaySession!.isLocked ? const Color(0xFFEF4444) : const Color(0xFF4CAF50),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSearchAndFilter() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            onChanged: (val) => setState(() => _searchQuery = val),
            decoration: InputDecoration(
              hintText: 'Search student',
              hintStyle: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF9094A6)),
              prefixIcon: const Icon(LucideIcons.search, size: 16, color: Color(0xFF9094A6)),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Row(
            children: [
              const Icon(LucideIcons.filter, size: 12, color: Color(0xFF4B5563)),
              const SizedBox(width: 8),
              Text('Filter', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: const Color(0xFF4B5563))),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStudentRow(AppUser student, PlacementAttendanceStatus? status) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF3F4F6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFFE5E7EB),
            child: Text(
              student.name.isNotEmpty ? student.name[0].toUpperCase() : '?',
              style: GoogleFonts.inter(color: const Color(0xFF4B5563), fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student.name,
                  style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF111827)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  student.regNo,
                  style: GoogleFonts.inter(fontSize: 9, color: const Color(0xFF6B7280)),
                ),
              ],
            ),
          ),
          _buildAttendanceToggles(student.uid, status),
        ],
      ),
    );
  }

  Widget _buildAttendanceToggles(String studentId, PlacementAttendanceStatus? status) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          _buildToggleButton(
            label: 'PRESENT',
            isSelected: status == PlacementAttendanceStatus.present,
            selectedColor: const Color(0xFF4CAF50),
            onTap: () => _markAttendance(studentId, PlacementAttendanceStatus.present),
          ),
          _buildToggleButton(
            label: 'ABSENT',
            isSelected: status == PlacementAttendanceStatus.absent,
            selectedColor: const Color(0xFFF44336),
            onTap: () => _markAttendance(studentId, PlacementAttendanceStatus.absent),
          ),
          _buildToggleButton(
            label: 'NOT MARKED',
            isSelected: status == null,
            selectedColor: const Color(0xFF9E9E9E),
            onTap: () {}, // Do nothing, you can't manually set to null via buttons easily, or maybe require an API call to delete record
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton({required String label, required bool isSelected, required Color selectedColor, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: isSelected ? Border.all(color: selectedColor) : null,
        ),
        child: Row(
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 8,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? selectedColor : const Color(0xFF6B7280),
              ),
            ),
            if (isSelected && label != 'NOT MARKED') ...[
              const SizedBox(width: 4),
              Icon(LucideIcons.checkCircle2, size: 12, color: selectedColor),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildBottomLockBar(bool canLock) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF6F5),
        border: const Border(top: BorderSide(color: Color(0xFFFBE4D8))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFFFFE0D6),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.info, color: Color(0xFFFF6B4A), size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Mark everyone to complete attendance',
                    style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: const Color(0xFF111827)),
                  ),
                  Text(
                    'All students must be marked to lock today\'s session.',
                    style: GoogleFonts.inter(fontSize: 9, color: const Color(0xFF6B7280)),
                  ),
                ],
              ),
            ),
            ElevatedButton.icon(
              onPressed: canLock ? _lockAttendance : null,
              icon: const Icon(LucideIcons.lock, size: 12, color: Colors.white),
              label: Text('Lock Attendance', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B4A),
                disabledBackgroundColor: const Color(0xFFFCA5A5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

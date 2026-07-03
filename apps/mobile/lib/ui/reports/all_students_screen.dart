import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_dimens.dart';
import '../../models/attendance.dart';
import '../../services/attendance_service.dart';
import 'team_details_screen.dart';
import 'student_details_screen.dart';

class AllStudentsScreen extends StatefulWidget {
  const AllStudentsScreen({super.key});

  @override
  State<AllStudentsScreen> createState() => _AllStudentsScreenState();
}

class _AllStudentsScreenState extends State<AllStudentsScreen> with SingleTickerProviderStateMixin {
  late AttendanceService _attendanceService;
  List<AttendanceSummary> _students = [];
  List<AttendanceSummary> _filteredStudents = [];
  List<Map<String, dynamic>> _teams = []; // Derived from students
  List<Map<String, dynamic>> _filteredTeams = [];

  bool _isLoading = true;
  String _searchQuery = '';
  double _attendanceFilter = 0;
  
  late TabController _tabController;
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _attendanceService = AttendanceService();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _currentTabIndex = _tabController.index;
          _applyFilters();
        });
      }
    });
    _loadStudents();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadStudents() async {
    setState(() => _isLoading = true);
    try {
      final stats = await _attendanceService.getAllStudentsAttendanceSummary();

      // Process teams from student data (client-side aggregation)
      final Map<String, List<AttendanceSummary>> teamGroups = {};
      for (var s in stats) {
        if (s.teamId != null && s.teamId!.isNotEmpty) {
          teamGroups.putIfAbsent(s.teamId!, () => []).add(s);
        }
      }

      final List<Map<String, dynamic>> teams = [];
      teamGroups.forEach((teamId, members) {
        final avgAttendance = members.fold<double>(
              0, (sum, m) => sum + m.attendancePercentage
            ) / members.length;
        
        teams.add({
          'teamId': teamId,
          'name': 'Team $teamId',
          'memberCount': members.length,
          'avgAttendance': avgAttendance,
          'members': members,
          'below75': members.where((m) => m.attendancePercentage < 75).length,
        });
      });
      
      // Sort teams by attendance descending initially
      teams.sort((a, b) => b['avgAttendance'].compareTo(a['avgAttendance']));

      if (mounted) {
        setState(() {
          _students = stats;
          _teams = teams;
          _applyFilters();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  void _applyFilters() {
    final query = _searchQuery.toLowerCase();
    
    // Filter Students
    _filteredStudents = _students.where((student) {
      final name = student.name.toLowerCase();
      final regNo = student.regNo.toLowerCase();
      final team = (student.teamId ?? '').toLowerCase();
      final attendance = student.attendancePercentage;
      
      final matchesSearch = name.contains(query) || regNo.contains(query) || team.contains(query);
      final matchesAttendance = _attendanceFilter == 0 || attendance >= _attendanceFilter;

      return matchesSearch && matchesAttendance;
    }).toList();

    // Filter Teams
    _filteredTeams = _teams.where((team) {
      final teamName = team['name'].toString().toLowerCase();
      final avgAttendance = team['avgAttendance'] as double;
      final members = team['members'] as List<AttendanceSummary>;

      // Search matches team name OR any member name/regNo
      final matchesTeamName = teamName.contains(query);
      final matchesAnyMember = members.any((m) => 
          m.name.toLowerCase().contains(query) || 
          m.regNo.toLowerCase().contains(query)
      );
      
      final matchesSearch = matchesTeamName || matchesAnyMember;
      final matchesAttendance = _attendanceFilter == 0 || avgAttendance >= _attendanceFilter;
      
      return matchesSearch && matchesAttendance;
    }).toList();
  }


  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Student & Team Views',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        elevation: 0,
        backgroundColor: colorScheme.surface,
        bottom: TabBar(
          controller: _tabController,
          labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
          unselectedLabelStyle: GoogleFonts.inter(),
          tabs: const [
            Tab(text: 'By Student'),
            Tab(text: 'By Team'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search and filter section
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                // Search bar
                TextField(
                  decoration: InputDecoration(
                    hintText: _currentTabIndex == 0 ? 'Search students, reg no...' : 'Search teams...',
                    hintStyle: GoogleFonts.inter(fontSize: 11),
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      borderSide: BorderSide(color: colorScheme.outlineVariant),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      borderSide: BorderSide(color: colorScheme.outlineVariant),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md, 
                      vertical: AppSpacing.sm
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                      _applyFilters();
                    });
                  },
                ),
                const SizedBox(height: AppSpacing.md),

                // Attendance filter chips
                SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [0, 50, 75, 90, 100].map((threshold) {
                      final isSelected = _attendanceFilter == threshold.toDouble();
                      return Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.sm),
                        child: FilterChip(
                          label: Text(
                            threshold == 0 ? 'All' : '$threshold%+',
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _attendanceFilter = selected ? threshold.toDouble() : 0;
                              _applyFilters();
                            });
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildStudentsList(colorScheme),
                      _buildTeamsList(colorScheme),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentsList(ColorScheme colorScheme) {
    if (_filteredStudents.isEmpty) return _buildEmptyState();

    return RefreshIndicator(
      onRefresh: _loadStudents,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        itemCount: _filteredStudents.length,
        itemBuilder: (context, index) {
          final student = _filteredStudents[index];
          final attendance = student.attendancePercentage;
          Color attendanceColor = attendance >= 90 ? Colors.green : (attendance >= 75 ? Colors.orange : Colors.red);

          return Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Material(
               color: colorScheme.surfaceContainer,
               borderRadius: BorderRadius.circular(AppRadius.lg),
              child: InkWell(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => StudentDetailsScreen(student: student),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 8),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: attendanceColor.withValues(alpha: 0.1),
                        child: Text(
                          student.name.isNotEmpty ? student.name[0].toUpperCase() : '?',
                          style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: attendanceColor),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              student.name,
                              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                            ),
                            Text(
                              '${student.regNo} • Team ${student.teamId ?? "N/A"}',
                              style: GoogleFonts.inter(fontSize: 9),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                        decoration: BoxDecoration(
                          color: attendanceColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Text(
                          '${attendance.toStringAsFixed(1)}%',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            color: attendanceColor,
                            fontSize: 9,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTeamsList(ColorScheme colorScheme) {
    if (_filteredTeams.isEmpty) return _buildEmptyState();

    return RefreshIndicator(
      onRefresh: _loadStudents,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        itemCount: _filteredTeams.length,
        itemBuilder: (context, index) {
          final team = _filteredTeams[index];
          final avgAttendance = team['avgAttendance'] as double;
          final below75 = team['below75'] as int;
          
          Color teamColor = avgAttendance >= 85 ? Colors.green : (avgAttendance >= 75 ? Colors.blue : Colors.orange);

          return Card(
            margin: const EdgeInsets.only(bottom: AppSpacing.md),
            elevation: 0,
            color: colorScheme.surfaceContainer,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => TeamDetailsScreen(
                      teamId: team['teamId'],
                      teamName: team['name'],
                    ),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: teamColor.withValues(alpha: 0.1),
                      radius: 24,
                      child: Icon(Icons.groups_rounded, color: teamColor),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            team['name'],
                            style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 11),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${team['memberCount']} Members',
                            style: GoogleFonts.inter(fontSize: 9, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                         Text(
                          '${avgAttendance.toStringAsFixed(1)}%',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: teamColor,
                          ),
                        ),
                        if (below75 > 0)
                          Text(
                            '$below75 at risk',
                            style: GoogleFonts.inter(
                              fontSize: 8,
                              color: Colors.red,
                              fontWeight: FontWeight.w500
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Icon(Icons.chevron_right, color: Colors.grey[400]),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
     return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 16,
            color: Colors.grey.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No results found',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting filters to see more.',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

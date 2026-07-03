import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../providers/user_provider.dart';
import '../../../services/placement_session_service.dart';
import '../../../models/placement_session.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MyAttendanceTab extends StatefulWidget {
  const MyAttendanceTab({super.key});

  @override
  State<MyAttendanceTab> createState() => _MyAttendanceTabState();
}

class _MyAttendanceTabState extends State<MyAttendanceTab> {
  late PlacementSessionService _service;
  bool _isLoading = true;
  PlacementAttendanceSummary? _summary;
  
  final DateTime _selectedMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    _service = PlacementSessionService(Supabase.instance.client);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final userId = Provider.of<UserProvider>(context, listen: false).currentUser?.uid;
    if (userId == null) return;

    try {
      final summary = await _service.fetchAttendanceSummary(userId);
      await _service.fetchMyAttendance(userId);
      
      if (mounted) {
        setState(() {
          _summary = summary;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFFF6B4A)));
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: const Color(0xFFFF6B4A),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildCalendarCard(),
          const SizedBox(height: 16),
          _buildStatsAndMascotCard(),
          const SizedBox(height: 16),
          _buildConsistencyInfoCard(),
          const SizedBox(height: 16),
          _buildThisWeekCard(),
        ],
      ),
    );
  }

  Widget _buildCalendarCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF0F0F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    DateFormat('MMMM yyyy').format(_selectedMonth),
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2D3142),
                    ),
                  ),
                  const Icon(LucideIcons.chevronDown, size: 16, color: Color(0xFF9094A6)),
                ],
              ),
              Row(
                children: [
                  Text('Less', style: GoogleFonts.inter(fontSize: 9, color: const Color(0xFF9094A6))),
                  const SizedBox(width: 8),
                  _buildLegendBox(const Color(0xFFFBE4D8)),
                  _buildLegendBox(const Color(0xFFF6C8A6)),
                  _buildLegendBox(const Color(0xFFF2A374)),
                  _buildLegendBox(const Color(0xFFFF6B4A)),
                  const SizedBox(width: 8),
                  Text('More', style: GoogleFonts.inter(fontSize: 9, color: const Color(0xFF9094A6))),
                ],
              )
            ],
          ),
          const SizedBox(height: 20),
          // Simplified placeholder for calendar heatmap grid
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                .map((day) => Text(day, style: GoogleFonts.inter(fontSize: 9, color: const Color(0xFF9094A6))))
                .toList(),
          ),
          const SizedBox(height: 12),
          // Placeholder grid for rows
          for (int i = 0; i < 5; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(7, (index) {
                  // Some random heatmap coloring for the mockup feel
                  final colors = [
                    const Color(0xFFFBE4D8),
                    const Color(0xFFF6C8A6),
                    const Color(0xFFF2A374),
                    const Color(0xFFFF6B4A),
                  ];
                  final isBordered = i == 0 && index == 0; // Highlight
                  return Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isBordered ? Colors.white : colors[(i + index) % 4],
                      borderRadius: BorderRadius.circular(8),
                      border: isBordered ? Border.all(color: const Color(0xFFFF6B4A), width: 2) : null,
                    ),
                  );
                }),
              ),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(LucideIcons.info, size: 12, color: Color(0xFF9094A6)),
              const SizedBox(width: 4),
              Text(
                'Tap a day to view session details',
                style: GoogleFonts.inter(fontSize: 9, color: const Color(0xFF9094A6)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendBox(Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 4),
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildStatsAndMascotCard() {
    final pct = _summary?.attendancePct ?? 0;
    final attended = _summary?.attendedSessions ?? 0;
    final total = _summary?.eligibleSessions ?? 0;

    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFF0F0F0)),
            ),
            child: Column(
              children: [
                Text(
                  '${pct.toStringAsFixed(0)}%',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF2D3142),
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Placement Sessions',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2D3142),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Attended $attended of $total sessions',
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    color: const Color(0xFF9094A6),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(LucideIcons.trendingUp, size: 12, color: Color(0xFF4CAF50)),
                      const SizedBox(width: 4),
                      Text(
                        'Great consistency! Keep it up.',
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF4CAF50),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        // Mascot representation (Image placeholder, using an icon stack since we don't have the exact image asset)
        Expanded(
          flex: 2,
          child: Container(
            height: 180,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Center(
              child: Icon(LucideIcons.calendarCheck2, size: 16, color: Color(0xFFFF6B4A)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConsistencyInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFDF7F3), // Very light orange/pink
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFBE4D8)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Color(0xFFFFE0D6),
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.target, color: Color(0xFFFF6B4A), size: 16),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Consistent attendance = More opportunities',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2D3142),
                  ),
                ),
                Text(
                  'Top performers never miss sessions.',
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    color: const Color(0xFF9094A6),
                  ),
                ),
              ],
            ),
          ),
          const Icon(LucideIcons.chevronRight, color: Color(0xFF9094A6)),
        ],
      ),
    );
  }

  Widget _buildThisWeekCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'This Week',
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2D3142),
              ),
            ),
            Text(
              '4 / 7 attended',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: const Color(0xFF9094A6),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildWeekDayCircle('Mon', true),
            _buildWeekDayCircle('Tue', true),
            _buildWeekDayCircle('Wed', true),
            _buildWeekDayCircle('Thu', true, isToday: true),
            _buildWeekDayCircle('Fri', false),
            _buildWeekDayCircle('Sat', false),
            _buildWeekDayCircle('Sun', false),
          ],
        ),
      ],
    );
  }

  Widget _buildWeekDayCircle(String day, bool attended, {bool isToday = false}) {
    return Column(
      children: [
        Text(
          day,
          style: GoogleFonts.inter(
            fontSize: 9,
            color: const Color(0xFF9094A6),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: attended
                ? (isToday ? const Color(0xFFFF6B4A) : const Color(0xFFFBE4D8))
                : const Color(0xFFF0F0F0),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: attended
                ? Icon(
                    LucideIcons.check,
                    size: 12,
                    color: isToday ? Colors.white : const Color(0xFFFF6B4A),
                  )
                : const Text('-', style: TextStyle(color: Color(0xFF9094A6))),
          ),
        ),
      ],
    );
  }
}

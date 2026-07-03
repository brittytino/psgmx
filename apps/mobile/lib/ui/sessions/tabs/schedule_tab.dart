import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../providers/user_provider.dart';
import '../../../services/placement_session_service.dart';
import '../../../models/placement_session.dart';
import '../widgets/new_session_bottom_sheet.dart';

class ScheduleTab extends StatefulWidget {
  const ScheduleTab({super.key});

  @override
  State<ScheduleTab> createState() => _ScheduleTabState();
}

class _ScheduleTabState extends State<ScheduleTab> {
  late PlacementSessionService _service;
  bool _isLoading = true;
  List<PlacementSession> _sessions = [];
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _service = PlacementSessionService(Supabase.instance.client);
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    setState(() => _isLoading = true);
    final batchId = Provider.of<UserProvider>(context, listen: false).currentUser?.batchId;
    if (batchId == null) return;

    try {
      final allSessions = await _service.fetchSessionsForBatch(batchId);
      if (mounted) {
        setState(() {
          _sessions = allSessions;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showNewSessionSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: NewSessionBottomSheet(
          onSessionCreated: _loadSessions,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFFF6B4A)));
    }

    final filteredSessions = _sessions.where((s) => 
      s.sessionDatetime.year == _selectedDate.year &&
      s.sessionDatetime.month == _selectedDate.month &&
      s.sessionDatetime.day == _selectedDate.day
    ).toList();

    return RefreshIndicator(
      onRefresh: _loadSessions,
      color: const Color(0xFFFF6B4A),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildCalendarStrip(),
          const SizedBox(height: 16),
          _buildManageBanner(),
          const SizedBox(height: 16),
          _buildFilters(),
          const SizedBox(height: 16),
          Text(
            DateFormat('EEEE, dd MMMM yyyy').format(_selectedDate),
            style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF2D3142)),
          ),
          const SizedBox(height: 12),
          if (filteredSessions.isEmpty)
            _buildEmptyState()
          else
            ...filteredSessions.map((s) => _buildSessionCard(s)),
        ],
      ),
    );
  }

  Widget _buildCalendarStrip() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF0F0F0)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(LucideIcons.calendar, size: 12, color: Color(0xFFFF6B4A)),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('MMMM yyyy').format(_selectedDate),
                    style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF2D3142)),
                  ),
                  const Icon(LucideIcons.chevronDown, size: 16, color: Color(0xFF9094A6)),
                ],
              ),
              Row(
                children: [
                  Text('Week', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFFFF6B4A))),
                  const SizedBox(width: 16),
                  Text('Month', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF9094A6))),
                ],
              )
            ],
          ),
          const SizedBox(height: 16),
          // Placeholder for the week row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Icon(LucideIcons.chevronLeft, size: 16, color: Color(0xFF9094A6)),
              ...List.generate(7, (index) {
                final date = _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1 - index));
                final isSelected = date.day == _selectedDate.day && date.month == _selectedDate.month;
                return GestureDetector(
                  onTap: () => setState(() => _selectedDate = date),
                  child: Column(
                    children: [
                      Text(DateFormat('E').format(date), style: GoogleFonts.inter(fontSize: 9, color: const Color(0xFF9094A6))),
                      const SizedBox(height: 8),
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFFFF6B4A) : Colors.transparent,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            date.day.toString(),
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? Colors.white : const Color(0xFF2D3142),
                            ),
                          ),
                        ),
                      ),
                      if (isSelected) ...[
                        const SizedBox(height: 4),
                        Text('Today', style: GoogleFonts.inter(fontSize: 8, color: const Color(0xFFFF6B4A))),
                      ]
                    ],
                  ),
                );
              }),
              const Icon(LucideIcons.chevronRight, size: 16, color: Color(0xFF9094A6)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildManageBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFDF7F3),
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
            child: const Icon(LucideIcons.calendarClock, color: Color(0xFFFF6B4A), size: 16),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Manage and schedule placement sessions', style: GoogleFonts.inter(fontSize: 9, color: const Color(0xFF2D3142))),
              ],
            ),
          ),
          OutlinedButton.icon(
            onPressed: _showNewSessionSheet,
            icon: const Icon(LucideIcons.plusCircle, size: 12, color: Color(0xFFFF6B4A)),
            label: Text('New Session', style: GoogleFonts.inter(color: const Color(0xFFFF6B4A), fontWeight: FontWeight.w600)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFFF6B4A)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          Container(
            width: 160,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.search, size: 12, color: Color(0xFF9094A6)),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    decoration: InputDecoration.collapsed(
                      hintText: 'Search sessions',
                      hintStyle: GoogleFonts.inter(fontSize: 9, color: const Color(0xFF9094A6)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _buildFilterDropdown('All Types'),
          const SizedBox(width: 8),
          _buildFilterDropdown('All Trainers'),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.filter, size: 12, color: Color(0xFF4B5563)),
                const SizedBox(width: 4),
                Text('Filter', style: GoogleFonts.inter(fontSize: 9, color: const Color(0xFF4B5563))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 9, color: const Color(0xFF4B5563))),
          const SizedBox(width: 4),
          const Icon(LucideIcons.chevronDown, size: 12, color: Color(0xFF4B5563)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF0F0F0)),
      ),
      child: Center(
        child: Column(
          children: [
            const Icon(LucideIcons.calendarSearch, size: 16, color: Color(0xFFD1D5DB)),
            const SizedBox(height: 16),
            Text('No sessions scheduled', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF4B5563))),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionCard(PlacementSession s) {
    // Generate derived colors based on sessionType
    Color typeColor = const Color(0xFFFF6B4A);
    IconData typeIcon = LucideIcons.code2;
    if (s.sessionType == 'Technical') {
      typeColor = const Color(0xFF4CAF50);
      typeIcon = LucideIcons.bookOpen;
    } else if (s.sessionType == 'Soft Skills') {
      typeColor = const Color(0xFF2196F3);
      typeIcon = LucideIcons.messageCircle;
    }

    final endTime = s.sessionDatetime.add(Duration(minutes: s.durationMinutes));

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF0F0F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: typeColor,
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), bottomLeft: Radius.circular(16)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(DateFormat('hh:mm a').format(s.sessionDatetime), style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.bold, color: const Color(0xFF2D3142))),
                  Text('-', style: GoogleFonts.inter(fontSize: 9, color: const Color(0xFF9094A6))),
                  Text(DateFormat('hh:mm a').format(endTime), style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.bold, color: const Color(0xFF2D3142))),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF6F5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text('Upcoming', style: GoogleFonts.inter(fontSize: 8, color: const Color(0xFFFF6B4A), fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
            Container(
              width: 1,
              color: const Color(0xFFF0F0F0),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: typeColor.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(typeIcon, color: typeColor, size: 16),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(s.sessionType, style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.bold, color: typeColor)),
                              Text(s.topic, style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF2D3142))),
                              if (s.description != null && s.description!.isNotEmpty)
                                Text(s.description!, style: GoogleFonts.inter(fontSize: 9, color: const Color(0xFF9094A6)), maxLines: 1, overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                        const Icon(LucideIcons.moreVertical, size: 16, color: Color(0xFF9094A6)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(LucideIcons.user, size: 12, color: Color(0xFF9094A6)),
                        const SizedBox(width: 4),
                        Text('Trainer: ${s.scheduledBy.substring(0, 4)}', style: GoogleFonts.inter(fontSize: 9, color: const Color(0xFF9094A6))),
                        const SizedBox(width: 12),
                        const Icon(LucideIcons.users, size: 12, color: Color(0xFF9094A6)),
                        const SizedBox(width: 4),
                        Text('Target: ${s.isBatchWide ? "All Teams" : "Selected Teams"}', style: GoogleFonts.inter(fontSize: 9, color: const Color(0xFF9094A6))),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(s.sessionMode == 'Offline' ? LucideIcons.mapPin : LucideIcons.globe, size: 12, color: const Color(0xFF9094A6)),
                            const SizedBox(width: 4),
                            Text(s.location, style: GoogleFonts.inter(fontSize: 9, color: const Color(0xFF9094A6))),
                          ],
                        ),
                        OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(LucideIcons.pencil, size: 12, color: Color(0xFFFF6B4A)),
                          label: Text('Edit', style: GoogleFonts.inter(fontSize: 9, color: const Color(0xFFFF6B4A))),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFFF6B4A)),
                            minimumSize: const Size(0, 30),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

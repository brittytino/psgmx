import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../providers/user_provider.dart';
import '../../../services/placement_session_service.dart';

class NewSessionBottomSheet extends StatefulWidget {
  final VoidCallback onSessionCreated;

  const NewSessionBottomSheet({super.key, required this.onSessionCreated});

  @override
  State<NewSessionBottomSheet> createState() => _NewSessionBottomSheetState();
}

class _NewSessionBottomSheetState extends State<NewSessionBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  
  String _sessionType = 'Aptitude';
  final _titleController = TextEditingController();
  final _topicController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _startTime = const TimeOfDay(hour: 10, minute: 0);
  int _durationMinutes = 90;
  
  String _sessionMode = 'Offline';
  final String _location = 'Room 201';

  bool _isLoading = false;

  void _createSession() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    final user = Provider.of<UserProvider>(context, listen: false).currentUser;
    if (user == null || user.batchId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final sessionDatetime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _startTime.hour,
        _startTime.minute,
      );

      final service = PlacementSessionService(Supabase.instance.client);
      await service.schedulePlacementSession(
        batchId: user.batchId!,
        scheduledBy: user.uid,
        sessionDatetime: sessionDatetime,
        topic: _titleController.text,
        description: _topicController.text,
        sessionType: _sessionType,
        sessionMode: _sessionMode,
        durationMinutes: _durationMinutes,
        location: _location,
        targetTeamIds: null, // Null means all teams
      );

      widget.onSessionCreated();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Session created successfully!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error creating session: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(LucideIcons.chevronLeft, color: Color(0xFF2D3142)),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'New Placement Session',
                        style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF2D3142)),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F0F0),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(LucideIcons.x, size: 12, color: Color(0xFF2D3142)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(left: 40),
                child: Text('Schedule a new session for your students', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF9094A6))),
              ),
              const SizedBox(height: 24),
              
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF6F5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFBE4D8)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(LucideIcons.calendarClock, color: Color(0xFFFF6B4A), size: 16),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Plan a great session!', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF2D3142))),
                          Text('Well-planned sessions lead to better learning and better outcomes.', style: GoogleFonts.inter(fontSize: 9, color: const Color(0xFF9094A6))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              Text('Session Type', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF2D3142))),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _buildTypeButton('Aptitude', LucideIcons.code2)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildTypeButton('Technical', LucideIcons.bookOpen)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildTypeButton('Soft Skills', LucideIcons.messageCircle)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildTypeButton('Other', LucideIcons.target)),
                ],
              ),
              const SizedBox(height: 16),

              Text('Session Title', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF2D3142))),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                decoration: InputDecoration(
                  hintText: 'e.g. Quantitative Aptitude - Number System',
                  hintStyle: GoogleFonts.inter(color: const Color(0xFFD1D5DB)),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                ),
              ),
              const SizedBox(height: 16),

              Text('Topic / Focus Area', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF2D3142))),
              const SizedBox(height: 8),
              TextFormField(
                controller: _topicController,
                decoration: InputDecoration(
                  hintText: 'e.g. Arithmetic, Percentages, Profit & Loss',
                  hintStyle: GoogleFonts.inter(color: const Color(0xFFD1D5DB)),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                ),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Date', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF2D3142))),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: _selectedDate,
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (date != null) setState(() => _selectedDate = date);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                            decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE5E7EB)), borderRadius: BorderRadius.circular(12)),
                            child: Row(
                              children: [
                                const Icon(LucideIcons.calendar, size: 12, color: Color(0xFF9094A6)),
                                const SizedBox(width: 8),
                                Text(DateFormat('dd MMM yyyy').format(_selectedDate), style: GoogleFonts.inter(color: const Color(0xFF4B5563))),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Time', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF2D3142))),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () async {
                            final time = await showTimePicker(
                              context: context,
                              initialTime: _startTime,
                            );
                            if (time != null) setState(() => _startTime = time);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                            decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE5E7EB)), borderRadius: BorderRadius.circular(12)),
                            child: Row(
                              children: [
                                const Icon(LucideIcons.clock, size: 12, color: Color(0xFF9094A6)),
                                const SizedBox(width: 8),
                                Text(_startTime.format(context), style: GoogleFonts.inter(color: const Color(0xFF4B5563))),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Duration', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF2D3142))),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE5E7EB)), borderRadius: BorderRadius.circular(12)),
                          child: Row(
                            children: [
                              const Icon(LucideIcons.clock, size: 12, color: Color(0xFF9094A6)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<int>(
                                    value: _durationMinutes,
                                    isDense: true,
                                    isExpanded: true,
                                    items: [30, 60, 90, 120].map((v) => DropdownMenuItem(value: v, child: Text('${v ~/ 60} hr ${v % 60} min', style: GoogleFonts.inter(fontSize: 11)))).toList(),
                                    onChanged: (v) => setState(() => _durationMinutes = v!),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Session Mode', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF2D3142))),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(child: _buildModeButton('Offline')),
                            const SizedBox(width: 8),
                            Expanded(child: _buildModeButton('Online')),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _createSession,
                  icon: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Icon(LucideIcons.calendarPlus, color: Colors.white),
                  label: Text('Create Session', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B4A),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeButton(String title, IconData icon) {
    final isSelected = _sessionType == title;
    return GestureDetector(
      onTap: () => setState(() => _sessionType = title),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFF6F5) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? const Color(0xFFFF6B4A) : const Color(0xFFE5E7EB)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 16, color: isSelected ? const Color(0xFFFF6B4A) : const Color(0xFF9094A6)),
            const SizedBox(height: 4),
            Text(
              title,
              style: GoogleFonts.inter(fontSize: 9, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500, color: isSelected ? const Color(0xFFFF6B4A) : const Color(0xFF4B5563)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeButton(String title) {
    final isSelected = _sessionMode == title;
    return GestureDetector(
      onTap: () => setState(() => _sessionMode = title),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFF6F5) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? const Color(0xFFFF6B4A) : const Color(0xFFE5E7EB)),
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(title == 'Offline' ? LucideIcons.building : LucideIcons.globe, size: 12, color: isSelected ? const Color(0xFFFF6B4A) : const Color(0xFF9094A6)),
              const SizedBox(width: 4),
              Text(
                title,
                style: GoogleFonts.inter(fontSize: 9, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500, color: isSelected ? const Color(0xFFFF6B4A) : const Color(0xFF4B5563)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

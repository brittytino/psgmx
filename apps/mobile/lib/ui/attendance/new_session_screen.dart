import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/rive_placeholder.dart';

class NewSessionScreen extends StatefulWidget {
  const NewSessionScreen({super.key});

  @override
  State<NewSessionScreen> createState() => _NewSessionScreenState();
}

class _NewSessionScreenState extends State<NewSessionScreen> {
  String _sessionType = 'Aptitude';
  String _sessionMode = 'Offline';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft),
          onPressed: () => context.pop(),
        ),
        title: Column(
          children: [
            Text(
              'New Placement Session',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            Text(
              'Schedule a new session for your students',
              style: GoogleFonts.inter(
                fontSize: 9,
                color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.x, size: 16),
            onPressed: () => context.pop(),
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(left: 24.0, right: 24.0, top: 16.0, bottom: 120.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Illustration Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAF9F6),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: theme.dividerColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const RivePlaceholder(width: 56, height: 56, label: 'Calendar', icon: LucideIcons.calendarClock),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Plan a great session!',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Well-planned sessions lead to better learning and better outcomes.',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      const RivePlaceholder(width: 60, height: 60, label: 'Teacher Mascot', icon: LucideIcons.user),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // Form Fields
                _buildSectionTitle('Session Type', theme),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildSessionTypeButton('Aptitude', LucideIcons.code2, theme)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildSessionTypeButton('Technical', LucideIcons.bookOpen, theme)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildSessionTypeButton('Soft Skills', LucideIcons.messageCircle, theme)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildSessionTypeButton('Other', LucideIcons.target, theme)),
                  ],
                ),
                const SizedBox(height: 24),
                
                _buildSectionTitle('Session Title', theme),
                const SizedBox(height: 8),
                _buildTextField('e.g. Quantitative Aptitude - Number System', theme),
                const SizedBox(height: 24),
                
                _buildSectionTitle('Topic / Focus Area', theme),
                const SizedBox(height: 8),
                _buildTextField('e.g. Arithmetic, Percentages, Profit & Loss', theme),
                const SizedBox(height: 24),
                
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle('Date', theme),
                          const SizedBox(height: 8),
                          _buildDropdownField('22 Apr 2025', LucideIcons.calendar, theme),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle('Time', theme),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(child: _buildTimeField('10:00 AM', theme)),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8.0),
                                child: Text('-'),
                              ),
                              Expanded(child: _buildTimeField('11:30 AM', theme)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle('Duration', theme),
                          const SizedBox(height: 8),
                          _buildDropdownField('1 hr 30 min', LucideIcons.clock, theme),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle('Session Mode', theme),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(child: _buildModeButton('Offline', LucideIcons.building, theme)),
                              const SizedBox(width: 8),
                              Expanded(child: _buildModeButton('Online', LucideIcons.globe, theme)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                _buildSectionTitle('Location / Room', theme),
                const SizedBox(height: 8),
                _buildDropdownField('Room 201', LucideIcons.mapPin, theme),
                const SizedBox(height: 24),
                
                _buildSectionTitle('Trainer', theme),
                const SizedBox(height: 8),
                _buildDropdownField('Rishabh T.', LucideIcons.user, theme),
                const SizedBox(height: 24),
                
                _buildSectionTitle('Target Audience', theme),
                const SizedBox(height: 8),
                _buildDropdownField('3rd Year', LucideIcons.users, theme),
                const SizedBox(height: 24),
                
                _buildSectionTitle('Description (Optional)', theme),
                const SizedBox(height: 8),
                TextField(
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Add details about the session, what students will learn, prerequisites, etc.',
                    hintStyle: GoogleFonts.inter(color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5), fontSize: 11),
                    filled: true,
                    fillColor: const Color(0xFFFAFAFA),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: theme.dividerColor.withValues(alpha: 0.5)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: theme.dividerColor.withValues(alpha: 0.5)),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text('0/300', style: GoogleFonts.inter(fontSize: 9, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5))),
                ),
                const SizedBox(height: 24),
                
                _buildSectionTitle('Attachments / Resources (Optional)', theme),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAF9F6),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.accentCoral.withValues(alpha: 0.3), style: BorderStyle.solid), // Should be dashed but keeping it simple
                  ),
                  child: Column(
                    children: [
                      const Icon(LucideIcons.upload, color: AppTheme.accentCoral),
                      const SizedBox(height: 8),
                      Text('Upload slides, notes or materials', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: theme.colorScheme.onSurface)),
                      const SizedBox(height: 4),
                      Text('PDF, PPT, DOC up to 10MB', style: GoogleFonts.inter(fontSize: 9, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5))),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // Bottom Tip
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAF9F6),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: theme.dividerColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.accentCoral.withValues(alpha: 0.2)),
                        ),
                        child: const Icon(LucideIcons.lightbulb, color: AppTheme.accentCoral, size: 12),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Tip: Clear topics + right timing = Better Attendance', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
                            const SizedBox(height: 2),
                            Text('Students are more likely to show up and engage.', style: GoogleFonts.inter(fontSize: 9, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7))),
                          ],
                        ),
                      ),
                      const RivePlaceholder(width: 48, height: 48, label: 'Thumbs Up', icon: LucideIcons.thumbsUp),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Fixed Bottom Button
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, -10),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: FilledButton.icon(
                  onPressed: () {},
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.accentCoral,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: const Icon(LucideIcons.calendarPlus, size: 12),
                  label: Text('Create Session', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, ThemeData theme) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.onSurface,
      ),
    );
  }

  Widget _buildSessionTypeButton(String label, IconData icon, ThemeData theme) {
    final isSelected = _sessionType == label;
    return GestureDetector(
      onTap: () => setState(() => _sessionType = label),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.accentCoral : theme.dividerColor.withValues(alpha: 0.5),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 12, color: isSelected ? AppTheme.accentCoral : theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5)),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 8,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? AppTheme.accentCoral : theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeButton(String label, IconData icon, ThemeData theme) {
    final isSelected = _sessionMode == label;
    return GestureDetector(
      onTap: () => setState(() => _sessionMode = label),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.accentCoral.withValues(alpha: 0.05) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.accentCoral : theme.dividerColor.withValues(alpha: 0.5),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 12, color: isSelected ? AppTheme.accentCoral : theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5)),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 9,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? AppTheme.accentCoral : theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String hint, ThemeData theme) {
    return TextField(
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.4), fontSize: 11),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.dividerColor.withValues(alpha: 0.5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.dividerColor.withValues(alpha: 0.5)),
        ),
      ),
    );
  }

  Widget _buildDropdownField(String value, IconData icon, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5)),
              const SizedBox(width: 8),
              Text(value, style: GoogleFonts.inter(fontSize: 11, color: theme.colorScheme.onSurface)),
            ],
          ),
          Icon(LucideIcons.chevronDown, size: 12, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5)),
        ],
      ),
    );
  }

  Widget _buildTimeField(String time, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.clock, size: 12, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5)),
          const SizedBox(width: 6),
          Text(time, style: GoogleFonts.inter(fontSize: 11, color: theme.colorScheme.onSurface)),
        ],
      ),
    );
  }
}

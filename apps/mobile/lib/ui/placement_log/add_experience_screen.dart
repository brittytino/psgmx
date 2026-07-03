import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/rive_placeholder.dart';

class AddExperienceScreen extends StatefulWidget {
  const AddExperienceScreen({super.key});

  @override
  State<AddExperienceScreen> createState() => _AddExperienceScreenState();
}

class _AddExperienceScreenState extends State<AddExperienceScreen> {
  final Set<String> _selectedRounds = {
    'Aptitude',
    'Coding',
    'Group Discussion',
    'Technical Interview',
    'HR Interview',
  };

  int _difficulty = 4;
  int _stars = 3;
  bool _isPublic = true;

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
              'Add your experience',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Help your juniors. Leave a legacy.',
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(LucideIcons.sparkles, size: 12, color: AppTheme.illusGold),
              ],
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          const RivePlaceholder(width: 48, height: 48, label: 'Briefcase', icon: LucideIcons.briefcase),
          const SizedBox(width: 16),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(left: 24.0, right: 24.0, top: 16.0, bottom: 120.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Tip Banner
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
                        child: const Icon(LucideIcons.lightbulb, color: AppTheme.accentCoral, size: 16),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Your insights can guide the next placer.',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Share what really happened—good, tough, all of it.',
                              style: GoogleFonts.inter(
                                fontSize: 9,
                                color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                
                // Company Details Section
                _buildSectionHeader('Company Details', theme),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFieldLabel('Company Name', theme),
                          const SizedBox(height: 8),
                          _buildTextField('Search or enter company', LucideIcons.search, theme),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFieldLabel('Role / Designation', theme),
                          const SizedBox(height: 8),
                          _buildTextField('e.g. Software Engineer', null, theme),
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
                          _buildFieldLabel('Offer Type', theme),
                          const SizedBox(height: 8),
                          _buildDropdownField('Select offer type', theme),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFieldLabel('Package (CTC)', theme),
                          const SizedBox(height: 8),
                          _buildTextField('₹ Min - Max LPA', null, theme),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildFieldLabel('Visited On', theme),
                const SizedBox(height: 8),
                _buildTextField('Select date', LucideIcons.calendar, theme),
                const SizedBox(height: 32),
                
                // Process Details Section
                _buildSectionHeader('Process Details', theme),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFieldLabel('Your Role', theme),
                          const SizedBox(height: 8),
                          _buildDropdownField('Select your role', theme),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFieldLabel('Year of Passing', theme),
                          const SizedBox(height: 8),
                          _buildDropdownField('Select year', theme),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildFieldLabel('Rounds You Went Through (Select all that apply)', theme),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _buildCheckboxChip('Aptitude', theme),
                    _buildCheckboxChip('Coding', theme),
                    _buildCheckboxChip('Group Discussion', theme),
                    _buildCheckboxChip('Technical Interview', theme),
                    _buildCheckboxChip('HR Interview', theme),
                    _buildCheckboxChip('Managerial Interview', theme),
                    _buildCheckboxChip('Other', theme),
                  ],
                ),
                const SizedBox(height: 32),
                _buildFieldLabel('How would you rate the difficulty level?', theme),
                const SizedBox(height: 16),
                
                // Difficulty Slider mock
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildDifficultyNode(1, 'Very Easy', theme),
                      Expanded(child: _buildSliderLine(1)),
                      _buildDifficultyNode(2, 'Easy', theme),
                      Expanded(child: _buildSliderLine(2)),
                      _buildDifficultyNode(3, 'Moderate', theme),
                      Expanded(child: _buildSliderLine(3)),
                      _buildDifficultyNode(4, 'Hard', theme),
                      Expanded(child: _buildSliderLine(4)),
                      _buildDifficultyNode(5, 'Very Hard', theme),
                    ],
                  ),
                ),
                const SizedBox(height: 48),
                
                // Your Experience Section
                _buildSectionHeader('Your Experience', theme),
                const SizedBox(height: 16),
                _buildFieldLabel('Overall Experience', theme),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: List.generate(5, (index) {
                        return GestureDetector(
                          onTap: () {
                            setState(() => _stars = index + 1);
                          },
                          child: Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: Icon(
                              index < _stars ? Icons.star : Icons.star_border,
                              size: 16,
                              color: AppTheme.accentCoral,
                            ),
                          ),
                        );
                      }),
                    ),
                    Container(
                      width: 140,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Good', style: GoogleFonts.inter(fontSize: 11, color: theme.colorScheme.onSurface)),
                          Icon(LucideIcons.chevronDown, size: 12, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildFieldLabel('Your Write-up', theme),
                const SizedBox(height: 8),
                TextField(
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: 'Share about the college support, preparation strategy, interview experience, tips for juniors, and anything you wish you knew earlier.',
                    hintStyle: GoogleFonts.inter(color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5), fontSize: 11, height: 1.5),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.all(16),
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
                  child: Text('0/1000', style: GoogleFonts.inter(fontSize: 9, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5))),
                ),
                const SizedBox(height: 32),
                
                // Anonymous or Public
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAF9F6),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: theme.dividerColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(LucideIcons.shieldCheck, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5), size: 16),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Anonymous or Public',
                              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Your name will be shown with your experience.\nYou can\'t edit or delete it later.',
                              style: GoogleFonts.inter(fontSize: 9, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7)),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _isPublic,
                        onChanged: (val) {
                          setState(() => _isPublic = val);
                        },
                        activeThumbColor: Colors.white,
                        activeTrackColor: AppTheme.accentCoral,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // Bottom Tip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.accentCoral.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.accentCoral.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.accentCoral.withValues(alpha: 0.3)),
                        ),
                        child: const Icon(LucideIcons.heart, color: AppTheme.accentCoral, size: 16),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Be honest. Be helpful. Be you.',
                              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                            ),
                            Text(
                              'Your story could be the reason someone gets placed.',
                              style: GoogleFonts.inter(fontSize: 9, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7)),
                            ),
                          ],
                        ),
                      ),
                      const RivePlaceholder(width: 48, height: 48, label: 'Happy Mascot', icon: LucideIcons.smile),
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
                  icon: const Icon(LucideIcons.send, size: 12),
                  label: Text('Submit Experience', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, ThemeData theme) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.onSurface,
      ),
    );
  }

  Widget _buildFieldLabel(String label, ThemeData theme) {
    return Text(
      label,
      style: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: theme.colorScheme.onSurface,
      ),
    );
  }

  Widget _buildTextField(String hint, IconData? prefixIcon, ThemeData theme) {
    return TextField(
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.4), fontSize: 11),
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 12, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.4)) : null,
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

  Widget _buildDropdownField(String hint, ThemeData theme) {
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
          Text(hint, style: GoogleFonts.inter(fontSize: 11, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5))),
          Icon(LucideIcons.chevronDown, size: 12, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5)),
        ],
      ),
    );
  }

  Widget _buildCheckboxChip(String label, ThemeData theme) {
    final isSelected = _selectedRounds.contains(label);
    
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedRounds.remove(label);
          } else {
            _selectedRounds.add(label);
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.accentCoral.withValues(alpha: 0.08) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppTheme.accentCoral : theme.dividerColor.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.accentCoral : Colors.white,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: isSelected ? AppTheme.accentCoral : theme.dividerColor.withValues(alpha: 0.5),
                ),
              ),
              child: isSelected 
                  ? const Icon(Icons.check, size: 12, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? AppTheme.accentCoral : theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDifficultyNode(int level, String label, ThemeData theme) {
    final isSelected = _difficulty == level;
    final isPast = level < _difficulty;
    
    return GestureDetector(
      onTap: () {
        setState(() => _difficulty = level);
      },
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.accentCoral : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected || isPast ? AppTheme.accentCoral : theme.dividerColor.withValues(alpha: 0.5),
                width: isSelected ? 0 : 1,
              ),
            ),
            child: Center(
              child: Text(
                level.toString(),
                style: GoogleFonts.sora(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : (isPast ? AppTheme.accentCoral : theme.colorScheme.onSurface),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 8,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? AppTheme.accentCoral : theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliderLine(int currentLevel) {
    final isPast = currentLevel < _difficulty;
    return Container(
      height: 2,
      margin: const EdgeInsets.only(bottom: 24), // Offset to align with circles not labels
      color: isPast ? AppTheme.accentCoral : Colors.grey.withValues(alpha: 0.2),
    );
  }
}

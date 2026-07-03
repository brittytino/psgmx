import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/rive_placeholder.dart';

class BulkUploadScreen extends StatefulWidget {
  const BulkUploadScreen({super.key});

  @override
  State<BulkUploadScreen> createState() => _BulkUploadScreenState();
}

class _BulkUploadScreenState extends State<BulkUploadScreen> {

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
              'Bulk Upload Placement Data',
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
                  'Upload past placement logs in bulk.',
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
          const RivePlaceholder(width: 48, height: 48, label: 'Excel', icon: LucideIcons.fileSpreadsheet),
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
                // Info Banner
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
                          border: Border.all(color: AppTheme.accentCoral.withValues(alpha: 0.3)),
                        ),
                        child: const Icon(LucideIcons.info, color: AppTheme.accentCoral, size: 12),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'For Placement Representatives',
                              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                            ),
                            Text(
                              'Use this to upload past placement data for multiple companies and students.',
                              style: GoogleFonts.inter(fontSize: 9, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // Stepper
                Row(
                  children: [
                    Expanded(child: _buildStepTab('Upload File', LucideIcons.upload, true, theme)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildStepTab('Preview & Import', null, false, theme, number: '2')),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Dropzone
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAF9F6),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.accentCoral.withValues(alpha: 0.2), style: BorderStyle.solid), // Dashed border theoretically
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.accentCoral.withValues(alpha: 0.1)),
                        ),
                        child: const Icon(LucideIcons.uploadCloud, color: AppTheme.accentCoral, size: 16),
                      ),
                      const SizedBox(height: 16),
                      Text('Drag & drop your file here', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
                      const SizedBox(height: 4),
                      RichText(
                        text: TextSpan(
                          style: GoogleFonts.inter(fontSize: 11, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6)),
                          children: [
                            const TextSpan(text: 'or '),
                            TextSpan(text: 'browse', style: TextStyle(color: AppTheme.accentCoral, fontWeight: FontWeight.bold)),
                            const TextSpan(text: ' from your device'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text('Supported format: .xlsx, .xls', style: GoogleFonts.inter(fontSize: 9, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5))),
                      Text('Maximum file size: 16 MB', style: GoogleFonts.inter(fontSize: 9, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5))),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () {},
                          style: FilledButton.styleFrom(
                            backgroundColor: AppTheme.accentCoral,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          icon: const Icon(LucideIcons.fileText, size: 12),
                          label: Text('Choose File', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // Download Template
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: theme.dividerColor.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Download Template', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
                                Text('Download the Excel template and fill in the data as per the columns.', style: GoogleFonts.inter(fontSize: 9, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6))),
                              ],
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: () {},
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.accentCoral,
                              side: const BorderSide(color: AppTheme.accentCoral),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            icon: const Icon(LucideIcons.download, size: 12),
                            label: Text('Download Template', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Divider(height: 1, color: theme.dividerColor.withValues(alpha: 0.3)),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Icon(LucideIcons.fileSpreadsheet, size: 12, color: Colors.green),
                          const SizedBox(width: 8),
                          Expanded(child: Text('Template includes all required fields with examples.', style: GoogleFonts.inter(fontSize: 9, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6)))),
                          Text('View Columns', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.accentCoral)),
                          const SizedBox(width: 4),
                          const Icon(LucideIcons.chevronDown, size: 12, color: AppTheme.accentCoral),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // Template Includes Grid
                Text('Template Includes', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
                const SizedBox(height: 4),
                Text('The template captures all details required for a placement log entry.', style: GoogleFonts.inter(fontSize: 9, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6))),
                const SizedBox(height: 16),
                
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    _buildTemplateGridCard('Company Details', 'Name, Role, Offer Type', LucideIcons.building, theme),
                    _buildTemplateGridCard('Offer Details', 'Package (Min, Max), CTC', LucideIcons.indianRupee, theme),
                    _buildTemplateGridCard('Student Details', 'Name, Roll No, Batch', LucideIcons.user, theme),
                    _buildTemplateGridCard('Process Details', 'Rounds, Difficulty', LucideIcons.layers, theme),
                    _buildTemplateGridCard('Result & Status', 'Placed / Not Placed', LucideIcons.checkCircle, theme),
                    _buildTemplateGridCard('Visit Details', 'Visited On, Year', LucideIcons.calendar, theme),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Important Notes
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
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Important Notes', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
                            const SizedBox(height: 16),
                            _buildCheckmarkItem('Ensure the file follows the template format. Columns should not be renamed.', theme),
                            _buildCheckmarkItem('Date format should be DD-MM-YYYY.', theme),
                            _buildCheckmarkItem('All mandatory fields must be filled.', theme),
                            _buildCheckmarkItem('Duplicate records (Roll No + Company) will be skipped.', theme),
                          ],
                        ),
                      ),
                      const RivePlaceholder(width: 80, height: 100, label: 'Clipboard', icon: LucideIcons.clipboardCheck),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // Need Help
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: theme.dividerColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFAFAFA),
                          shape: BoxShape.circle,
                          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.3)),
                        ),
                        child: const Icon(LucideIcons.headphones, color: Colors.black87, size: 16),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Need help?', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
                            Text('Read our guide to understand how to fill the template correctly.', style: GoogleFonts.inter(fontSize: 9, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6))),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          Text('View Guide', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.accentCoral)),
                          const SizedBox(width: 4),
                          const Icon(LucideIcons.externalLink, size: 12, color: AppTheme.accentCoral),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Fixed Bottom Section
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
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(LucideIcons.shieldCheck, size: 12, color: Colors.deepPurple.shade300),
                          const SizedBox(width: 8),
                          Text('Your data is secure and will only be used for placement records.', style: GoogleFonts.inter(fontSize: 9, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () {},
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.accentCoral,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        icon: const Icon(LucideIcons.upload, size: 12),
                        label: Text('Upload & Preview', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepTab(String label, IconData? icon, bool isActive, ThemeData theme, {String? number}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: isActive ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isActive ? AppTheme.accentCoral.withValues(alpha: 0.3) : theme.dividerColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: isActive ? AppTheme.accentCoral : theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5)),
            const SizedBox(width: 8),
          ],
          if (number != null) ...[
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: theme.textTheme.bodyMedium!.color!.withValues(alpha: 0.5)),
              ),
              child: Center(
                child: Text(number, style: GoogleFonts.inter(fontSize: 8, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5))),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 9,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              color: isActive ? AppTheme.accentCoral : theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateGridCard(String title, String subtitle, IconData icon, ThemeData theme) {
    return Container(
      width: (MediaQuery.of(context).size.width - 48 - 32) / 2, // Half width minus padding and spacing
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppTheme.accentCoral.withValues(alpha: 0.05),
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.accentCoral.withValues(alpha: 0.2)),
            ),
            child: Icon(icon, size: 12, color: AppTheme.accentCoral),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
                const SizedBox(height: 2),
                Text(subtitle, style: GoogleFonts.inter(fontSize: 8, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckmarkItem(String text, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 2),
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.accentCoral.withValues(alpha: 0.5)),
            ),
            child: const Icon(Icons.check, size: 10, color: AppTheme.accentCoral),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(fontSize: 9, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7)),
            ),
          ),
        ],
      ),
    );
  }
}

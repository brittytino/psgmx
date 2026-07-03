import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';

class PlacementLogScreen extends StatefulWidget {
  const PlacementLogScreen({super.key});

  @override
  State<PlacementLogScreen> createState() => _PlacementLogScreenState();
}

class _PlacementLogScreenState extends State<PlacementLogScreen> {
  // Mock data for the timeline
  final List<Map<String, dynamic>> _companies = [
    {
      'year': '2025',
      'name': 'Microsoft',
      'role': 'Software Engineer',
      'ctc': '₹18 – 24 LPA',
      'offers': 42,
      'date': '18 Apr 2025',
      'isExpanded': false,
    },
    {
      'year': '2025',
      'name': 'Amazon',
      'role': 'SDE Intern',
      'ctc': '₹12 – 16 LPA',
      'offers': 36,
      'date': '10 Apr 2025',
      'isExpanded': false,
    },
    {
      'year': '2024',
      'name': 'Google',
      'role': 'Software Engineer',
      'ctc': '₹20 – 28 LPA',
      'offers': 28,
      'date': '28 Sept 2024',
      'isExpanded': false,
    },
    {
      'year': '2024',
      'name': 'D E Shaw',
      'role': 'Software Development Associate',
      'ctc': '₹15 – 20 LPA',
      'offers': 18,
      'date': '12 Sept 2024',
      'isExpanded': true,
      'experiences': [
        {
          'name': 'Rohan P.',
          'role': 'SDE',
          'batch': '2024 Batch',
          'stars': 5,
          'quote': 'The process was intense but extremely well-structured. Focus on DSA, problem solving speed and communicate your approach clearly.',
        },
        {
          'name': 'Meera R.',
          'role': 'SDE',
          'batch': '2024 Batch',
          'stars': 5,
          'quote': 'Case round was the game changer. Practice estimation and be confident with your assumptions. Be calm and think out loud.',
        },
        {
          'name': 'Karthik S.',
          'role': 'SDE',
          'batch': '2024 Batch',
          'stars': 4,
          'quote': '\'Great culture fit! They value thorough thinking over just coding speed. Revise core CS fundamentals.\'',
        },
      ]
    },
    {
      'year': '2024',
      'name': 'TCS Digital',
      'role': 'System Engineer',
      'ctc': '₹3.6 – 7 LPA',
      'offers': 120,
      'date': '5 Sept 2024',
      'isExpanded': false,
    },
    {
      'year': '2023',
      'name': 'Zoho',
      'role': 'Member Technical Staff',
      'ctc': '₹8 – 12 LPA',
      'offers': 22,
      'date': '14 Oct 2023',
      'isExpanded': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          SafeArea(
            child: CustomScrollView(
              slivers: [
                // Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 24, 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            IconButton(
                              icon: const Icon(LucideIcons.chevronLeft, size: 16),
                              onPressed: () => context.pop(),
                            ),
                            const SizedBox(width: 4),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  'Placement Log',
                                  style: GoogleFonts.sora(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.onSurface,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text(
                                      'Stories. Insights. Inspiration.',
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(LucideIcons.sparkles, size: 12, color: AppTheme.illusGold),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                        OutlinedButton.icon(
                          onPressed: () => context.push('/placement-log/add'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.accentCoral,
                            side: const BorderSide(color: AppTheme.accentCoral),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          icon: const Icon(LucideIcons.plus, size: 12),
                          label: const Text('Add your experience'),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Filters
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: 'Search company',
                              hintStyle: GoogleFonts.inter(fontSize: 11, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5)),
                              prefixIcon: Icon(LucideIcons.search, size: 12, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5)),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(vertical: 0),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide(color: theme.dividerColor.withValues(alpha: 0.3)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide(color: theme.dividerColor.withValues(alpha: 0.3)),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: _buildDropdownFilter('All Roles', null, theme),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: _buildDropdownFilter('All Years', LucideIcons.calendar, theme),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Timeline
                SliverPadding(
                  padding: const EdgeInsets.only(left: 24, right: 24, top: 32, bottom: 120),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final company = _companies[index];
                        final isFirstOfYear = index == 0 || _companies[index - 1]['year'] != company['year'];
                        final isLast = index == _companies.length - 1;
                        
                        return IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Timeline column
                              SizedBox(
                                width: 40,
                                child: Column(
                                  children: [
                                    if (isFirstOfYear)
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 8.0),
                                        child: Text(
                                          company['year'],
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.accentCoral,
                                          ),
                                        ),
                                      )
                                    else
                                      const SizedBox(height: 24), // Spacer if no year label
                                      
                                    Container(
                                      width: 16,
                                      height: 16,
                                      decoration: BoxDecoration(
                                        color: AppTheme.accentCoral.withValues(alpha: 0.2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Container(
                                          width: 8,
                                          height: 8,
                                          decoration: const BoxDecoration(
                                            color: AppTheme.accentCoral,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ),
                                    ),
                                    if (!isLast)
                                      Expanded(
                                        child: Container(
                                          width: 2,
                                          color: AppTheme.accentCoral.withValues(alpha: 0.3),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              
                              // Content Column
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 24.0, left: 16.0),
                                  child: _buildCompanyCard(company, index, theme),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      childCount: _companies.length,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Sticky Bottom Banner
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
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
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
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Every story helps. Every insight matters.',
                                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                                  ),
                                  Text(
                                    'Share your experience and help the next placer.',
                                    style: GoogleFonts.inter(fontSize: 9, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    FilledButton.icon(
                      onPressed: () => context.push('/placement-log/add'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.accentCoral,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      icon: const Icon(LucideIcons.plus, size: 12),
                      label: Text('Add your experience', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
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

  Widget _buildDropdownFilter(String value, IconData? icon, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 12, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5)),
                const SizedBox(width: 8),
              ],
              Text(value, style: GoogleFonts.inter(fontSize: 9, color: theme.colorScheme.onSurface)),
            ],
          ),
          Icon(LucideIcons.chevronDown, size: 12, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5)),
        ],
      ),
    );
  }

  Widget _buildCompanyCard(Map<String, dynamic> company, int index, ThemeData theme) {
    final isExpanded = company['isExpanded'] as bool;
    
    return Container(
      decoration: BoxDecoration(
        color: isExpanded ? const Color(0xFFFAF9F6) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isExpanded ? AppTheme.accentCoral.withValues(alpha: 0.3) : theme.dividerColor.withValues(alpha: 0.3)),
        boxShadow: isExpanded ? [] : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                company['isExpanded'] = !isExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: theme.dividerColor.withValues(alpha: 0.2)),
                    ),
                    child: Center(
                      child: Icon(
                        LucideIcons.building2, 
                        size: 16, 
                        color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              company['name'],
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.accentCoral.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                company['ctc'],
                                style: GoogleFonts.inter(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.accentCoral,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          company['role'],
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(LucideIcons.users, size: 12, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5)),
                            const SizedBox(width: 4),
                            Text('${company['offers']} offers', style: GoogleFonts.inter(fontSize: 9, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6))),
                            const SizedBox(width: 12),
                            Text('·', style: GoogleFonts.inter(fontSize: 9, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6))),
                            const SizedBox(width: 12),
                            Icon(LucideIcons.calendar, size: 12, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5)),
                            const SizedBox(width: 4),
                            Text('Visited on ${company['date']}', style: GoogleFonts.inter(fontSize: 9, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6))),
                            const Spacer(),
                            Icon(isExpanded ? LucideIcons.chevronUp : LucideIcons.chevronDown, size: 16, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          if (isExpanded && company['experiences'] != null)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.dividerColor.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Student Experiences (${(company['experiences'] as List).length})',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  ...(company['experiences'] as List).map((exp) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 24.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: theme.colorScheme.surfaceContainerHighest,
                            child: const Icon(LucideIcons.user),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          exp['name'],
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: theme.colorScheme.onSurface,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppTheme.accentCoral.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            'Placed',
                                            style: GoogleFonts.inter(
                                              fontSize: 8,
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.accentCoral,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: List.generate(5, (starIndex) {
                                        return Icon(
                                          starIndex < exp['stars'] ? Icons.star : Icons.star_border,
                                          size: 12,
                                          color: AppTheme.accentCoral,
                                        );
                                      }),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text(exp['role'], style: GoogleFonts.inter(fontSize: 9, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6))),
                                    const SizedBox(width: 8),
                                    Text('·', style: GoogleFonts.inter(fontSize: 9, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6))),
                                    const SizedBox(width: 8),
                                    Text(exp['batch'], style: GoogleFonts.inter(fontSize: 9, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6))),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '“ ',
                                      style: GoogleFonts.sora(
                                        fontSize: 16,
                                        height: 1,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.accentCoral.withValues(alpha: 0.3),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        exp['quote'],
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          color: theme.colorScheme.onSurface,
                                          height: 1.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  
                  Text(
                    'View all experiences (${(company['experiences'] as List).length}) >',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.accentCoral,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

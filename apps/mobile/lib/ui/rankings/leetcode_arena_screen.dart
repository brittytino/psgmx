import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/rive_placeholder.dart';

import 'package:provider/provider.dart';
import '../../providers/leetcode_provider.dart';
import '../../models/leetcode_stats.dart';
import '../widgets/shared_bottom_navigation_bar.dart';
import '../widgets/avatar_widget.dart';

class LeetcodeArenaScreen extends StatefulWidget {
  const LeetcodeArenaScreen({super.key});

  @override
  State<LeetcodeArenaScreen> createState() => _LeetcodeArenaScreenState();
}

class _LeetcodeArenaScreenState extends State<LeetcodeArenaScreen> {
  bool _isWeekly = true;
  int _displayLimit = 20;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LeetCodeProvider>().fetchAllUsers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<LeetCodeProvider>();
    final users = provider.allUsers;

    // Filter/Sort logic based on _isWeekly
    var sortedUsers = List<LeetCodeStats>.from(users);
    if (_isWeekly) {
      sortedUsers.sort((a, b) => b.weeklyScore.compareTo(a.weeklyScore));
    } else {
      sortedUsers.sort((a, b) => b.totalSolved.compareTo(a.totalSolved));
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      sortedUsers = sortedUsers.where((user) {
        final name = (user.name ?? user.username).toLowerCase();
        final username = user.username.toLowerCase();
        final query = _searchQuery.toLowerCase();
        return name.contains(query) || username.contains(query);
      }).toList();
    }

    final topUser = sortedUsers.isNotEmpty ? sortedUsers.first : null;
    final totalUsers = users.length;
    final displayedCount = math.min(_displayLimit, sortedUsers.length);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      bottomNavigationBar: const SharedBottomNavigationBar(),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'LeetCode Arena',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(LucideIcons.flame, color: AppTheme.accentCoral, size: 12),
              ],
            ),
            Row(
              children: [
                Text(
                  'Code more. Solve smart. Climb higher.',
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
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.dividerColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.helpCircle, size: 12, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7)),
                const SizedBox(width: 4),
                Text('How it works?', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _scrollController.hasClients && _displayLimit > 20
          ? FloatingActionButton.small(
              onPressed: () => _scrollController.animateTo(0, duration: const Duration(milliseconds: 500), curve: Curves.easeOut),
              backgroundColor: AppTheme.accentCoral,
              child: const Icon(LucideIcons.arrowUp, color: Colors.white, size: 12),
            )
          : null,
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 16.0, bottom: 48.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Filters
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: theme.dividerColor.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Expanded(child: _buildFilterSegment('Weekly', _isWeekly, theme, () => setState(() => _isWeekly = true))),
                        Expanded(child: _buildFilterSegment('All Time', !_isWeekly, theme, () => setState(() => _isWeekly = false))),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Total count badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: theme.dividerColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.users, size: 12, color: AppTheme.accentCoral),
                      const SizedBox(width: 6),
                      Text('$totalUsers Students', style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Search bar
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.dividerColor.withValues(alpha: 0.2)),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _searchQuery = value),
                style: GoogleFonts.inter(fontSize: 9),
                decoration: InputDecoration(
                  hintText: 'Search students by name...',
                  hintStyle: GoogleFonts.inter(fontSize: 9, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.4)),
                  prefixIcon: Icon(LucideIcons.search, size: 12, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.4)),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(LucideIcons.x, size: 12, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5)),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Hero Card
            if (topUser != null && _searchQuery.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: theme.dividerColor.withValues(alpha: 0.2)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Row(
                  children: [
                    const RivePlaceholder(width: 50, height: 50, label: 'Trophy', icon: LucideIcons.trophy),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AvatarWidget(
                                name: topUser.name ?? topUser.username,
                                avatarUrl: topUser.profilePicture,
                                radius: 12,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _isWeekly ? 'Weekly Top Performer' : 'All-Time Top Performer',
                                      style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.bold, color: AppTheme.accentCoral),
                                    ),
                                    Text(
                                      topUser.name ?? topUser.username,
                                      style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    _isWeekly ? topUser.weeklyScore.toString() : topUser.totalSolved.toString(),
                                    style: GoogleFonts.sora(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.accentCoral),
                                  ),
                                  Text(
                                    _isWeekly ? 'Weekly Score' : 'Total Solved',
                                    style: GoogleFonts.inter(fontSize: 8, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          RichText(
                            text: TextSpan(
                              style: GoogleFonts.inter(fontSize: 9, color: theme.colorScheme.onSurface),
                              children: [
                                const TextSpan(text: 'Solved '),
                                TextSpan(text: '${_isWeekly ? topUser.weeklyScore : topUser.totalSolved} ', style: const TextStyle(color: AppTheme.accentCoral, fontWeight: FontWeight.bold)),
                                TextSpan(text: 'problems ${_isWeekly ? 'this week' : 'in total'}\n'),
                              ],
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Consistency. Focus. Execution.',
                            style: GoogleFonts.inter(fontSize: 8, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),
            
            // Legend
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  _buildLegendItem('Easy', const Color(0xFFFFB74D), theme),
                  const SizedBox(width: 16),
                  _buildLegendItem('Medium', const Color(0xFFFF7043), theme),
                  const SizedBox(width: 16),
                  _buildLegendItem('Hard', const Color(0xFF81C784), theme),
                  const Spacer(),
                  Text('Problems Solved', style: GoogleFonts.inter(fontSize: 9, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5))),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Showing count
            if (_searchQuery.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  '${sortedUsers.length} result${sortedUsers.length != 1 ? 's' : ''} found',
                  style: GoogleFonts.inter(fontSize: 9, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5)),
                ),
              ),
            
            // List
            if (provider.isLoading && sortedUsers.isEmpty)
               const Center(child: CircularProgressIndicator(color: AppTheme.accentCoral))
            else if (sortedUsers.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    children: [
                      Icon(LucideIcons.searchX, size: 16, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.3)),
                      const SizedBox(height: 16),
                      Text('No students found', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5))),
                      const SizedBox(height: 4),
                      Text('Try a different search term', style: GoogleFonts.inter(fontSize: 11, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.4))),
                    ],
                  ),
                ),
              )
            else
                 Container(
                   decoration: BoxDecoration(
                     color: theme.colorScheme.surface,
                     borderRadius: BorderRadius.circular(16),
                     border: Border.all(color: theme.dividerColor.withValues(alpha: 0.2)),
                     boxShadow: [
                       BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
                     ],
                   ),
                   child: Column(
                     children: [
                       // Showing X of Y header
                       Padding(
                         padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                         child: Row(
                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
                           children: [
                             Text(
                               'Showing $displayedCount of ${sortedUsers.length}',
                               style: GoogleFonts.inter(fontSize: 9, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5)),
                             ),
                             if (_searchQuery.isEmpty)
                               Text(
                                 _isWeekly ? 'Sorted by weekly score' : 'Sorted by total solved',
                                 style: GoogleFonts.inter(fontSize: 9, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.4)),
                               ),
                           ],
                         ),
                       ),
                       _buildDivider(theme),
                       ListView.separated(
                         shrinkWrap: true,
                         physics: const NeverScrollableScrollPhysics(),
                         itemCount: displayedCount,
                         separatorBuilder: (context, index) => _buildDivider(theme),
                         itemBuilder: (context, index) {
                           final stat = sortedUsers[index];
                           return _buildListItem(
                             index + 1,
                             0, // diff placeholder
                             true,
                             stat.name ?? stat.username,
                             stat.easySolved,
                             stat.mediumSolved,
                             stat.hardSolved,
                             _isWeekly ? stat.weeklyScore : stat.totalSolved,
                             theme,
                             isTop3: index < 3,
                             avatarUrl: stat.profilePicture,
                           );
                         },
                       ),
                       if (_displayLimit < sortedUsers.length)
                         Padding(
                           padding: const EdgeInsets.all(16.0),
                           child: SizedBox(
                             width: double.infinity,
                             child: OutlinedButton.icon(
                               onPressed: () => setState(() => _displayLimit += 20),
                               icon: const Icon(LucideIcons.chevronDown, size: 12),
                               label: Text(
                                 'Load More (${sortedUsers.length - _displayLimit} remaining)',
                                 style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                               ),
                               style: OutlinedButton.styleFrom(
                                 foregroundColor: AppTheme.accentCoral,
                                 side: BorderSide(color: AppTheme.accentCoral.withValues(alpha: 0.3)),
                                 padding: const EdgeInsets.symmetric(vertical: 14),
                                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                               ),
                             ),
                           ),
                         ),
                     ],
                   ),
                 ),
            const SizedBox(height: 24),
            
            // Info Box
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
                      color: theme.colorScheme.surface,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.accentCoral.withValues(alpha: 0.2)),
                    ),
                    child: const Icon(LucideIcons.target, color: AppTheme.accentCoral, size: 16),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Solve problems. Build logic. Earn your spot.',
                          style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                        ),
                        Text(
                          'Rankings update every Monday at 8:00 AM.',
                          style: GoogleFonts.inter(fontSize: 9, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Footer — dynamic last updated
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.refreshCcw, size: 12, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5)),
                const SizedBox(width: 6),
                Text(
                  _getLastUpdatedText(provider),
                  style: GoogleFonts.inter(fontSize: 9, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getLastUpdatedText(LeetCodeProvider provider) {
    if (provider.allUsers.isEmpty) return 'No data';
    // Find the most recent last_updated from all users
    DateTime? latest;
    for (final user in provider.allUsers) {
      if (latest == null || user.lastUpdated.isAfter(latest)) {
        latest = user.lastUpdated;
      }
    }
    if (latest == null) return 'No data';
    final diff = DateTime.now().difference(latest);
    if (diff.inMinutes < 1) return 'Last updated: just now';
    if (diff.inMinutes < 60) return 'Last updated: ${diff.inMinutes}m ago';
    if (diff.inHours < 24) return 'Last updated: ${diff.inHours}h ago';
    return 'Last updated: ${diff.inDays}d ago';
  }

  Widget _buildFilterSegment(String label, bool isActive, ThemeData theme, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.accentCoral : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 9,
              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              color: isActive ? Colors.white : theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, ThemeData theme) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: GoogleFonts.inter(fontSize: 9, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7))),
      ],
    );
  }

  Widget _buildDivider(ThemeData theme) {
    return Divider(height: 1, indent: 64, endIndent: 16, color: theme.dividerColor.withValues(alpha: 0.1));
  }

  Widget _buildListItem(
    int rank, 
    int diff, 
    bool isUp, 
    String name, 
    int easy, 
    int medium, 
    int hard, 
    int displayScore,
    ThemeData theme, 
    {bool isHighlighted = false, bool isTop3 = false, String? avatarUrl}
  ) {
    final int total = easy + medium + hard;
    
    // Calculate proportions for the stacked bar
    final int totalProblemsInRow = total > 0 ? total : 1;
    final int easyFlex = (easy * 100) ~/ totalProblemsInRow;
    final int medFlex = (medium * 100) ~/ totalProblemsInRow;
    final int hardFlex = (hard * 100) ~/ totalProblemsInRow;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Rank & Trend
          SizedBox(
            width: 40,
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    if (isTop3)
                      Container(
                        width: 4,
                        height: 24,
                        decoration: BoxDecoration(
                          color: AppTheme.illusGold,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    Padding(
                      padding: EdgeInsets.only(left: isTop3 ? 8.0 : 0.0),
                      child: Text(
                        rank.toString(),
                        style: GoogleFonts.sora(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
                if (diff > 0) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isUp ? LucideIcons.arrowUp : LucideIcons.arrowDown,
                        size: 8,
                        color: isUp ? Colors.green : Colors.red,
                      ),
                      Text(
                        diff.toString(),
                        style: GoogleFonts.inter(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: isUp ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  const SizedBox(height: 4),
                  Text('-', style: GoogleFonts.inter(fontSize: 8, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5))),
                ],
              ],
            ),
          ),
          
          // Avatar — using AvatarWidget for DiceBear fallback
          AvatarWidget(
            name: name,
            avatarUrl: avatarUrl,
            radius: 14,
          ),
          const SizedBox(width: 10),
          
          // Name & Stacked Bar
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: isHighlighted ? AppTheme.accentCoral : theme.colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          displayScore.toString(),
                          style: GoogleFonts.sora(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.accentCoral,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(LucideIcons.chevronRight, size: 12, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.3)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Stacked Bar
                Container(
                  height: 12,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      if (easy > 0)
                        Expanded(
                          flex: easyFlex,
                          child: Container(
                            color: const Color(0xFFFFB74D), // Easy Orange
                            child: Center(
                              child: Text(
                                easy.toString(),
                                style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                      if (medium > 0)
                        Expanded(
                          flex: medFlex,
                          child: Container(
                            color: const Color(0xFFFF7043), // Medium Dark Orange
                            child: Center(
                              child: Text(
                                medium.toString(),
                                style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                      if (hard > 0)
                        Expanded(
                          flex: hardFlex,
                          child: Container(
                            color: const Color(0xFF81C784), // Hard Green
                            child: Center(
                              child: Text(
                                hard.toString(),
                                style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                    ],
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

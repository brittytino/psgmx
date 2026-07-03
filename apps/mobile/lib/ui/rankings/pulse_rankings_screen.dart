import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/avatar_widget.dart';
import '../widgets/rive_placeholder.dart';
import '../widgets/shared_bottom_navigation_bar.dart';
import '../../providers/user_provider.dart';
import '../../services/readiness_score_service.dart';
import '../../models/readiness_score.dart';

class PulseRankingsScreen extends StatefulWidget {
  const PulseRankingsScreen({super.key});

  @override
  State<PulseRankingsScreen> createState() => _PulseRankingsScreenState();
}

class _PulseRankingsScreenState extends State<PulseRankingsScreen> {
  List<ReadinessScore> _scores = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final userProvider = context.read<UserProvider>();
    final user = userProvider.currentUser;
    if (user == null || user.batchId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final service = ReadinessScoreService(Supabase.instance.client);
      final fetched = await service.fetchBatchLatestScores(user.batchId!);
      setState(() {
        _scores = fetched;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('[PulseRankingsScreen] fetch error: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userProvider = context.watch<UserProvider>();
    final myUid = userProvider.currentUser?.uid;

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
                  'Readiness Rankings',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(LucideIcons.sparkles, color: AppTheme.illusGold, size: 12),
              ],
            ),
            Row(
              children: [
                Text(
                  'Learn. Improve. Inspire.',
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(LucideIcons.heart, size: 12, color: AppTheme.accentCoral),
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.accentCoral))
          : _scores.isEmpty
              ? Center(child: Text('No data available', style: GoogleFonts.inter(fontSize: 11)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 16.0, bottom: 48.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Filters
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Container(
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surface,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: theme.dividerColor.withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                children: [
                                  Expanded(child: _buildFilterSegment('Institute', false, theme)),
                                  Expanded(child: _buildFilterSegment('Batch', true, theme)),
                                  Expanded(child: _buildFilterSegment('Branch', false, theme)),
                                  Expanded(child: _buildFilterSegment('Year', false, theme)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: theme.dividerColor.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              children: [
                                Text('Current Batch', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w600)),
                                const SizedBox(width: 4),
                                Icon(LucideIcons.chevronDown, size: 12, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      // Top 20% Banner
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF8F5), // Very light coral
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.accentCoral.withValues(alpha: 0.1)),
                        ),
                        child: Row(
                          children: [
                            const RivePlaceholder(width: 40, height: 40, label: 'High Five', icon: LucideIcons.users),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Consistency is key!',
                                    style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Keep pushing to improve your score daily.',
                                    style: GoogleFonts.inter(fontSize: 9, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7)),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(LucideIcons.sparkles, color: AppTheme.illusGold, size: 12),
                          ],
                        ),
                      ),
                      const SizedBox(height: 48), // Extra space for podium
                      
                      // Podium
                      if (_scores.length >= 3)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildPodiumItem(2, _scores[1], 110, theme),
                            const SizedBox(width: 16),
                            _buildPodiumItem(1, _scores[0], 140, theme),
                            const SizedBox(width: 16),
                            _buildPodiumItem(3, _scores[2], 90, theme),
                          ],
                        ),
                      const SizedBox(height: 32),
                      
                      // List Header
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          children: [
                            SizedBox(width: 40, child: Text('Rank', style: GoogleFonts.inter(fontSize: 9, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5)))),
                            Expanded(child: Text('Student', style: GoogleFonts.inter(fontSize: 9, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5)))),
                            Row(
                              children: [
                                Text('Readiness Score', style: GoogleFonts.inter(fontSize: 9, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5))),
                                const SizedBox(width: 4),
                                Icon(LucideIcons.info, size: 10, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // List
                      if (_scores.length > 3)
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
                              for (int i = 3; i < _scores.length; i++) ...[
                                if (i > 3) _buildDivider(theme),
                                _buildListItem(
                                  i + 1,
                                  _scores[i],
                                  theme,
                                  isHighlighted: _scores[i].userId == myUid,
                                ),
                              ],
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
                              child: const Icon(LucideIcons.users, color: AppTheme.accentCoral, size: 12),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Rankings update every 24 hours based on learning activity, quizzes, consistency & performance.',
                                style: GoogleFonts.inter(fontSize: 9, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Footer
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.refreshCcw, size: 10, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5)),
                          const SizedBox(width: 6),
                          Text(
                            'Updated just now',
                            style: GoogleFonts.inter(fontSize: 9, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildFilterSegment(String label, bool isActive, ThemeData theme) {
    return Container(
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
    );
  }

  Widget _buildPodiumItem(int rank, ReadinessScore scoreItem, double cardHeight, ThemeData theme) {
    final bool isFirst = rank == 1;
    final double avatarRadius = isFirst ? 24.0 : 18.0;
    final name = scoreItem.userName ?? 'Student';
    final scoreStr = scoreItem.score.toStringAsFixed(1);
    final avatarUrl = scoreItem.avatarUrl;
    
    return Expanded(
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Container(
            height: cardHeight,
            padding: EdgeInsets.only(top: avatarRadius + 16, bottom: 16, left: 8, right: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.dividerColor.withValues(alpha: 0.2)),
              boxShadow: [
                BoxShadow(
                  color: isFirst ? AppTheme.accentCoral.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.02),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  name,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: isFirst ? 11 : 9,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Batch',
                  style: GoogleFonts.inter(fontSize: 8, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5)),
                ),
                const SizedBox(height: 8),
                Text(
                  scoreStr,
                  style: GoogleFonts.sora(
                    fontSize: isFirst ? 14 : 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.accentCoral,
                  ),
                ),
              ],
            ),
          ),
          
          // Avatar
          Positioned(
            top: -avatarRadius,
            child: AvatarWidget(
              name: name,
              avatarUrl: avatarUrl,
              gender: scoreItem.gender,
              radius: avatarRadius,
            ),
          ),
          
          // Rank Flag
          Positioned(
            top: -avatarRadius - 40,
            child: Row(
              children: [
                const Icon(LucideIcons.flag, size: 12, color: AppTheme.illusTerracotta),
                const SizedBox(width: 4),
                Text(
                  rank.toString(),
                  style: GoogleFonts.sora(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(ThemeData theme) {
    return Divider(height: 1, indent: 64, endIndent: 16, color: theme.dividerColor.withValues(alpha: 0.1));
  }

  Widget _buildListItem(int rank, ReadinessScore scoreItem, ThemeData theme, {bool isHighlighted = false}) {
    final name = scoreItem.userName ?? 'Student';
    final scoreStr = scoreItem.score.toStringAsFixed(1);
    final avatarUrl = scoreItem.avatarUrl;

    return Container(
      decoration: isHighlighted 
          ? BoxDecoration(
              color: const Color(0xFFFFF8F5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.accentCoral),
            )
          : null,
      margin: isHighlighted ? const EdgeInsets.symmetric(vertical: 4, horizontal: 8) : EdgeInsets.zero,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        children: [
          // Rank & Trend
          SizedBox(
            width: 40,
            child: Column(
              children: [
                Text(
                  rank.toString(),
                  style: GoogleFonts.sora(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text('-', style: GoogleFonts.inter(fontSize: 8, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5))),
              ],
            ),
          ),
          
          // Avatar
          AvatarWidget(
            name: name,
            avatarUrl: avatarUrl,
            gender: scoreItem.gender,
            radius: 14,
          ),
          const SizedBox(width: 10),
          
          // Name & Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isHighlighted ? 'You ($name)' : name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: isHighlighted ? AppTheme.accentCoral : theme.colorScheme.onSurface,
                  ),
                ),
                Text(
                  'Batch',
                  style: GoogleFonts.inter(fontSize: 8, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5)),
                ),
              ],
            ),
          ),
          
          // Score
          Text(
            scoreStr,
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
    );
  }
}

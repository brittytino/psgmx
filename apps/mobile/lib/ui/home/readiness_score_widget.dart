import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/readiness_score.dart';
import '../../providers/user_provider.dart';
import '../../services/readiness_score_service.dart';
import '../../core/theme/app_dimens.dart';
import '../widgets/premium_card.dart';

class ReadinessScoreWidget extends StatefulWidget {
  const ReadinessScoreWidget({super.key});

  @override
  State<ReadinessScoreWidget> createState() => _ReadinessScoreWidgetState();
}

class _ReadinessScoreWidgetState extends State<ReadinessScoreWidget> {
  late final ReadinessScoreService _service;
  List<ReadinessScore>? _history;
  ReadinessScore? _latest;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _service = ReadinessScoreService(Supabase.instance.client);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final user = context.read<UserProvider>().currentUser!;
      final history = await _service.fetchScoreHistory(user.uid, limit: 14);
      
      if (mounted) {
        setState(() {
          _history = history;
          _latest = history.isNotEmpty ? history.last : null;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading readiness score: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _forceCompute() async {
    setState(() => _isLoading = true);
    try {
      final user = context.read<UserProvider>().currentUser!;
      await _service.computeAndStore(user.uid);
      await _loadData();
    } catch (e) {
      debugPrint('Error computing score: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Computation failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (_isLoading) {
      return const PremiumCard(
        child: SizedBox(
          height: 200, 
          child: Center(child: CircularProgressIndicator())
        ),
      );
    }
    
    if (_latest == null) {
      return PremiumCard(
        child: Column(
          children: [
            const Icon(Icons.analytics_outlined, size: 16, color: Colors.grey),
            const SizedBox(height: AppSpacing.md),
            const Text('No Readiness Score computed yet.'),
            const SizedBox(height: AppSpacing.md),
            FilledButton.icon(
              onPressed: _forceCompute,
              icon: const Icon(Icons.calculate),
              label: const Text('Compute Now'),
            ),
          ],
        ),
      );
    }

    return PremiumCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Readiness Score', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.refresh, size: 16),
                onPressed: _forceCompute,
                tooltip: 'Recompute',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          
          Row(
            children: [
              // Circular Gauge / Score Display
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 100,
                    height: 100,
                    child: CircularProgressIndicator(
                      value: _latest!.score / 100,
                      strokeWidth: 10,
                      backgroundColor: theme.colorScheme.surfaceContainerHighest,
                      color: _getScoreColor(_latest!.score),
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _latest!.score.toStringAsFixed(1),
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Grade ${_latest!.grade}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: _getScoreColor(_latest!.score),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(width: AppSpacing.xl),
              
              // Component breakdown simple
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCompRow('Attendance', _latest!.components.placementAttendancePct, 0.30, theme),
                    _buildCompRow('Quiz Adherence', _latest!.components.dailyFiveAdherencePct, 0.20, theme),
                    _buildCompRow('Tasks Done', _latest!.components.taskCompletionRatePct, 0.20, theme),
                    _buildCompRow('Quiz Accuracy', _latest!.components.dailyFiveAccuracyPct, 0.15, theme),
                    _buildCompRow('LeetCode Pct', _latest!.components.leetcodeMomentumPercentile, 0.15, theme),
                  ],
                ),
              ),
            ],
          ),
          
          if (_history != null && _history!.length > 1) ...[
            const SizedBox(height: AppSpacing.xl),
            Text('14-Day Trend', style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 100,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  minY: 0,
                  maxY: 100,
                  lineBarsData: [
                    LineChartBarData(
                      spots: _history!.asMap().entries.map((e) {
                        return FlSpot(e.key.toDouble(), e.value.score);
                      }).toList(),
                      isCurved: true,
                      color: theme.colorScheme.primary,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildCompRow(String label, double value, double weight, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style: theme.textTheme.bodySmall, overflow: TextOverflow.ellipsis)),
          Text(value.toStringAsFixed(0), style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }
}

// screens/home/steps_trend_screen.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../models/challenge_model.dart';
import '../../providers/health_provider.dart';
import '../../utils/theme.dart';

class StepsTrendScreen extends StatefulWidget {
  const StepsTrendScreen({super.key});

  @override
  State<StepsTrendScreen> createState() => _StepsTrendScreenState();
}

class _StepsTrendScreenState extends State<StepsTrendScreen> {
  List<DailySteps> _steps = [];
  bool _isLoading = true;
  String? _error;
  int _selectedDays = 30;
  int? _touchedIndex;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final health = context.read<HealthProvider>();
      final steps = await health.getDailySteps(_selectedDays);

      if (mounted) {
        setState(() {
          _steps = steps;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load steps data';
          _isLoading = false;
        });
      }
    }
  }

  int get _totalSteps => _steps.fold(0, (sum, d) => sum + d.steps);
  int get _averageSteps => _steps.isNotEmpty ? _totalSteps ~/ _steps.length : 0;
  int get _bestDay => _steps.isNotEmpty
      ? _steps.map((d) => d.steps).reduce((a, b) => a > b ? a : b)
      : 0;
  int get _worstDay => _steps.isNotEmpty
      ? _steps.map((d) => d.steps).reduce((a, b) => a < b ? a : b)
      : 0;
  int get _daysAboveGoal => _steps.where((d) => d.steps >= 10000).length;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? RivlColors.darkBackground : RivlColors.lightBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Steps Trend'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _loadData,
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                )
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  _buildCurrentCard(context),
                  const SizedBox(height: 20),
                  _buildPeriodSelector(context),
                  const SizedBox(height: 16),
                  _buildBarChart(context),
                  const SizedBox(height: 20),
                  _buildStatsRow(context),
                  const SizedBox(height: 20),
                  _buildInsightCard(context),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildCurrentCard(BuildContext context) {
    final health = context.watch<HealthProvider>();
    final todaySteps = health.todaySteps;
    final goalProgress = health.goalProgress;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            RivlColors.primary.withOpacity(0.9),
            RivlColors.primary.withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: RivlColors.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.directions_walk, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Text(
                'Today\'s Steps',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                health.formatSteps(todaySteps),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 6),
                child: Text(
                  '/ ${health.formatSteps(health.dailyGoal)}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: goalProgress,
              backgroundColor: Colors.white.withOpacity(0.2),
              valueColor: const AlwaysStoppedAnimation(Colors.white),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${(goalProgress * 100).toInt()}% of daily goal',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector(BuildContext context) {
    return Row(
      children: [7, 14, 30].map((days) {
        final isSelected = _selectedDays == days;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ChoiceChip(
            label: Text('${days}D'),
            selected: isSelected,
            onSelected: (_) {
              setState(() => _selectedDays = days);
              _loadData();
            },
            selectedColor: RivlColors.primary.withOpacity(0.15),
            labelStyle: TextStyle(
              color: isSelected ? RivlColors.primary : context.textSecondary,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              fontSize: 13,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: isSelected
                    ? RivlColors.primary.withOpacity(0.4)
                    : Colors.grey.withOpacity(0.2),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBarChart(BuildContext context) {
    if (_steps.isEmpty) return const SizedBox.shrink();

    final maxSteps = _steps.map((d) => d.steps).reduce(max).toDouble();
    final goalLine = 10000.0;

    return Container(
      height: 250,
      padding: const EdgeInsets.fromLTRB(8, 20, 16, 8),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: BarChart(
        BarChartData(
          maxY: max(maxSteps * 1.15, goalLine * 1.15),
          alignment: BarChartAlignment.spaceAround,
          barTouchData: BarTouchData(
            enabled: true,
            touchCallback: (event, response) {
              if (event.isInterestedForInteractions &&
                  response != null &&
                  response.spot != null) {
                setState(() => _touchedIndex = response.spot!.touchedBarGroupIndex);
              } else {
                setState(() => _touchedIndex = null);
              }
            },
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => context.surface,
              tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final day = _steps[group.x.toInt()];
                final date = DateTime.parse(day.date);
                return BarTooltipItem(
                  '${_formatNumber(day.steps)}\n',
                  TextStyle(
                    color: RivlColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                  children: [
                    TextSpan(
                      text: '${_monthName(date.month)} ${date.day}',
                      style: TextStyle(
                        color: context.textSecondary,
                        fontWeight: FontWeight.w400,
                        fontSize: 11,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxSteps > 0 ? max(maxSteps / 4, 1) : 2500,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.grey.withOpacity(0.1),
              strokeWidth: 1,
            ),
          ),
          extraLinesData: ExtraLinesData(
            horizontalLines: [
              HorizontalLine(
                y: goalLine,
                color: RivlColors.success.withOpacity(0.5),
                strokeWidth: 1.5,
                dashArray: [6, 4],
                label: HorizontalLineLabel(
                  show: true,
                  alignment: Alignment.topRight,
                  style: TextStyle(
                    color: RivlColors.success,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                  labelResolver: (_) => '10K Goal',
                ),
              ),
            ],
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 42,
                getTitlesWidget: (value, meta) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Text(
                      _formatAxisSteps(value),
                      style: TextStyle(
                        fontSize: 10,
                        color: context.textSecondary,
                      ),
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: _selectedDays <= 7 ? 1 : (_selectedDays <= 14 ? 2 : 5),
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= _steps.length) {
                    return const SizedBox.shrink();
                  }
                  final date = DateTime.parse(_steps[idx].date);
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '${date.month}/${date.day}',
                      style: TextStyle(
                        fontSize: 10,
                        color: context.textSecondary,
                      ),
                    ),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(_steps.length, (i) {
            final isTouched = _touchedIndex == i;
            final isAboveGoal = _steps[i].steps >= 10000;
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: _steps[i].steps.toDouble(),
                  color: isTouched
                      ? RivlColors.primary
                      : isAboveGoal
                          ? RivlColors.primary.withOpacity(0.8)
                          : RivlColors.primary.withOpacity(0.35),
                  width: _selectedDays <= 7 ? 28 : (_selectedDays <= 14 ? 14 : 6),
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            );
          }),
        ),
        duration: const Duration(milliseconds: 300),
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context) {
    final health = context.watch<HealthProvider>();
    return Row(
      children: [
        _StatCard(
          label: 'Average',
          value: health.formatSteps(_averageSteps),
          icon: Icons.analytics_outlined,
          color: RivlColors.primary,
        ),
        const SizedBox(width: 10),
        _StatCard(
          label: 'Best Day',
          value: health.formatSteps(_bestDay),
          icon: Icons.arrow_upward_rounded,
          color: RivlColors.success,
        ),
        const SizedBox(width: 10),
        _StatCard(
          label: 'Goal Days',
          value: '$_daysAboveGoal',
          icon: Icons.emoji_events_outlined,
          color: Colors.orange,
        ),
      ],
    );
  }

  Widget _buildInsightCard(BuildContext context) {
    if (_steps.length < 7) return const SizedBox.shrink();

    final recentWeek = _steps.sublist(_steps.length - 7);
    final recentAvg = recentWeek.fold(0, (sum, d) => sum + d.steps) / 7;
    final olderDays = _steps.sublist(0, min(7, _steps.length - 7));
    final olderAvg = olderDays.isNotEmpty
        ? olderDays.fold(0, (sum, d) => sum + d.steps) / olderDays.length
        : recentAvg;

    final change = olderAvg > 0 ? ((recentAvg - olderAvg) / olderAvg * 100) : 0.0;
    final isImproving = change > 0;

    String insight;
    if (change.abs() < 3) {
      insight = 'Your step count has been consistent over the past $_selectedDays days. '
          'You\'re averaging ${_formatNumber(_averageSteps)} steps per day.';
    } else if (isImproving) {
      insight = 'Great progress! Your recent average is up ${change.abs().toStringAsFixed(1)}% '
          'compared to earlier in the period. Keep it up!';
    } else {
      insight = 'Your recent steps are down ${change.abs().toStringAsFixed(1)}% '
          'compared to earlier. Try to get more walks in to boost your count.';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isImproving ? Icons.trending_up : Icons.trending_down,
                color: isImproving ? RivlColors.success : RivlColors.warning,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Insight',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            insight,
            style: TextStyle(
              color: context.textSecondary,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  String _formatNumber(int value) {
    if (value >= 1000) {
      final k = value / 1000;
      return k == k.roundToDouble()
          ? '${k.toInt()}K'
          : '${k.toStringAsFixed(1)}K';
    }
    return '$value';
  }

  String _formatAxisSteps(double value) {
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(0)}K';
    return value.toInt().toString();
  }

  String _monthName(int month) {
    const names = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return names[(month - 1).clamp(0, 11)];
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: context.textSecondary,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

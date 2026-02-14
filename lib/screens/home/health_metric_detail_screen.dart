// screens/home/health_metric_detail_screen.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../providers/health_provider.dart';
import '../../utils/theme.dart';

/// A data point representing one day's value for any health metric.
class MetricDataPoint {
  final DateTime date;
  final double value;
  const MetricDataPoint({required this.date, required this.value});
}

/// Enum to identify which metric is being displayed.
enum HealthMetricType {
  heartRate,
  sleep,
  hrv,
  restingHeartRate,
  bloodOxygen,
  vo2Max,
  recovery,
  exertion,
}

class HealthMetricDetailScreen extends StatefulWidget {
  final HealthMetricType metricType;
  final IconData icon;
  final String label;
  final String currentValue;
  final String unit;
  final Color color;
  final String description;

  const HealthMetricDetailScreen({
    super.key,
    required this.metricType,
    required this.icon,
    required this.label,
    required this.currentValue,
    required this.unit,
    required this.color,
    required this.description,
  });

  @override
  State<HealthMetricDetailScreen> createState() =>
      _HealthMetricDetailScreenState();
}

class _HealthMetricDetailScreenState extends State<HealthMetricDetailScreen> {
  List<MetricDataPoint> _data = [];
  bool _isLoading = true;
  int _selectedDays = 30;
  int? _touchedIndex;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    // Generate realistic demo trend data for 30 days
    final now = DateTime.now();
    final rng = Random(widget.metricType.index * 1000 + now.day);
    final points = <MetricDataPoint>[];

    for (var i = _selectedDays - 1; i >= 0; i--) {
      final date = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: i));
      final value = _generateDemoValue(rng, i);
      points.add(MetricDataPoint(date: date, value: value));
    }

    setState(() {
      _data = points;
      _isLoading = false;
    });
  }

  double _generateDemoValue(Random rng, int daysAgo) {
    // Create a slight upward trend with natural daily variation
    final trendFactor = 1.0 + ((_selectedDays - daysAgo) / _selectedDays) * 0.08;
    final noise = (rng.nextDouble() - 0.5) * 2;

    switch (widget.metricType) {
      case HealthMetricType.heartRate:
        return (68 + rng.nextInt(15) + noise * 5).clamp(55, 110);
      case HealthMetricType.sleep:
        return (6.5 + rng.nextDouble() * 2.5 + noise * 0.3).clamp(4.0, 10.0);
      case HealthMetricType.hrv:
        return ((42 + rng.nextInt(25)) * trendFactor + noise * 3)
            .clamp(20, 100);
      case HealthMetricType.restingHeartRate:
        final base = 65 - ((_selectedDays - daysAgo) * 0.1);
        return (base + rng.nextInt(6) + noise * 2).clamp(45, 85);
      case HealthMetricType.bloodOxygen:
        return (96.0 + rng.nextDouble() * 3 + noise * 0.3).clamp(93, 100);
      case HealthMetricType.vo2Max:
        return ((38 + rng.nextInt(10)) * trendFactor + noise * 1.5)
            .clamp(25, 65);
      case HealthMetricType.recovery:
        return ((55 + rng.nextInt(35)) * trendFactor + noise * 5)
            .clamp(10, 100);
      case HealthMetricType.exertion:
        return (30 + rng.nextInt(50) + noise * 8).clamp(5, 100);
    }
  }

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
        title: Text(widget.label),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  _buildCurrentValueCard(context),
                  const SizedBox(height: 20),
                  _buildPeriodSelector(context),
                  const SizedBox(height: 16),
                  _buildChart(context),
                  const SizedBox(height: 20),
                  _buildStatsCards(context),
                  const SizedBox(height: 20),
                  _buildInsightCard(context),
                  const SizedBox(height: 20),
                  _buildAboutCard(context),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildCurrentValueCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            widget.color.withOpacity(0.9),
            widget.color.withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: widget.color.withOpacity(0.3),
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
                child: Icon(widget.icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Text(
                'Current ${widget.label}',
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
                widget.currentValue,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
              if (widget.unit.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 6, bottom: 6),
                  child: Text(
                    widget.unit,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _buildTrendBadge(),
        ],
      ),
    );
  }

  Widget _buildTrendBadge() {
    if (_data.length < 7) return const SizedBox.shrink();

    final recentAvg =
        _data.sublist(_data.length - 7).map((d) => d.value).reduce((a, b) => a + b) / 7;
    final olderAvg =
        _data.sublist(0, min(7, _data.length)).map((d) => d.value).reduce((a, b) => a + b) /
            min(7, _data.length);

    final change = ((recentAvg - olderAvg) / olderAvg * 100);
    final isImproving = _isImprovementPositive(change);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isImproving ? Icons.trending_up : Icons.trending_down,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            '${change.abs().toStringAsFixed(1)}% ${isImproving ? "improvement" : "change"} over ${_selectedDays}d',
            style: TextStyle(
              color: Colors.white.withOpacity(0.95),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  bool _isImprovementPositive(double changePercent) {
    switch (widget.metricType) {
      case HealthMetricType.restingHeartRate:
      case HealthMetricType.exertion:
        return changePercent < 0; // lower is better
      case HealthMetricType.heartRate:
        return changePercent.abs() < 5; // stable is good
      default:
        return changePercent > 0; // higher is generally better
    }
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
            selectedColor: widget.color.withOpacity(0.15),
            labelStyle: TextStyle(
              color: isSelected ? widget.color : context.textSecondary,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              fontSize: 13,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: isSelected
                    ? widget.color.withOpacity(0.4)
                    : Colors.grey.withOpacity(0.2),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildChart(BuildContext context) {
    if (_data.isEmpty) return const SizedBox.shrink();

    final values = _data.map((d) => d.value).toList();
    final minVal = values.reduce(min);
    final maxVal = values.reduce(max);
    final range = maxVal - minVal;
    final padding = range * 0.15;

    return Container(
      height: 220,
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
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: range > 0 ? range / 4 : 1,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.grey.withOpacity(0.1),
              strokeWidth: 1,
            ),
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
                      _formatAxisValue(value),
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
                  if (idx < 0 || idx >= _data.length) {
                    return const SizedBox.shrink();
                  }
                  final date = _data[idx].date;
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
            topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          minY: (minVal - padding).clamp(0, double.infinity),
          maxY: maxVal + padding,
          lineTouchData: LineTouchData(
            handleBuiltInTouches: true,
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => context.surface,
              tooltipPadding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8),
              getTooltipItems: (spots) {
                return spots.map((spot) {
                  final idx = spot.x.toInt();
                  final date = idx >= 0 && idx < _data.length
                      ? _data[idx].date
                      : DateTime.now();
                  return LineTooltipItem(
                    '${_formatTooltipValue(spot.y)}\n',
                    TextStyle(
                      color: widget.color,
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
                }).toList();
              },
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: List.generate(
                _data.length,
                (i) => FlSpot(i.toDouble(), _data[i].value),
              ),
              isCurved: true,
              curveSmoothness: 0.3,
              color: widget.color,
              barWidth: 2.5,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: _selectedDays <= 14,
                getDotPainter: (spot, percent, bar, idx) =>
                    FlDotCirclePainter(
                  radius: 3,
                  color: widget.color,
                  strokeWidth: 1.5,
                  strokeColor: Colors.white,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    widget.color.withOpacity(0.25),
                    widget.color.withOpacity(0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
        duration: const Duration(milliseconds: 300),
      ),
    );
  }

  Widget _buildStatsCards(BuildContext context) {
    if (_data.isEmpty) return const SizedBox.shrink();

    final values = _data.map((d) => d.value).toList();
    final avg = values.reduce((a, b) => a + b) / values.length;
    final high = values.reduce(max);
    final low = values.reduce(min);

    return Row(
      children: [
        _StatCard(
          label: 'Average',
          value: _formatStatValue(avg),
          icon: Icons.analytics_outlined,
          color: widget.color,
        ),
        const SizedBox(width: 10),
        _StatCard(
          label: 'High',
          value: _formatStatValue(high),
          icon: Icons.arrow_upward_rounded,
          color: RivlColors.success,
        ),
        const SizedBox(width: 10),
        _StatCard(
          label: 'Low',
          value: _formatStatValue(low),
          icon: Icons.arrow_downward_rounded,
          color: RivlColors.warning,
        ),
      ],
    );
  }

  Widget _buildInsightCard(BuildContext context) {
    if (_data.length < 7) return const SizedBox.shrink();

    final recentAvg =
        _data.sublist(_data.length - 7).map((d) => d.value).reduce((a, b) => a + b) / 7;
    final olderAvg =
        _data.sublist(0, min(7, _data.length)).map((d) => d.value).reduce((a, b) => a + b) /
            min(7, _data.length);
    final change = ((recentAvg - olderAvg) / olderAvg * 100);

    final insight = _getInsightText(change);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(18),
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
              Icon(Icons.lightbulb_outline, color: widget.color, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Insight',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            insight,
            style: TextStyle(
              fontSize: 14,
              color: context.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(18),
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
              Icon(Icons.info_outline, color: widget.color, size: 20),
              const SizedBox(width: 8),
              Text(
                'About ${widget.label}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            widget.description,
            style: TextStyle(
              fontSize: 14,
              color: context.textSecondary,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 16),
          _buildNormalRangeRow(context),
        ],
      ),
    );
  }

  Widget _buildNormalRangeRow(BuildContext context) {
    final range = _getNormalRange();
    if (range == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: widget.color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline,
              color: widget.color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Normal range: $range',
              style: TextStyle(
                fontSize: 13,
                color: widget.color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // HELPERS
  // ============================================

  String _formatAxisValue(double value) {
    switch (widget.metricType) {
      case HealthMetricType.sleep:
        return '${value.toStringAsFixed(0)}h';
      case HealthMetricType.bloodOxygen:
        return '${value.toStringAsFixed(0)}%';
      case HealthMetricType.recovery:
      case HealthMetricType.exertion:
        return value.toStringAsFixed(0);
      default:
        return value.toStringAsFixed(0);
    }
  }

  String _formatTooltipValue(double value) {
    switch (widget.metricType) {
      case HealthMetricType.sleep:
        final h = value.floor();
        final m = ((value - h) * 60).round();
        return m > 0 ? '${h}h ${m}m' : '${h}h';
      case HealthMetricType.bloodOxygen:
        return '${value.toStringAsFixed(1)}%';
      case HealthMetricType.hrv:
      case HealthMetricType.vo2Max:
        return value.toStringAsFixed(1);
      case HealthMetricType.recovery:
      case HealthMetricType.exertion:
        return '${value.toStringAsFixed(0)}/100';
      default:
        return value.toStringAsFixed(0);
    }
  }

  String _formatStatValue(double value) {
    switch (widget.metricType) {
      case HealthMetricType.sleep:
        return '${value.toStringAsFixed(1)}h';
      case HealthMetricType.bloodOxygen:
        return '${value.toStringAsFixed(1)}%';
      case HealthMetricType.hrv:
        return '${value.toStringAsFixed(0)} ms';
      case HealthMetricType.vo2Max:
        return value.toStringAsFixed(1);
      case HealthMetricType.heartRate:
      case HealthMetricType.restingHeartRate:
        return '${value.toStringAsFixed(0)} bpm';
      case HealthMetricType.recovery:
      case HealthMetricType.exertion:
        return value.toStringAsFixed(0);
    }
  }

  String? _getNormalRange() {
    switch (widget.metricType) {
      case HealthMetricType.heartRate:
        return '60-100 bpm';
      case HealthMetricType.restingHeartRate:
        return '60-100 bpm (athletes: 40-60)';
      case HealthMetricType.hrv:
        return '20-100 ms (higher is better)';
      case HealthMetricType.sleep:
        return '7-9 hours per night';
      case HealthMetricType.bloodOxygen:
        return '95-100%';
      case HealthMetricType.vo2Max:
        return '30-60 ml/kg/min (varies by age)';
      case HealthMetricType.recovery:
        return '60-100 (higher is better)';
      case HealthMetricType.exertion:
        return '40-70 optimal training zone';
    }
  }

  String _getInsightText(double changePercent) {
    final direction = changePercent > 0 ? 'increased' : 'decreased';
    final pct = changePercent.abs().toStringAsFixed(1);

    switch (widget.metricType) {
      case HealthMetricType.heartRate:
        if (changePercent.abs() < 3) {
          return 'Your heart rate has been stable over the past $_selectedDays days. Consistent heart rate patterns suggest your cardiovascular system is in a steady state.';
        }
        return 'Your heart rate has $direction by $pct% over the past $_selectedDays days. Keep an eye on factors like stress, caffeine, and sleep quality that can influence heart rate trends.';

      case HealthMetricType.restingHeartRate:
        if (changePercent < -2) {
          return 'Your resting heart rate has decreased by $pct% -- a sign of improving cardiovascular fitness. Keep up the good work with consistent exercise.';
        } else if (changePercent > 3) {
          return 'Your resting heart rate has increased by $pct%. This could indicate stress, poor sleep, or overtraining. Consider taking a rest day.';
        }
        return 'Your resting heart rate has remained steady over the past $_selectedDays days, which is a good sign of consistent fitness levels.';

      case HealthMetricType.hrv:
        if (changePercent > 3) {
          return 'Your HRV has improved by $pct%, indicating better recovery and stress management. Your body is adapting well to your training load.';
        } else if (changePercent < -3) {
          return 'Your HRV has decreased by $pct%. This may indicate accumulated fatigue or stress. Consider prioritizing sleep and recovery.';
        }
        return 'Your HRV has been consistent over the past $_selectedDays days. Maintaining a stable HRV shows balanced training and recovery.';

      case HealthMetricType.sleep:
        final avgSleep = _data.map((d) => d.value).reduce((a, b) => a + b) / _data.length;
        if (avgSleep >= 7) {
          return 'You\'ve been averaging ${avgSleep.toStringAsFixed(1)} hours of sleep. That\'s within the recommended 7-9 hour range -- great for recovery and performance.';
        }
        return 'You\'ve been averaging ${avgSleep.toStringAsFixed(1)} hours of sleep, which is below the recommended 7-9 hours. Try going to bed 30 minutes earlier to improve recovery.';

      case HealthMetricType.bloodOxygen:
        return 'Your blood oxygen levels have remained in a healthy range over the past $_selectedDays days. Consistent SpO2 levels above 95% indicate good respiratory function.';

      case HealthMetricType.vo2Max:
        if (changePercent > 2) {
          return 'Your VO2 Max has improved by $pct% -- your aerobic capacity is increasing. This is one of the strongest indicators of overall fitness improvement.';
        } else if (changePercent < -2) {
          return 'Your VO2 Max has decreased by $pct%. Consider incorporating more zone 2 cardio (moderate intensity) to rebuild your aerobic base.';
        }
        return 'Your VO2 Max has been stable over the past $_selectedDays days. To improve, try adding interval training or longer steady-state cardio sessions.';

      case HealthMetricType.recovery:
        if (changePercent > 3) {
          return 'Your recovery score has improved by $pct% over the past $_selectedDays days. Your body is bouncing back well -- great sleep, low stress, and proper nutrition are paying off.';
        } else if (changePercent < -3) {
          return 'Your recovery has dropped by $pct%. Consider prioritizing sleep, hydration, and rest days to help your body restore its readiness.';
        }
        return 'Your recovery has been steady over the past $_selectedDays days. Maintaining consistent sleep and nutrition will keep your recovery high.';

      case HealthMetricType.exertion:
        if (changePercent > 5) {
          return 'Your exertion has increased by $pct% over the past $_selectedDays days. Make sure you\'re balancing high-effort days with adequate recovery to avoid overtraining.';
        } else if (changePercent < -5) {
          return 'Your exertion has decreased by $pct%. If intentional, this is a good deload period. Otherwise, consider ramping up your training to maintain fitness.';
        }
        return 'Your exertion has been consistent over the past $_selectedDays days. A moderate and steady training load supports long-term progress.';
    }
  }

  String _monthName(int month) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month];
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
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: context.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

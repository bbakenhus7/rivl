// screens/home/health_category_detail_screen.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../models/health_category.dart';
import '../../providers/health_provider.dart';
import '../../utils/theme.dart';
import '../../utils/animations.dart';
import 'health_metric_detail_screen.dart';
import 'workout_detail_screen.dart';

/// Display info for each metric type.
class _MetricInfo {
  final IconData icon;
  final String label;
  final String unit;
  final Color color;
  final String description;
  const _MetricInfo({
    required this.icon,
    required this.label,
    required this.unit,
    required this.color,
    required this.description,
  });
}

const _metricInfoMap = <HealthMetricType, _MetricInfo>{
  HealthMetricType.heartRate: _MetricInfo(
    icon: Icons.favorite,
    label: 'Heart Rate',
    unit: 'bpm',
    color: Colors.red,
    description:
        'Heart rate measures how many times your heart beats per minute. '
        'Tracking it during exercise shows how hard your cardiovascular system is working, '
        'and monitoring trends over time can reveal improvements in fitness.',
  ),
  HealthMetricType.restingHeartRate: _MetricInfo(
    icon: Icons.monitor_heart,
    label: 'Resting HR',
    unit: 'bpm',
    color: Colors.pink,
    description:
        'Resting heart rate is your heart rate when completely at rest. '
        'A lower resting heart rate typically means your heart is more efficient. '
        'Athletes often have resting rates between 40-60 bpm.',
  ),
  HealthMetricType.hrv: _MetricInfo(
    icon: Icons.show_chart,
    label: 'HRV',
    unit: 'ms',
    color: Colors.purple,
    description:
        'Heart Rate Variability measures the variation in time between heartbeats. '
        'Higher HRV generally indicates better cardiovascular fitness and recovery.',
  ),
  HealthMetricType.sleep: _MetricInfo(
    icon: Icons.bedtime,
    label: 'Sleep',
    unit: '',
    color: Colors.indigo,
    description:
        'Sleep is when your body recovers, builds muscle, and consolidates memory. '
        'Getting 7-9 hours of quality sleep each night improves athletic performance.',
  ),
  HealthMetricType.recovery: _MetricInfo(
    icon: Icons.battery_charging_full,
    label: 'Recovery',
    unit: '/100',
    color: Color(0xFF4CAF50),
    description:
        'Recovery measures how ready your body is to perform, calculated from '
        'HRV and Resting Heart Rate. Higher means you are more recovered.',
  ),
  HealthMetricType.bloodOxygen: _MetricInfo(
    icon: Icons.air,
    label: 'Blood Oxygen',
    unit: '%',
    color: Colors.teal,
    description:
        'Blood oxygen (SpO2) measures the percentage of oxygen your red blood cells carry. '
        'Normal levels are 95-100%. Tracked primarily during sleep.',
  ),
  HealthMetricType.exertion: _MetricInfo(
    icon: Icons.local_fire_department,
    label: 'Exertion',
    unit: '/100',
    color: Colors.deepOrange,
    description:
        'Exertion measures the total physical load on your body today, '
        'calculated from steps and calorie burn.',
  ),
  HealthMetricType.vo2Max: _MetricInfo(
    icon: Icons.speed,
    label: 'VO2 Max',
    unit: 'ml/kg/min',
    color: Colors.orange,
    description:
        'VO2 Max is the maximum amount of oxygen your body can use during intense exercise. '
        'It is the gold standard measure of aerobic fitness.',
  ),
  HealthMetricType.healthScore: _MetricInfo(
    icon: Icons.insights_rounded,
    label: 'RIVL Health Score',
    unit: '/100',
    color: Color(0xFF6C5CE7),
    description:
        'Your RIVL Health Score is a weighted average of six dimensions: '
        'steps, active calories, exercise minutes, sleep quality, resting heart rate, and HRV.',
  ),
};

class HealthCategoryDetailScreen extends StatefulWidget {
  final HealthCategory category;

  const HealthCategoryDetailScreen({super.key, required this.category});

  @override
  State<HealthCategoryDetailScreen> createState() =>
      _HealthCategoryDetailScreenState();
}

class _HealthCategoryDetailScreenState
    extends State<HealthCategoryDetailScreen> {
  late final HealthCategoryConfig _config;
  int _selectedDays = 7;
  bool _isLoading = true;
  Map<HealthMetricType, List<MetricDataPoint>> _metricData = {};

  @override
  void initState() {
    super.initState();
    _config = HealthCategoryConfig.of(widget.category);
    _loadData();
  }

  void _loadData() {
    setState(() => _isLoading = true);

    final now = DateTime.now();
    final data = <HealthMetricType, List<MetricDataPoint>>{};

    for (final metricType in _config.metrics) {
      final rng = Random(metricType.index * 1000 + now.day);
      final points = <MetricDataPoint>[];
      for (var i = _selectedDays - 1; i >= 0; i--) {
        final date =
            DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
        points.add(MetricDataPoint(
          date: date,
          value: _generateDemoValue(rng, i, metricType),
        ));
      }
      data[metricType] = points;
    }

    setState(() {
      _metricData = data;
      _isLoading = false;
    });
  }

  double _generateDemoValue(Random rng, int daysAgo, HealthMetricType type) {
    final trendFactor =
        1.0 + ((_selectedDays - daysAgo) / _selectedDays) * 0.08;
    final noise = (rng.nextDouble() - 0.5) * 2;

    switch (type) {
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
      case HealthMetricType.healthScore:
        return ((60 + rng.nextInt(30)) * trendFactor + noise * 4)
            .clamp(15, 100);
    }
  }

  String _getCurrentValue(HealthMetricType type, HealthProvider health) {
    switch (type) {
      case HealthMetricType.heartRate:
        return health.heartRate > 0 ? '${health.heartRate}' : '--';
      case HealthMetricType.restingHeartRate:
        return health.restingHeartRate > 0
            ? '${health.restingHeartRate}'
            : '--';
      case HealthMetricType.hrv:
        return health.hrv > 0 ? health.formatHRV(health.hrv) : '--';
      case HealthMetricType.sleep:
        return health.sleepHours > 0
            ? health.formatSleep(health.sleepHours)
            : '--';
      case HealthMetricType.recovery:
        return '${health.recoveryScore}';
      case HealthMetricType.bloodOxygen:
        return health.bloodOxygen > 0
            ? health.formatBloodOxygen(health.bloodOxygen)
            : '--';
      case HealthMetricType.exertion:
        return '${health.strainScore}';
      case HealthMetricType.vo2Max:
        return health.vo2Max > 0 ? health.formatVO2Max(health.vo2Max) : '--';
      case HealthMetricType.healthScore:
        return '${health.rivlHealthScore}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? RivlColors.darkBackground : RivlColors.lightBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(_config.name),
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
                  _buildCategoryHeader(context),
                  const SizedBox(height: 20),
                  _buildPeriodSelector(context),
                  const SizedBox(height: 20),

                  // Metric sections
                  ...List.generate(_config.metrics.length, (i) {
                    final metricType = _config.metrics[i];
                    return FadeIn(
                      delay: Duration(milliseconds: 100 * i),
                      child: _buildMetricSection(context, metricType),
                    );
                  }),

                  // Sleep-specific: stage breakdown
                  if (widget.category ==
                      HealthCategory.sleepRecovery) ...[
                    const SizedBox(height: 8),
                    FadeIn(
                      delay: Duration(
                          milliseconds: 100 * _config.metrics.length),
                      child: _buildSleepBreakdownCard(context),
                    ),
                  ],

                  // Activity-specific sections
                  if (widget.category ==
                      HealthCategory.activityPerformance) ...[
                    const SizedBox(height: 8),
                    FadeIn(
                      delay: Duration(
                          milliseconds: 100 * _config.metrics.length),
                      child: _buildWeeklyStepsSection(context),
                    ),
                    const SizedBox(height: 20),
                    FadeIn(
                      delay: Duration(
                          milliseconds: 100 * (_config.metrics.length + 1)),
                      child: _buildRecentWorkoutsSection(context),
                    ),
                  ],

                  // Overall-specific: health score breakdown + AI recommendations
                  if (widget.category == HealthCategory.overall) ...[
                    const SizedBox(height: 8),
                    FadeIn(
                      delay: Duration(
                          milliseconds: 100 * _config.metrics.length),
                      child: _buildHealthScoreBreakdownCard(context),
                    ),
                    const SizedBox(height: 20),
                    FadeIn(
                      delay: Duration(
                          milliseconds: 100 * (_config.metrics.length + 1)),
                      child: _buildAiRecommendationCard(context),
                    ),
                  ],

                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  // ============================================
  // CATEGORY HEADER
  // ============================================

  Widget _buildCategoryHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _config.accentColor.withOpacity(0.9),
            _config.accentColor.withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _config.accentColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(_config.icon, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _config.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_config.metrics.length} metric${_config.metrics.length == 1 ? '' : 's'} tracked',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // PERIOD SELECTOR
  // ============================================

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
            selectedColor: _config.accentColor.withOpacity(0.15),
            labelStyle: TextStyle(
              color: isSelected ? _config.accentColor : context.textSecondary,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              fontSize: 13,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: isSelected
                    ? _config.accentColor.withOpacity(0.4)
                    : Colors.grey.withOpacity(0.2),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          ),
        );
      }).toList(),
    );
  }

  // ============================================
  // METRIC SECTION (header + chart + stats)
  // ============================================

  Widget _buildMetricSection(BuildContext context, HealthMetricType metricType) {
    final info = _metricInfoMap[metricType]!;
    final data = _metricData[metricType] ?? [];

    return Consumer<HealthProvider>(
      builder: (context, health, _) {
        final currentValue = _getCurrentValue(metricType, health);

        return Container(
          margin: const EdgeInsets.only(bottom: 20),
          padding: const EdgeInsets.all(16),
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
              // Tappable header → navigates to individual detail
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    SlidePageRoute(
                      page: HealthMetricDetailScreen(
                        metricType: metricType,
                        icon: info.icon,
                        label: info.label,
                        currentValue: currentValue,
                        unit: info.unit,
                        color: info.color,
                        description: info.description,
                      ),
                    ),
                  );
                },
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            info.color.withOpacity(0.18),
                            info.color.withOpacity(0.08),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(info.icon, color: info.color, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            info.label,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            info.description.split('.').first + '.',
                            style: TextStyle(
                              fontSize: 11,
                              color: context.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      currentValue,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: info.color,
                      ),
                    ),
                    if (info.unit.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(left: 2),
                        child: Text(
                          info.unit,
                          style: TextStyle(
                            fontSize: 11,
                            color: context.textSecondary,
                          ),
                        ),
                      ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.chevron_right,
                      size: 18,
                      color: context.textSecondary,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Mini chart
              _buildMiniChart(context, data, info.color, metricType),

              const SizedBox(height: 12),

              // Stats row
              _buildMiniStatsRow(context, data, info.color, metricType),
            ],
          ),
        );
      },
    );
  }

  // ============================================
  // MINI CHART (compact version of detail screen chart)
  // ============================================

  Widget _buildMiniChart(BuildContext context, List<MetricDataPoint> data,
      Color color, HealthMetricType metricType) {
    if (data.isEmpty) return const SizedBox.shrink();

    final values = data.map((d) => d.value).toList();
    final minVal = values.reduce(min);
    final maxVal = values.reduce(max);
    final range = maxVal - minVal;
    final padding = range * 0.15;

    return SizedBox(
      height: 160,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: range > 0 ? range / 3 : 1,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.grey.withOpacity(0.1),
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                getTitlesWidget: (value, meta) {
                  return Text(
                    _formatAxisValue(value, metricType),
                    style: TextStyle(
                      fontSize: 9,
                      color: context.textSecondary,
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
                interval: _selectedDays <= 7
                    ? 1
                    : (_selectedDays <= 14 ? 2 : 5),
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= data.length) {
                    return const SizedBox.shrink();
                  }
                  final date = data[idx].date;
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      '${date.month}/${date.day}',
                      style: TextStyle(
                        fontSize: 9,
                        color: context.textSecondary,
                      ),
                    ),
                  );
                },
              ),
            ),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          minY: (minVal - padding).clamp(0, double.infinity),
          maxY: maxVal + padding,
          lineTouchData: LineTouchData(
            handleBuiltInTouches: true,
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => context.surface,
              tooltipPadding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              getTooltipItems: (spots) {
                return spots.map((spot) {
                  final idx = spot.x.toInt();
                  final date = idx >= 0 && idx < data.length
                      ? data[idx].date
                      : DateTime.now();
                  return LineTooltipItem(
                    '${_formatTooltipValue(spot.y, metricType)}\n',
                    TextStyle(
                      color: color,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                    children: [
                      TextSpan(
                        text: '${_monthName(date.month)} ${date.day}',
                        style: TextStyle(
                          color: context.textSecondary,
                          fontWeight: FontWeight.w400,
                          fontSize: 10,
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
                data.length,
                (i) => FlSpot(i.toDouble(), data[i].value),
              ),
              isCurved: true,
              curveSmoothness: 0.3,
              color: color,
              barWidth: 2.5,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: _selectedDays <= 14,
                getDotPainter: (spot, percent, bar, idx) =>
                    FlDotCirclePainter(
                  radius: 2.5,
                  color: color,
                  strokeWidth: 1,
                  strokeColor: Colors.white,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    color.withOpacity(0.2),
                    color.withOpacity(0.0),
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

  // ============================================
  // MINI STATS ROW (avg / high / low)
  // ============================================

  Widget _buildMiniStatsRow(BuildContext context, List<MetricDataPoint> data,
      Color color, HealthMetricType metricType) {
    if (data.isEmpty) return const SizedBox.shrink();

    final values = data.map((d) => d.value).toList();
    final avg = values.reduce((a, b) => a + b) / values.length;
    final high = values.reduce(max);
    final low = values.reduce(min);

    return Row(
      children: [
        _MiniStat(
            label: 'Avg',
            value: _formatStatValue(avg, metricType),
            color: color),
        const SizedBox(width: 8),
        _MiniStat(
            label: 'High',
            value: _formatStatValue(high, metricType),
            color: RivlColors.success),
        const SizedBox(width: 8),
        _MiniStat(
            label: 'Low',
            value: _formatStatValue(low, metricType),
            color: RivlColors.warning),
      ],
    );
  }

  // ============================================
  // WEEKLY STEPS (Activity & Performance)
  // ============================================

  Widget _buildWeeklyStepsSection(BuildContext context) {
    return Consumer<HealthProvider>(
      builder: (context, health, _) {
        final weeklySteps = health.weeklySteps;
        final days = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
        final maxSteps = weeklySteps.isNotEmpty
            ? weeklySteps
                .map((d) => d.steps)
                .reduce((a, b) => a > b ? a : b)
                .toDouble()
            : 10000.0;
        final todayIndex = DateTime.now().weekday % 7;

        return Container(
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
                  const Text('This Week',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  const Spacer(),
                  Text(
                    '${health.formatSteps(health.weeklyTotal)} total',
                    style: TextStyle(
                      fontSize: 13,
                      color: context.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 120,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(7, (i) {
                    final steps =
                        i < weeklySteps.length ? weeklySteps[i].steps : 0;
                    final heightFraction =
                        maxSteps > 0 ? (steps / maxSteps) : 0.0;
                    final isToday = i == todayIndex;

                    return TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: heightFraction),
                      duration: Duration(milliseconds: 600 + i * 80),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, _) {
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              width: 32,
                              height: (100 * value).clamp(4.0, 100.0),
                              decoration: BoxDecoration(
                                color: isToday
                                    ? _config.accentColor
                                    : _config.accentColor.withOpacity(0.25),
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              days[i],
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isToday
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isToday
                                    ? _config.accentColor
                                    : context.textSecondary,
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  }),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _WeeklyStat(
                      label: 'Average',
                      value: health.formatSteps(health.weeklyAverage)),
                  _WeeklyStat(
                      label: 'Best Day',
                      value: health.formatSteps(health.weeklyBest)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ============================================
  // RECENT WORKOUTS (Activity & Performance)
  // ============================================

  Widget _buildRecentWorkoutsSection(BuildContext context) {
    return Consumer<HealthProvider>(
      builder: (context, health, _) {
        final workouts = health.recentWorkouts;
        if (workouts.isEmpty) return const SizedBox.shrink();

        return Container(
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
              const Text('Recent Workouts',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              ...workouts.take(3).map((workout) {
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      SlidePageRoute(
                        page: WorkoutDetailScreen(workout: workout),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: workout.accentColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(workout.iconData,
                              color: workout.accentColor, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(workout.displayName,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600)),
                              Text(
                                '${workout.formattedDuration} \u2022 ${workout.calories} cal',
                                style: TextStyle(
                                  color: context.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right,
                            size: 18, color: context.textSecondary),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  // ============================================
  // SLEEP STAGE BREAKDOWN (Sleep & Recovery)
  // ============================================

  Widget _buildSleepBreakdownCard(BuildContext context) {
    return Consumer<HealthProvider>(
      builder: (context, health, _) {
        final deep = health.deepSleepHours;
        final rem = health.remSleepHours;
        final light = health.lightSleepHours;
        final awake = health.awakeDuration;
        final total = health.sleepHours;
        final quality = health.sleepQualityScore;
        final efficiency = health.sleepEfficiency;

        if (total <= 0) return const SizedBox.shrink();

        final stages = [
          _SleepStage('Deep', deep, const Color(0xFF1A237E)),
          _SleepStage('REM', rem, const Color(0xFF7C4DFF)),
          _SleepStage('Light', light, const Color(0xFF42A5F5)),
          _SleepStage('Awake', awake, const Color(0xFFFFB74D)),
        ];

        return Container(
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
                  const Text('Sleep Stages',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _qualityColor(quality).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Quality $quality',
                      style: TextStyle(
                        color: _qualityColor(quality),
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Stacked bar showing stage proportions
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SizedBox(
                  height: 20,
                  child: Row(
                    children: stages.where((s) => s.hours > 0).map((s) {
                      final fraction = s.hours / (total + awake);
                      return Expanded(
                        flex: (fraction * 1000).round().clamp(1, 1000),
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: 1),
                          duration: const Duration(milliseconds: 800),
                          builder: (context, value, _) {
                            return Container(
                              color: s.color.withOpacity(0.15 + 0.85 * value),
                            );
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Stage breakdown rows
              ...stages.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: s.color,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      s.label,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _formatHours(s.hours),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 42,
                      child: Text(
                        total > 0 ? '${(s.hours / (total + awake) * 100).round()}%' : '--',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 13,
                          color: context.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              )),

              const Divider(height: 24),

              // Efficiency row
              Row(
                children: [
                  Icon(Icons.speed, size: 16, color: context.textSecondary),
                  const SizedBox(width: 6),
                  Text(
                    'Sleep Efficiency',
                    style: TextStyle(fontSize: 13, color: context.textSecondary),
                  ),
                  const Spacer(),
                  Text(
                    '${efficiency.round()}%',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Color _qualityColor(int score) {
    if (score >= 80) return RivlColors.success;
    if (score >= 60) return Colors.lightGreen;
    if (score >= 40) return RivlColors.warning;
    return RivlColors.error;
  }

  String _formatHours(double hours) {
    final h = hours.floor();
    final m = ((hours - h) * 60).round();
    if (h == 0 && m == 0) return '0m';
    if (h == 0) return '${m}m';
    if (m == 0) return '${h}h';
    return '${h}h ${m}m';
  }

  // ============================================
  // HEALTH SCORE BREAKDOWN (Overall)
  // ============================================

  Widget _buildHealthScoreBreakdownCard(BuildContext context) {
    return Consumer<HealthProvider>(
      builder: (context, health, _) {
        final components = [
          _ScoreBar('Steps', health.scoreSteps, 0.20, Icons.directions_walk, RivlColors.primary),
          _ScoreBar('Calories', health.scoreCalories, 0.15, Icons.local_fire_department, Colors.green),
          _ScoreBar('Exercise', health.scoreExercise, 0.15, Icons.fitness_center, Colors.orange),
          _ScoreBar('Sleep', health.scoreSleep, 0.20, Icons.bedtime, Colors.indigo),
          _ScoreBar('RHR', health.scoreRhr, 0.15, Icons.monitor_heart, Colors.pink),
          _ScoreBar('HRV', health.scoreHrv, 0.15, Icons.show_chart, Colors.purple),
        ];

        return Container(
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
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _config.accentColor.withOpacity(0.18),
                          _config.accentColor.withOpacity(0.08),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.bar_chart_rounded, color: _config.accentColor, size: 18),
                  ),
                  const SizedBox(width: 10),
                  const Text('Score Breakdown',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 20),

              ...components.map((c) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(
                  children: [
                    Icon(c.icon, size: 16, color: c.color),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 62,
                      child: Text(
                        c.label,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Expanded(
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: (c.score / 100).clamp(0.0, 1.0)),
                        duration: const Duration(milliseconds: 800),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, _) {
                          return Container(
                            height: 8,
                            decoration: BoxDecoration(
                              color: c.color.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: value,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: c.color,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 28,
                      child: Text(
                        '${c.score.round()}',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: c.color,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    SizedBox(
                      width: 28,
                      child: Text(
                        '${(c.weight * 100).round()}%',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 10,
                          color: context.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
            ],
          ),
        );
      },
    );
  }

  // ============================================
  // AI RECOMMENDATION CARD (Overall)
  // ============================================

  Widget _buildAiRecommendationCard(BuildContext context) {
    return Consumer<HealthProvider>(
      builder: (context, health, _) {
        final tips = _generateTips(health);

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                context.surface,
                _config.accentColor.withOpacity(0.06),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: _config.accentColor.withOpacity(0.08),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _config.accentColor.withOpacity(0.18),
                          _config.accentColor.withOpacity(0.08),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.auto_awesome,
                        color: _config.accentColor, size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'AI Coach',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _config.accentColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Score: ${health.rivlHealthScore} (${health.rivlHealthGrade})',
                      style: TextStyle(
                        color: _config.accentColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Based on your current metrics, here\u2019s how to improve your RIVL Health Score:',
                style: TextStyle(
                  fontSize: 13,
                  color: context.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              ...tips.map((tip) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 2),
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: tip.color.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(tip.icon, color: tip.color, size: 14),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tip.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                tip.message,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: context.textSecondary,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ),
        );
      },
    );
  }

  List<_AiTip> _generateTips(HealthProvider health) {
    final tips = <_AiTip>[];

    // Steps analysis
    final stepsScore = (health.todaySteps / 10000 * 100).clamp(0.0, 100.0);
    if (stepsScore < 70) {
      final deficit = 10000 - health.todaySteps;
      tips.add(_AiTip(
        icon: Icons.directions_walk,
        color: RivlColors.primary,
        title: 'Move more',
        message:
            'You\'re at ${health.formatSteps(health.todaySteps)} steps today. '
            'Add ${health.formatSteps(deficit)} more to hit your goal and boost your score by ~5 points.',
      ));
    }

    // Sleep analysis
    if (health.sleepHours > 0 && health.sleepHours < 7) {
      final deficit = (7 - health.sleepHours).toStringAsFixed(1);
      tips.add(_AiTip(
        icon: Icons.bedtime,
        color: Colors.indigo,
        title: 'Prioritize sleep',
        message:
            'You got ${health.formatSleep(health.sleepHours)} last night. '
            'Try to get an extra ${deficit}h to reach the 7-9 hour sweet spot \u2014 this alone could improve your score by ~8 points.',
      ));
    }

    // Heart health analysis
    if (health.restingHeartRate > 70) {
      tips.add(_AiTip(
        icon: Icons.favorite,
        color: Colors.red,
        title: 'Improve resting heart rate',
        message:
            'Your resting HR of ${health.restingHeartRate} bpm is above optimal. '
            'Consistent cardio 3-4x per week can lower it by 5-10 bpm over a few months.',
      ));
    }

    // HRV analysis
    if (health.hrv > 0 && health.hrv < 40) {
      tips.add(_AiTip(
        icon: Icons.show_chart,
        color: Colors.purple,
        title: 'Boost your HRV',
        message:
            'Your HRV of ${health.formatHRV(health.hrv)} is below average. '
            'Focus on stress management, consistent sleep schedule, and avoiding alcohol before bed.',
      ));
    }

    // Recovery check
    if (health.recoveryScore < 50) {
      tips.add(_AiTip(
        icon: Icons.battery_charging_full,
        color: Colors.orange,
        title: 'Rest & recover',
        message:
            'Your recovery score is ${health.recoveryScore}/100. '
            'Consider a light day \u2014 overtraining when recovery is low increases injury risk.',
      ));
    }

    // If doing great
    if (tips.isEmpty) {
      tips.add(_AiTip(
        icon: Icons.emoji_events,
        color: RivlColors.success,
        title: 'Great job!',
        message:
            'All your metrics look strong. Keep up the consistency \u2014 '
            'you\'re on track for an excellent RIVL Health Score.',
      ));
    }

    return tips.take(3).toList();
  }

  // ============================================
  // FORMAT HELPERS
  // ============================================

  String _formatAxisValue(double value, HealthMetricType type) {
    switch (type) {
      case HealthMetricType.sleep:
        return '${value.toStringAsFixed(0)}h';
      case HealthMetricType.bloodOxygen:
        return '${value.toStringAsFixed(0)}%';
      default:
        return value.toStringAsFixed(0);
    }
  }

  String _formatTooltipValue(double value, HealthMetricType type) {
    switch (type) {
      case HealthMetricType.sleep:
        final h = value.floor();
        final m = ((value - h) * 60).round();
        return m > 0 ? '${h}h ${m}m' : '${h}h';
      case HealthMetricType.bloodOxygen:
        return '${value.toStringAsFixed(1)}%';
      case HealthMetricType.hrv:
      case HealthMetricType.vo2Max:
        return value.toStringAsFixed(1);
      default:
        return value.toStringAsFixed(0);
    }
  }

  String _formatStatValue(double value, HealthMetricType type) {
    switch (type) {
      case HealthMetricType.sleep:
        final h = value.floor();
        final m = ((value - h) * 60).round();
        return m > 0 ? '${h}h ${m}m' : '${h}h';
      case HealthMetricType.bloodOxygen:
        return '${value.toStringAsFixed(1)}%';
      case HealthMetricType.hrv:
      case HealthMetricType.vo2Max:
        return value.toStringAsFixed(1);
      default:
        return value.toStringAsFixed(0);
    }
  }

  String _monthName(int month) {
    const names = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return names[(month - 1).clamp(0, 11)];
  }
}

// ============================================
// SHARED HELPER WIDGETS
// ============================================

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: context.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeeklyStat extends StatelessWidget {
  final String label;
  final String value;

  const _WeeklyStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: context.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _AiTip {
  final IconData icon;
  final Color color;
  final String title;
  final String message;
  const _AiTip({
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
  });
}

class _SleepStage {
  final String label;
  final double hours;
  final Color color;
  const _SleepStage(this.label, this.hours, this.color);
}

class _ScoreBar {
  final String label;
  final double score;
  final double weight;
  final IconData icon;
  final Color color;
  const _ScoreBar(this.label, this.score, this.weight, this.icon, this.color);
}

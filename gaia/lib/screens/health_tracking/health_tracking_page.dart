import 'dart:math';

import 'package:flutter/material.dart';
import 'package:gaia/models/health_metric.dart';
import 'package:gaia/values/values.dart';

class HealthTrackingPage extends StatefulWidget {
  const HealthTrackingPage({Key? key}) : super(key: key);

  @override
  State<HealthTrackingPage> createState() => _HealthTrackingPageState();
}

class _HealthTrackingPageState extends State<HealthTrackingPage> {
  static const Map<String, _MetricConfig> _metricConfigs = {
    'sleep': _MetricConfig(
      key: 'sleep',
      label: 'Sleep',
      unit: 'h',
      icon: Icons.nights_stay_rounded,
      color: AppColors.turquoise,
      minInput: 0,
      maxInput: 20,
      decimals: 1,
      goalTarget: 7,
      goalUpperTarget: 9,
      healthyMin: 6,
      healthyMax: 9.5,
      quickHint: 'How many hours did you sleep?',
    ),
    'exercise': _MetricConfig(
      key: 'exercise',
      label: 'Exercise',
      unit: 'min',
      icon: Icons.directions_run_rounded,
      color: AppColors.orange,
      minInput: 0,
      maxInput: 360,
      decimals: 0,
      goalTarget: 45,
      goalUpperTarget: null,
      healthyMin: 20,
      healthyMax: 120,
      quickHint: 'Total active minutes today',
    ),
    'weight': _MetricConfig(
      key: 'weight',
      label: 'Weight',
      unit: 'kg',
      icon: Icons.monitor_weight_outlined,
      color: AppColors.pink,
      minInput: 20,
      maxInput: 250,
      decimals: 1,
      goalTarget: 65,
      goalUpperTarget: 78,
      healthyMin: 50,
      healthyMax: 95,
      quickHint: 'Current body weight',
    ),
    'blood_pressure': _MetricConfig(
      key: 'blood_pressure',
      label: 'Blood Pressure',
      unit: 'mmHg',
      icon: Icons.favorite_outline_rounded,
      color: AppColors.purple,
      minInput: 70,
      maxInput: 220,
      decimals: 0,
      goalTarget: 95,
      goalUpperTarget: 120,
      healthyMin: 90,
      healthyMax: 130,
      quickHint: 'Systolic value (top number)',
    ),
    'mood': _MetricConfig(
      key: 'mood',
      label: 'Mood',
      unit: '/10',
      icon: Icons.mood_rounded,
      color: AppColors.purple,
      minInput: 1,
      maxInput: 10,
      decimals: 1,
      goalTarget: 7,
      goalUpperTarget: null,
      healthyMin: 5,
      healthyMax: 10,
      quickHint: 'How do you feel today?',
    ),
    'water': _MetricConfig(
      key: 'water',
      label: 'Water',
      unit: 'L',
      icon: Icons.local_drink_outlined,
      color: AppColors.turquoise,
      minInput: 0,
      maxInput: 8,
      decimals: 1,
      goalTarget: 2.5,
      goalUpperTarget: null,
      healthyMin: 1.5,
      healthyMax: 4,
      quickHint: 'Total water intake',
    ),
    'steps': _MetricConfig(
      key: 'steps',
      label: 'Steps',
      unit: 'steps',
      icon: Icons.directions_walk_rounded,
      color: AppColors.orange,
      minInput: 0,
      maxInput: 40000,
      decimals: 0,
      goalTarget: 10000,
      goalUpperTarget: null,
      healthyMin: 3000,
      healthyMax: 20000,
      quickHint: 'Daily steps count',
    ),
    'heart_rate': _MetricConfig(
      key: 'heart_rate',
      label: 'Heart Rate',
      unit: 'bpm',
      icon: Icons.favorite_rounded,
      color: AppColors.pink,
      minInput: 30,
      maxInput: 220,
      decimals: 0,
      goalTarget: 55,
      goalUpperTarget: 75,
      healthyMin: 50,
      healthyMax: 95,
      quickHint: 'Resting heart rate',
    ),
  };

  static const Map<String, String> _periodLabels = {
    '7d': '7D',
    '30d': '30D',
    '90d': '90D',
    'all': 'All',
  };

  bool _isLoading = false;
  String? _errorMessage;
  String _selectedPeriod = '30d';
  String _selectedTypeFilter = 'all';
  List<HealthMetric> _metrics = [];

  @override
  void initState() {
    super.initState();
    _loadHealthMetrics();
  }

  Future<void> _loadHealthMetrics() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await Future<void>.delayed(const Duration(milliseconds: 250));
      final generated = _generateMockData()..sort((a, b) => b.date.compareTo(a.date));
      setState(() {
        _metrics = generated;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load health metrics: $e';
      });
    }
  }

  List<HealthMetric> _generateMockData() {
    final random = Random(97);
    final now = DateUtils.dateOnly(DateTime.now());
    final metrics = <HealthMetric>[];

    for (var dayOffset = 0; dayOffset < 120; dayOffset++) {
      final day = now.subtract(Duration(days: dayOffset));
      if (random.nextDouble() < 0.08) {
        continue;
      }

      _tryAddMetric(random, metrics, day, 'sleep', chance: 0.92);
      _tryAddMetric(random, metrics, day, 'mood', chance: 0.85);
      _tryAddMetric(random, metrics, day, 'steps', chance: 0.82);
      _tryAddMetric(random, metrics, day, 'water', chance: 0.70);
      _tryAddMetric(random, metrics, day, 'exercise', chance: 0.66);
      _tryAddMetric(random, metrics, day, 'heart_rate', chance: 0.58);
      _tryAddMetric(random, metrics, day, 'weight', chance: 0.25);
      _tryAddMetric(random, metrics, day, 'blood_pressure', chance: 0.20);
    }

    return metrics;
  }

  void _tryAddMetric(
    Random random,
    List<HealthMetric> metrics,
    DateTime day,
    String type, {
    required double chance,
  }) {
    if (random.nextDouble() > chance) {
      return;
    }

    final config = _metricConfigs[type]!;
    final value = _mockValue(type, random);
    final note = _mockNote(type, random, value);

    metrics.add(
      HealthMetric(
        id: '${type}_${day.microsecondsSinceEpoch}_${random.nextInt(10000)}',
        name: config.label,
        type: config.key,
        value: value,
        unit: config.unit,
        date: day.add(
          Duration(hours: 6 + random.nextInt(15), minutes: random.nextInt(59)),
        ),
        note: note,
      ),
    );
  }

  double _mockValue(String type, Random random) {
    switch (type) {
      case 'sleep':
        return _round(5.3 + random.nextDouble() * 4.2, 1);
      case 'exercise':
        return _round(8 + random.nextDouble() * 85, 0);
      case 'weight':
        return _round(66 + random.nextDouble() * 12, 1);
      case 'blood_pressure':
        return _round(101 + random.nextDouble() * 32, 0);
      case 'mood':
        return _round(4 + random.nextDouble() * 6, 1);
      case 'water':
        return _round(1 + random.nextDouble() * 2.8, 1);
      case 'steps':
        return _round(2600 + random.nextDouble() * 11000, 0);
      case 'heart_rate':
        return _round(56 + random.nextDouble() * 30, 0);
      default:
        return 0;
    }
  }

  String? _mockNote(String type, Random random, double value) {
    if (random.nextDouble() < 0.65) {
      return null;
    }

    switch (type) {
      case 'sleep':
        return value < 6.5 ? 'Late night, trying to recover.' : 'Slept better than usual.';
      case 'exercise':
        return value > 60 ? 'Strength + cardio session.' : 'Light movement day.';
      case 'mood':
        return value < 5.5 ? 'Stressful workday.' : 'Felt focused and calm.';
      case 'water':
        return value < 2 ? 'Need to hydrate earlier.' : 'Hydration target almost done.';
      case 'heart_rate':
        return value > 82 ? 'After a busy morning commute.' : 'Measured at rest.';
      default:
        return null;
    }
  }

  List<HealthMetric> _filteredMetrics() {
    final periodStart = _periodStart(_selectedPeriod);
    final results = _metrics.where((metric) {
      final inPeriod = periodStart == null || !metric.date.isBefore(periodStart);
      final inType = _selectedTypeFilter == 'all' || metric.type == _selectedTypeFilter;
      return inPeriod && inType;
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    return results;
  }

  DateTime? _periodStart(String period) {
    final today = DateUtils.dateOnly(DateTime.now());
    switch (period) {
      case '7d':
        return today.subtract(const Duration(days: 6));
      case '30d':
        return today.subtract(const Duration(days: 29));
      case '90d':
        return today.subtract(const Duration(days: 89));
      case 'all':
        return null;
      default:
        return null;
    }
  }

  int _activeDaysCount(List<HealthMetric> metrics) {
    return metrics.map((m) => _dayKey(m.date)).toSet().length;
  }

  int _currentStreak() {
    final availableDays = _metrics.map((m) => _dayKey(m.date)).toSet();
    var streak = 0;
    var cursor = DateUtils.dateOnly(DateTime.now());

    while (availableDays.contains(_dayKey(cursor))) {
      streak += 1;
      cursor = cursor.subtract(const Duration(days: 1));
    }

    return streak;
  }

  double _wellnessScore(List<HealthMetric> metrics) {
    if (metrics.isEmpty) {
      return 0;
    }

    final latestByType = <String, HealthMetric>{};
    for (final metric in metrics) {
      latestByType.putIfAbsent(metric.type, () => metric);
    }

    if (latestByType.isEmpty) {
      return 0;
    }

    var total = 0.0;
    for (final entry in latestByType.entries) {
      total += _normalizedMetricScore(entry.key, entry.value.value);
    }

    final average = total / latestByType.length;
    return (average * 100).clamp(0, 100);
  }

  double _normalizedMetricScore(String type, double value) {
    final config = _metricConfigs[type];
    if (config == null) {
      return 0;
    }

    final upper = config.goalUpperTarget;
    if (upper == null) {
      return (value / config.goalTarget).clamp(0, 1);
    }

    if (value >= config.goalTarget && value <= upper) {
      return 1;
    }
    if (value < config.goalTarget) {
      return (value / config.goalTarget).clamp(0, 1);
    }

    return (upper / value).clamp(0, 1);
  }

  double _averageForType(List<HealthMetric> metrics, String type) {
    final values = metrics.where((m) => m.type == type).map((m) => m.value).toList();
    if (values.isEmpty) {
      return 0;
    }

    return values.reduce((a, b) => a + b) / values.length;
  }

  HealthMetric? _latestForType(List<HealthMetric> metrics, String type) {
    for (final metric in metrics) {
      if (metric.type == type) {
        return metric;
      }
    }
    return null;
  }

  List<HealthMetric> _entriesForType(List<HealthMetric> metrics, String type) {
    return metrics.where((m) => m.type == type).toList();
  }

  double _trendPercent(List<double> values) {
    if (values.length < 4) {
      return 0;
    }

    final split = values.length ~/ 2;
    final older = values.take(split).toList();
    final newer = values.skip(split).toList();
    final olderAvg = older.reduce((a, b) => a + b) / older.length;
    final newerAvg = newer.reduce((a, b) => a + b) / newer.length;

    if (olderAvg == 0) {
      return 0;
    }

    return ((newerAvg - olderAvg) / olderAvg) * 100;
  }

  bool _isPositiveTrend(String type, double trend) {
    if (trend == 0) {
      return true;
    }

    const lowerIsBetter = {'weight', 'blood_pressure', 'heart_rate'};
    return lowerIsBetter.contains(type) ? trend < 0 : trend > 0;
  }

  List<_HealthAlert> _alerts(List<HealthMetric> metrics) {
    final alerts = <_HealthAlert>[];
    final latestByType = <String, HealthMetric>{};

    for (final metric in metrics) {
      latestByType.putIfAbsent(metric.type, () => metric);
    }

    for (final entry in latestByType.entries) {
      final type = entry.key;
      final metric = entry.value;
      final config = _metricConfigs[type];
      if (config == null) {
        continue;
      }

      if (metric.value < config.healthyMin) {
        alerts.add(
          _HealthAlert(
            title: '${config.label} is below the healthy range',
            description:
                'Latest: ${_formatValue(metric.value, config.decimals)} ${config.unit} (target ${_goalText(config)})',
            color: AppColors.orange,
            icon: Icons.warning_amber_rounded,
          ),
        );
      } else if (metric.value > config.healthyMax) {
        alerts.add(
          _HealthAlert(
            title: '${config.label} is above the healthy range',
            description:
                'Latest: ${_formatValue(metric.value, config.decimals)} ${config.unit} (target ${_goalText(config)})',
            color: AppColors.pink,
            icon: Icons.warning_amber_rounded,
          ),
        );
      }
    }

    return alerts;
  }

  double _goalProgress(_MetricConfig config, double currentValue) {
    final upper = config.goalUpperTarget;
    if (upper == null) {
      return (currentValue / config.goalTarget).clamp(0, 1);
    }

    if (currentValue >= config.goalTarget && currentValue <= upper) {
      return 1;
    }
    if (currentValue < config.goalTarget) {
      return (currentValue / config.goalTarget).clamp(0, 1);
    }

    return (upper / currentValue).clamp(0, 1);
  }

  String _goalText(_MetricConfig config) {
    final upper = config.goalUpperTarget;
    if (upper == null) {
      return '>= ${_formatValue(config.goalTarget, config.decimals)} ${config.unit}';
    }

    return '${_formatValue(config.goalTarget, config.decimals)} - ${_formatValue(upper, config.decimals)} ${config.unit}';
  }

  Future<void> _openMetricDialog({HealthMetric? editing, String? presetType}) async {
    final rootContext = context;
    final isEditing = editing != null;
    String selectedType = editing?.type ??
        presetType ??
        (_selectedTypeFilter == 'all' ? _metricConfigs.keys.first : _selectedTypeFilter);
    DateTime selectedDate = editing?.date ?? DateTime.now();
    String? validationError;

    final selectedConfig = _metricConfigs[selectedType]!;
    final valueController = TextEditingController(
      text: editing == null
          ? ''
          : _formatValue(editing.value, selectedConfig.decimals, trimZeros: true),
    );
    final noteController = TextEditingController(text: editing?.note ?? '');

    await showDialog<void>(
      context: rootContext,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            final config = _metricConfigs[selectedType]!;

            return AlertDialog(
              title: Text(isEditing ? 'Edit Entry' : 'Add Health Entry'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<String>(
                      value: selectedType,
                      decoration: const InputDecoration(labelText: 'Metric'),
                      items: _metricConfigs.values
                          .map(
                            (c) => DropdownMenuItem<String>(
                              value: c.key,
                              child: Text(c.label),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }
                        setDialogState(() {
                          selectedType = value;
                          validationError = null;
                        });
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      controller: valueController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Value (${config.unit})',
                        hintText: config.quickHint,
                        errorText: validationError,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: rootContext,
                          initialDate: selectedDate,
                          firstDate: DateTime(DateTime.now().year - 5),
                          lastDate: DateTime.now(),
                        );
                        if (picked == null) {
                          return;
                        }
                        setDialogState(() {
                          selectedDate = DateTime(
                            picked.year,
                            picked.month,
                            picked.day,
                            selectedDate.hour,
                            selectedDate.minute,
                          );
                        });
                      },
                      icon: const Icon(Icons.calendar_today_outlined, size: 18),
                      label: Text('Date: ${_formatLongDate(selectedDate)}'),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      controller: noteController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Notes (optional)',
                        hintText: 'Sleep quality, workout type, mood trigger...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    final parsed = double.tryParse(valueController.text.trim());
                    if (parsed == null) {
                      setDialogState(() {
                        validationError = 'Please enter a valid number.';
                      });
                      return;
                    }
                    if (parsed < config.minInput || parsed > config.maxInput) {
                      setDialogState(() {
                        validationError =
                            'Value must be between ${_formatValue(config.minInput, config.decimals)} and ${_formatValue(config.maxInput, config.decimals)}.';
                      });
                      return;
                    }

                    final newMetric = HealthMetric(
                      id: editing?.id ?? 'manual_${DateTime.now().microsecondsSinceEpoch}',
                      name: config.label,
                      type: config.key,
                      value: _round(parsed, config.decimals),
                      unit: config.unit,
                      date: selectedDate,
                      note: noteController.text.trim().isEmpty ? null : noteController.text.trim(),
                    );

                    setState(() {
                      if (isEditing) {
                        final index = _metrics.indexWhere((m) => m.id == editing!.id);
                        if (index != -1) {
                          _metrics[index] = newMetric;
                        }
                      } else {
                        _metrics.insert(0, newMetric);
                      }
                      _metrics.sort((a, b) => b.date.compareTo(a.date));
                    });

                    Navigator.pop(dialogContext);
                    ScaffoldMessenger.of(rootContext).showSnackBar(
                      SnackBar(
                        content: Text(isEditing ? 'Entry updated.' : 'Entry added.'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: Icon(isEditing ? Icons.save_outlined : Icons.add),
                  label: Text(isEditing ? 'Save' : 'Add'),
                ),
              ],
            );
          },
        );
      },
    );

    valueController.dispose();
    noteController.dispose();
  }

  void _deleteMetric(HealthMetric metric) {
    final index = _metrics.indexWhere((m) => m.id == metric.id);
    if (index == -1) {
      return;
    }

    setState(() {
      _metrics.removeAt(index);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${metric.name} entry deleted'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            setState(() {
              _metrics.insert(index, metric);
              _metrics.sort((a, b) => b.date.compareTo(a.date));
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Health Tracking', style: textTheme.headlineSmall),
        backgroundColor: AppColors.white,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loadHealthMetrics,
            icon: const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            tooltip: 'Add entry',
            onPressed: () => _openMetricDialog(),
            icon: const Icon(Icons.add_rounded),
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorState()
              : _buildContent(),
    );
  }

  Widget _buildErrorState() {
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 52, color: AppColors.pink),
            const SizedBox(height: AppSpacing.md),
            Text('Unable to load health metrics', style: textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            Text(_errorMessage ?? 'Unknown error', style: textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.md),
            ElevatedButton.icon(
              onPressed: _loadHealthMetrics,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final filtered = _filteredMetrics();
    return RefreshIndicator(
      onRefresh: _loadHealthMetrics,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              _buildHeroCard(filtered),
              const SizedBox(height: AppSpacing.md),
              _buildFilterSection(),
              const SizedBox(height: AppSpacing.md),
              _buildQuickStats(filtered),
              const SizedBox(height: AppSpacing.md),
              _buildAlertsSection(filtered),
              const SizedBox(height: AppSpacing.md),
              _buildTrendsSection(filtered, constraints.maxWidth),
              const SizedBox(height: AppSpacing.md),
              _buildGoalsSection(filtered),
              const SizedBox(height: AppSpacing.md),
              _buildQuickActions(),
              const SizedBox(height: AppSpacing.md),
              _buildLogsSection(filtered),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeroCard(List<HealthMetric> metrics) {
    final textTheme = Theme.of(context).textTheme;
    final score = _wellnessScore(metrics);
    final streak = _currentStreak();
    final activeDays = _activeDaysCount(metrics);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.turquoise.withOpacity(0.18),
            AppColors.purple.withOpacity(0.14),
            AppColors.pink.withOpacity(0.10),
          ],
        ),
        border: Border.all(color: AppColors.gray[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Health Overview', style: textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Score ${score.toStringAsFixed(0)} • ${_scoreLabel(score)}',
            style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _summaryPill(
                icon: Icons.local_fire_department_outlined,
                text: '$streak day streak',
              ),
              _summaryPill(
                icon: Icons.event_available_outlined,
                text: '$activeDays active days',
              ),
              _summaryPill(
                icon: Icons.list_alt_rounded,
                text: '${metrics.length} entries',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryPill({required IconData icon, required String text}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.65),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.gray[200]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.gray[800]),
          const SizedBox(width: AppSpacing.xs),
          Text(text),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.gray[100],
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Filters', style: textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: _periodLabels.entries.map((entry) {
              return ChoiceChip(
                label: Text(entry.value),
                selected: _selectedPeriod == entry.key,
                onSelected: (_) => setState(() => _selectedPeriod = entry.key),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.md),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildTypeFilterChip(label: 'All', value: 'all'),
                const SizedBox(width: AppSpacing.sm),
                ..._metricConfigs.values.map(
                  (config) => Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.sm),
                    child: _buildTypeFilterChip(label: config.label, value: config.key),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeFilterChip({required String label, required String value}) {
    final isSelected = _selectedTypeFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppColors.turquoise.withOpacity(0.25),
      onSelected: (_) => setState(() => _selectedTypeFilter = value),
      checkmarkColor: AppColors.black,
    );
  }

  Widget _buildQuickStats(List<HealthMetric> filtered) {
    final sleep = _averageForType(filtered, 'sleep');
    final exercise = _averageForType(filtered, 'exercise');
    final mood = _averageForType(filtered, 'mood');

    final cards = [
      _StatCardData(
        title: 'Entries',
        value: '${filtered.length}',
        subtitle: 'Total logs in selected filter',
        icon: Icons.fact_check_outlined,
        color: AppColors.turquoise,
      ),
      _StatCardData(
        title: 'Active Days',
        value: '${_activeDaysCount(filtered)}',
        subtitle: 'Days with at least one metric',
        icon: Icons.calendar_month_outlined,
        color: AppColors.orange,
      ),
      _StatCardData(
        title: 'Avg Sleep',
        value: '${_formatValue(sleep, 1)} h',
        subtitle: 'Average sleep duration',
        icon: Icons.bedtime_outlined,
        color: AppColors.purple,
      ),
      _StatCardData(
        title: 'Avg Exercise',
        value: '${_formatValue(exercise, 0)} min',
        subtitle: 'Movement per logged day',
        icon: Icons.fitness_center_rounded,
        color: AppColors.pink,
      ),
      _StatCardData(
        title: 'Avg Mood',
        value: '${_formatValue(mood, 1)}/10',
        subtitle: 'Self-reported mood score',
        icon: Icons.sentiment_satisfied_alt_outlined,
        color: AppColors.turquoise,
      ),
    ];

    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.md,
      children: cards.map(_buildQuickStatCard).toList(),
    );
  }

  Widget _buildQuickStatCard(_StatCardData data) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 210, maxWidth: 280),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.gray[200]!),
          color: AppColors.white,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(data.icon, color: data.color, size: 20),
                const SizedBox(width: AppSpacing.sm),
                Text(data.title, style: Theme.of(context).textTheme.titleSmall),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              data.value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(data.subtitle, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertsSection(List<HealthMetric> filtered) {
    final textTheme = Theme.of(context).textTheme;
    final alerts = _alerts(filtered);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.md),
        color: AppColors.gray[100],
        border: Border.all(color: AppColors.gray[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Highlights', style: textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          if (alerts.isEmpty)
            Row(
              children: [
                Icon(Icons.check_circle_outline_rounded, color: AppColors.turquoise),
                const SizedBox(width: AppSpacing.sm),
                const Expanded(
                  child: Text('No concerning patterns found in the selected range.'),
                ),
              ],
            ),
          ...alerts.map(
            (alert) => Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: AppSpacing.sm),
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: alert.color.withOpacity(0.11),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(alert.icon, size: 18, color: alert.color),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(alert.title, style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: AppSpacing.xs),
                        Text(alert.description, style: textTheme.bodyMedium),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendsSection(List<HealthMetric> filtered, double screenWidth) {
    final textTheme = Theme.of(context).textTheme;
    final rankedTypes = _metricConfigs.keys.toList()
      ..sort(
        (a, b) => _entriesForType(filtered, b).length.compareTo(_entriesForType(filtered, a).length),
      );
    final selectedTypes = _selectedTypeFilter == 'all'
        ? rankedTypes.take(4).toList()
        : <String>[_selectedTypeFilter];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Trend Insights', style: textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        if (selectedTypes.isEmpty)
          const Text('No trend data available. Add entries to unlock insights.')
        else
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: selectedTypes.map((type) {
              final config = _metricConfigs[type]!;
              final entries = _entriesForType(filtered, type);
              final history = entries.reversed.take(10).map((m) => m.value).toList();
              final trend = _trendPercent(history);
              final positive = _isPositiveTrend(type, trend);
              final trendColor = trend == 0
                  ? AppColors.gray[700]!
                  : positive
                      ? AppColors.turquoise
                      : AppColors.pink;
              final latest = entries.isEmpty ? null : entries.first;
              final average = _averageForType(filtered, type);
              final cardWidth = screenWidth > 880 ? (screenWidth - AppSpacing.md * 3) / 2 : screenWidth;

              return SizedBox(
                width: cardWidth,
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: AppColors.gray[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(config.icon, color: config.color),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(config.label, style: textTheme.titleSmall),
                          ),
                          Icon(
                            trend == 0
                                ? Icons.trending_flat_rounded
                                : trend > 0
                                    ? Icons.trending_up_rounded
                                    : Icons.trending_down_rounded,
                            color: trendColor,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            '${trend >= 0 ? '+' : ''}${trend.toStringAsFixed(1)}%',
                            style: textTheme.bodyMedium?.copyWith(
                              color: trendColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        latest == null
                            ? 'No entries'
                            : 'Latest: ${_formatValue(latest.value, config.decimals)} ${config.unit}',
                        style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Average: ${_formatValue(average, config.decimals)} ${config.unit}',
                        style: textTheme.bodyMedium,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _buildMiniBars(history, config.color),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildMiniBars(List<double> history, Color color) {
    if (history.isEmpty) {
      return Container(
        height: 48,
        alignment: Alignment.centerLeft,
        child: const Text('Not enough data'),
      );
    }

    final minValue = history.reduce(min);
    final maxValue = history.reduce(max);
    final spread = max(maxValue - minValue, 0.001);

    return SizedBox(
      height: 56,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: history.map((value) {
          final normalized = ((value - minValue) / spread).clamp(0.0, 1.0);
          final barHeight = 10 + normalized * 40;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Container(
                height: barHeight,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  color: color.withOpacity(0.25 + (normalized * 0.6)),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildGoalsSection(List<HealthMetric> filtered) {
    final textTheme = Theme.of(context).textTheme;
    final types = _selectedTypeFilter == 'all'
        ? _metricConfigs.keys.toList()
        : <String>[_selectedTypeFilter];

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.gray[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Goals Progress', style: textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          ...types.map((type) {
            final config = _metricConfigs[type]!;
            final latest = _latestForType(filtered, type);
            final value = latest?.value ?? 0;
            final progress = _goalProgress(config, value);
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(config.icon, size: 18, color: config.color),
                      const SizedBox(width: AppSpacing.sm),
                      Text(config.label, style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                      const Spacer(),
                      Text(
                        latest == null
                            ? 'No logs yet'
                            : '${_formatValue(value, config.decimals)} ${config.unit}',
                        style: textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    child: LinearProgressIndicator(
                      minHeight: 8,
                      value: progress,
                      backgroundColor: AppColors.gray[200],
                      valueColor: AlwaysStoppedAnimation<Color>(config.color),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Goal: ${_goalText(config)}',
                    style: textTheme.bodyMedium?.copyWith(color: AppColors.gray[700]),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    final textTheme = Theme.of(context).textTheme;
    final suggestions = _metricConfigs.values.toList();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.md),
        color: AppColors.gray[100],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Quick Log', style: textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: suggestions.map((config) {
              return ActionChip(
                avatar: Icon(config.icon, size: 16, color: config.color),
                label: Text('Add ${config.label}'),
                onPressed: () => _openMetricDialog(presetType: config.key),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLogsSection(List<HealthMetric> filtered) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.gray[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Recent Entries', style: textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          if (filtered.isEmpty)
            _buildEmptyLogsState()
          else
            ListView.separated(
              itemCount: filtered.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              separatorBuilder: (_, __) => const Divider(height: AppSpacing.lg),
              itemBuilder: (context, index) {
                final metric = filtered[index];
                final config = _metricConfigs[metric.type];
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: (config?.color ?? AppColors.gray).withOpacity(0.12),
                      child: Icon(
                        config?.icon ?? Icons.health_and_safety_outlined,
                        color: config?.color ?? AppColors.gray[800],
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  metric.name,
                                  style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                                ),
                              ),
                              Text(
                                '${_formatValue(metric.value, config?.decimals ?? 1)} ${metric.unit}',
                                style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            _formatEntryDate(metric.date),
                            style: textTheme.bodyMedium?.copyWith(color: AppColors.gray[700]),
                          ),
                          if (metric.note != null && metric.note!.trim().isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              metric.note!,
                              style: textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
                            ),
                          ],
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') {
                          _openMetricDialog(editing: metric);
                        } else if (value == 'delete') {
                          _deleteMetric(metric);
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem<String>(
                          value: 'edit',
                          child: Text('Edit'),
                        ),
                        PopupMenuItem<String>(
                          value: 'delete',
                          child: Text('Delete'),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyLogsState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.inbox_outlined, color: AppColors.gray[700]),
            const SizedBox(width: AppSpacing.sm),
            const Expanded(
              child: Text('No entries match your current filter.'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton.icon(
          onPressed: () => _openMetricDialog(
            presetType: _selectedTypeFilter == 'all' ? null : _selectedTypeFilter,
          ),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Add Entry'),
        ),
      ],
    );
  }

  String _scoreLabel(double score) {
    if (score >= 85) {
      return 'Excellent momentum';
    }
    if (score >= 70) {
      return 'Strong consistency';
    }
    if (score >= 55) {
      return 'Making progress';
    }
    return 'Needs attention';
  }

  String _formatEntryDate(DateTime date) {
    final now = DateTime.now();
    final day = DateUtils.dateOnly(date);
    final today = DateUtils.dateOnly(now);
    final diff = today.difference(day).inDays;
    if (diff == 0) {
      return 'Today • ${_twoDigits(date.hour)}:${_twoDigits(date.minute)}';
    }
    if (diff == 1) {
      return 'Yesterday • ${_twoDigits(date.hour)}:${_twoDigits(date.minute)}';
    }
    if (diff < 7) {
      return '$diff days ago';
    }
    return '${date.month}/${date.day}/${date.year}';
  }

  String _formatLongDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  String _formatValue(double value, int decimals, {bool trimZeros = false}) {
    final formatted = value.toStringAsFixed(decimals);
    if (!trimZeros || !formatted.contains('.')) {
      return formatted;
    }
    return formatted.replaceFirst(RegExp(r'\.?0+$'), '');
  }

  String _twoDigits(int value) {
    return value.toString().padLeft(2, '0');
  }

  String _dayKey(DateTime date) {
    final normalized = DateUtils.dateOnly(date);
    return '${normalized.year}-${normalized.month}-${normalized.day}';
  }

  double _round(double value, int decimals) {
    final mod = pow(10, decimals).toDouble();
    return (value * mod).roundToDouble() / mod;
  }
}

class _MetricConfig {
  final String key;
  final String label;
  final String unit;
  final IconData icon;
  final Color color;
  final double minInput;
  final double maxInput;
  final int decimals;
  final double goalTarget;
  final double? goalUpperTarget;
  final double healthyMin;
  final double healthyMax;
  final String quickHint;

  const _MetricConfig({
    required this.key,
    required this.label,
    required this.unit,
    required this.icon,
    required this.color,
    required this.minInput,
    required this.maxInput,
    required this.decimals,
    required this.goalTarget,
    required this.goalUpperTarget,
    required this.healthyMin,
    required this.healthyMax,
    required this.quickHint,
  });
}

class _HealthAlert {
  final String title;
  final String description;
  final Color color;
  final IconData icon;

  const _HealthAlert({
    required this.title,
    required this.description,
    required this.color,
    required this.icon,
  });
}

class _StatCardData {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _StatCardData({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:gaia/models/health_metric.dart';
import 'package:gaia/services/api_service.dart';
import 'package:gaia/services/auth_session.dart';
import 'package:gaia/values/values.dart';
import 'package:gaia/widgets/navbar.dart';

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
    '7d': 'Last 7 Days',
    '30d': 'Last 30 Days',
    '90d': 'Last 90 Days',
    'all': 'All Time',
  };

  bool _isLoading = false;
  String? _errorMessage;
  String _selectedPeriod = '30d';
  String _selectedTypeFilter = 'all';
  final ValueNotifier<bool> _showAdvancedSections = ValueNotifier<bool>(false);
  List<HealthMetric> _metrics = [];
  static const int _logPreviewCount = 8;

  @override
  void initState() {
    super.initState();
    _loadHealthMetrics();
  }

  @override
  void dispose() {
    _showAdvancedSections.dispose();
    super.dispose();
  }

  Future<void> _loadHealthMetrics() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final generated = await _fetchPersistedTrackerMetrics();
      setState(() {
        _metrics = generated;
        _isLoading = false;
      });
    } catch (e) {
      final message = e.toString();
      final isAuthIssue = message.contains('401') ||
          message.toLowerCase().contains('auth') ||
          message.toLowerCase().contains('token');
      if (isAuthIssue) {
        AuthSession.clear();
      }
      setState(() {
        _isLoading = false;
        _errorMessage = isAuthIssue
            ? 'Please log in to load synced step and water records.'
            : 'Failed to load health metrics: $e';
      });
    }
  }

  Future<List<HealthMetric>> _fetchPersistedTrackerMetrics() async {
    final metrics = _generateDummyNonSyncedMetrics();
    final token = AuthSession.token;
    if (token == null || token.isEmpty) {
      metrics.sort((a, b) => b.date.compareTo(a.date));
      return metrics;
    }

    try {
      final responses = await Future.wait<List<Map<String, dynamic>>>([
        ApiService.fetchStepsHistory(),
        ApiService.fetchWaterHistory(),
      ]);

      metrics.addAll(_mapStepRecordsToMetrics(responses[0]));
      metrics.addAll(_mapWaterRecordsToMetrics(responses[1]));
    } catch (_) {
      // Keep showing dummy non-synced metrics even if synced endpoints fail.
    }

    metrics.sort((a, b) => b.date.compareTo(a.date));
    return metrics;
  }

  List<HealthMetric> _generateDummyNonSyncedMetrics() {
    const dummyChances = <String, double>{
      'sleep': 0.92,
      'mood': 0.85,
      'exercise': 0.66,
      'heart_rate': 0.58,
      'weight': 0.25,
      'blood_pressure': 0.20,
    };
    final random = Random(97);
    final now = DateUtils.dateOnly(DateTime.now());
    final metrics = <HealthMetric>[];

    for (var dayOffset = 0; dayOffset < 120; dayOffset++) {
      final day = now.subtract(Duration(days: dayOffset));
      if (random.nextDouble() < 0.08) {
        continue;
      }

      for (final entry in dummyChances.entries) {
        _tryAddDummyMetric(
          random,
          metrics,
          day,
          entry.key,
          chance: entry.value,
        );
      }
    }

    return metrics;
  }

  void _tryAddDummyMetric(
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
    final value = _dummyValue(type, random);
    final note = _dummyNote(type, random, value);

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

  double _dummyValue(String type, Random random) {
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
      case 'heart_rate':
        return _round(56 + random.nextDouble() * 30, 0);
      default:
        return 0;
    }
  }

  String? _dummyNote(String type, Random random, double value) {
    if (random.nextDouble() < 0.65) {
      return null;
    }

    switch (type) {
      case 'sleep':
        return value < 6.5
            ? 'Late night, trying to recover.'
            : 'Slept better than usual.';
      case 'exercise':
        return value > 60
            ? 'Strength + cardio session.'
            : 'Light movement day.';
      case 'mood':
        return value < 5.5 ? 'Stressful workday.' : 'Felt focused and calm.';
      case 'heart_rate':
        return value > 82
            ? 'After a busy morning commute.'
            : 'Measured at rest.';
      default:
        return null;
    }
  }

  List<HealthMetric> _mapStepRecordsToMetrics(List<Map<String, dynamic>> records) {
    final config = _metricConfigs['steps']!;
    return records.map((record) {
      final date = _parseRecordDate(record['record_date']);
      final recordId = (record['id'] ?? date.microsecondsSinceEpoch).toString();
      final steps = (record['steps'] as num?)?.toDouble() ?? 0;

      return HealthMetric(
        id: 'steps_$recordId',
        name: config.label,
        type: config.key,
        value: steps,
        unit: config.unit,
        date: date,
      );
    }).toList();
  }

  List<HealthMetric> _mapWaterRecordsToMetrics(
    List<Map<String, dynamic>> records,
  ) {
    final config = _metricConfigs['water']!;
    return records.map((record) {
      final date = _parseRecordDate(record['record_date']);
      final recordId = (record['id'] ?? date.microsecondsSinceEpoch).toString();
      final intakeMl = (record['intake_ml'] as num?)?.toDouble() ?? 0;

      return HealthMetric(
        id: 'water_$recordId',
        name: config.label,
        type: config.key,
        value: intakeMl / 1000,
        unit: config.unit,
        date: date,
      );
    }).toList();
  }

  DateTime _parseRecordDate(dynamic value) {
    if (value is String && value.isNotEmpty) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        // Fall through to today's date fallback.
      }
    }

    return DateUtils.dateOnly(DateTime.now());
  }

  List<HealthMetric> _filteredMetrics() {
    final periodStart = _periodStart(_selectedPeriod);
    final results = _metrics.where((metric) {
      final inPeriod =
          periodStart == null || !metric.date.isBefore(periodStart);
      final inType =
          _selectedTypeFilter == 'all' || metric.type == _selectedTypeFilter;
      return inPeriod && inType;
    }).toList()..sort((a, b) => b.date.compareTo(a.date));

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
    final values = metrics
        .where((m) => m.type == type)
        .map((m) => m.value)
        .toList();
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

  Future<void> _openMetricDialog({
    HealthMetric? editing,
    String? presetType,
  }) async {
    final rootContext = context;
    final isEditing = editing != null;
    String selectedType =
        editing?.type ??
        presetType ??
        (_selectedTypeFilter == 'all'
            ? _metricConfigs.keys.first
            : _selectedTypeFilter);
    DateTime selectedDate = editing?.date ?? DateTime.now();
    String? validationError;

    final selectedConfig = _metricConfigs[selectedType]!;
    final valueController = TextEditingController(
      text: editing == null
          ? ''
          : _formatValue(
              editing.value,
              selectedConfig.decimals,
              trimZeros: true,
            ),
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
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
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
                        hintText:
                            'Sleep quality, workout type, mood trigger...',
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
                      id:
                          editing?.id ??
                          'manual_${DateTime.now().microsecondsSinceEpoch}',
                      name: config.label,
                      type: config.key,
                      value: _round(parsed, config.decimals),
                      unit: config.unit,
                      date: selectedDate,
                      note: noteController.text.trim().isEmpty
                          ? null
                          : noteController.text.trim(),
                    );

                    setState(() {
                      if (isEditing) {
                        final index = _metrics.indexWhere(
                          (m) => m.id == editing!.id,
                        );
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
                        content: Text(
                          isEditing ? 'Entry updated.' : 'Entry added.',
                        ),
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
    return Scaffold(
      appBar: const GaiaNavBarAppBar(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openMetricDialog,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Log Metric'),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: _isLoading
            ? _buildLoadingState()
            : _errorMessage != null
            ? _buildErrorState()
            : _buildContent(),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 36,
            width: 36,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
          SizedBox(height: AppSpacing.md),
          Text('Preparing your health dashboard...'),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 520),
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            color: AppColors.white,
            border: Border.all(color: AppColors.gray[200]!),
            boxShadow: [
              BoxShadow(
                color: AppColors.gray[900]!.withOpacity(0.04),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 54,
                color: AppColors.pink,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Unable to load health metrics',
                style: textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                _errorMessage ?? 'Unknown error',
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton.icon(
                onPressed: _loadHealthMetrics,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            ],
          ),
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
          final horizontalPadding = constraints.maxWidth >= 1280
              ? AppSpacing.xl
              : constraints.maxWidth >= 840
              ? AppSpacing.lg
              : AppSpacing.md;

          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              AppSpacing.lg,
              horizontalPadding,
              90,
            ),
            children: [
              _buildCommandBar(filtered),
              const SizedBox(height: AppSpacing.md),
              _buildHeroCard(filtered),
              const SizedBox(height: AppSpacing.md),
              _buildFilterSection(),
              const SizedBox(height: AppSpacing.md),
              _buildQuickStats(filtered),
              const SizedBox(height: AppSpacing.md),
              _buildTrendsSection(filtered, constraints.maxWidth),
              const SizedBox(height: AppSpacing.md),
              _buildAdvancedSections(filtered),
              const SizedBox(height: AppSpacing.md),
              _buildLogsSection(filtered),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAdvancedSections(List<HealthMetric> filtered) {
    final textTheme = Theme.of(context).textTheme;
    final advancedContent = RepaintBoundary(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.md),
          _buildAlertsSection(filtered),
          const SizedBox(height: AppSpacing.md),
          _buildGoalsSection(filtered),
          const SizedBox(height: AppSpacing.md),
          _buildQuickActions(),
        ],
      ),
    );

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        color: AppColors.white,
        border: Border.all(color: AppColors.gray[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ValueListenableBuilder<bool>(
            valueListenable: _showAdvancedSections,
            child: advancedContent,
            builder: (context, expanded, child) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'More Insights & Actions',
                              style: textTheme.titleMedium,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              'Open this only when you need deeper alerts, goals, and shortcuts.',
                              style: textTheme.bodyMedium?.copyWith(
                                color: AppColors.gray[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => _showAdvancedSections.value = !expanded,
                        icon: Icon(
                          expanded
                              ? Icons.expand_less_rounded
                              : Icons.expand_more_rounded,
                        ),
                        label: Text(expanded ? 'Collapse' : 'Expand'),
                      ),
                    ],
                  ),
                  if (expanded) child!,
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCommandBar(List<HealthMetric> filtered) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        color: AppColors.white,
        border: Border.all(color: AppColors.gray[200]!),
      ),
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 320,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Health Tracking Hub', style: textTheme.headlineSmall),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${filtered.length} logs in ${_periodLabels[_selectedPeriod]}',
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.gray[700],
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton.icon(
            onPressed: _loadHealthMetrics,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Refresh data'),
          ),
          ElevatedButton.icon(
            onPressed: _openMetricDialog,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add entry'),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroCard(List<HealthMetric> metrics) {
    final textTheme = Theme.of(context).textTheme;
    final score = _wellnessScore(metrics);
    final streak = _currentStreak();
    final activeDays = _activeDaysCount(metrics);
    final periodDays = _selectedPeriod == 'all'
        ? max(activeDays, 1)
        : int.parse(_selectedPeriod.replaceAll(RegExp(r'[^0-9]'), ''));
    final consistency = (activeDays / max(periodDays, 1)).clamp(0, 1);
    final scoreColor = score >= 85
        ? AppColors.turquoise
        : score >= 70
        ? AppColors.orange
        : score >= 55
        ? AppColors.purple
        : AppColors.pink;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.turquoise.withOpacity(0.18),
            AppColors.purple.withOpacity(0.14),
            AppColors.pink.withOpacity(0.10),
          ],
        ),
      ),
      child: Wrap(
        spacing: AppSpacing.md,
        runSpacing: AppSpacing.md,
        children: [
          SizedBox(
            width: 520,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Wellness Pulse', style: textTheme.titleMedium),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  _scoreLabel(score),
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Your wellness score is ${score.toStringAsFixed(0)} based on the latest values across tracked metrics.',
                  style: textTheme.bodyLarge,
                ),
                const SizedBox(height: AppSpacing.md),
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
                      icon: Icons.track_changes_rounded,
                      text: '${(consistency * 100).round()}% consistency',
                    ),
                    _summaryPill(
                      icon: Icons.list_alt_rounded,
                      text: '${metrics.length} total entries',
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            width: 280,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.white.withOpacity(0.72),
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.white.withOpacity(0.7)),
            ),
            child: Row(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      height: 78,
                      width: 78,
                      child: CircularProgressIndicator(
                        value: score / 100,
                        strokeWidth: 8,
                        backgroundColor: AppColors.gray[200],
                        valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                      ),
                    ),
                    Text(
                      '${score.round()}',
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    'Score for ${_periodLabels[_selectedPeriod]}',
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.gray[800],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryPill({required IconData icon, required String text}) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.65),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.white.withOpacity(0.75)),
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
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.gray[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Focus Filters', style: textTheme.titleMedium),
              const Spacer(),
              if (_selectedTypeFilter != 'all')
                TextButton.icon(
                  onPressed: () => setState(() => _selectedTypeFilter = 'all'),
                  icon: const Icon(Icons.filter_alt_off_outlined, size: 18),
                  label: const Text('Clear metric filter'),
                ),
            ],
          ),
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
                _buildTypeFilterChip(label: 'All metrics', value: 'all'),
                const SizedBox(width: AppSpacing.sm),
                ..._metricConfigs.values.map(
                  (config) => Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.sm),
                    child: _buildTypeFilterChip(
                      label: config.label,
                      value: config.key,
                    ),
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
      side: BorderSide(color: AppColors.gray[300]!),
    );
  }

  Widget _buildQuickStats(List<HealthMetric> filtered) {
    final sleep = _averageForType(filtered, 'sleep');
    final exercise = _averageForType(filtered, 'exercise');
    final mood = _averageForType(filtered, 'mood');
    final periodDays = _selectedPeriod == 'all'
        ? max(_activeDaysCount(filtered), 1)
        : int.parse(_selectedPeriod.replaceAll(RegExp(r'[^0-9]'), ''));
    final coverage = ((_activeDaysCount(filtered) / max(periodDays, 1)) * 100)
        .round();

    final cards = [
      _StatCardData(
        title: 'Entries',
        value: '${filtered.length}',
        subtitle: 'Total logs in this view',
        icon: Icons.fact_check_outlined,
        color: AppColors.turquoise,
      ),
      _StatCardData(
        title: 'Coverage',
        value: '$coverage%',
        subtitle: '${_activeDaysCount(filtered)} active days',
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

    final width = MediaQuery.of(context).size.width;
    final columns = width >= 1320
        ? 4
        : width >= 980
        ? 3
        : width >= 650
        ? 2
        : 1;
    final totalSpacing = AppSpacing.md * (columns - 1);
    final cardWidth = ((width - totalSpacing - (AppSpacing.lg * 2)) / columns)
        .clamp(220, 360)
        .toDouble();

    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.md,
      children: cards
          .map(
            (card) =>
                SizedBox(width: cardWidth, child: _buildQuickStatCard(card)),
          )
          .toList(),
    );
  }

  Widget _buildQuickStatCard(_StatCardData data) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        color: AppColors.white,
        border: Border.all(color: AppColors.gray[200]!),
        boxShadow: [
          BoxShadow(
            color: AppColors.gray[900]!.withOpacity(0.03),
            blurRadius: 16,
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
                height: 34,
                width: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: data.color.withOpacity(0.18),
                ),
                child: Icon(data.icon, size: 18, color: data.color),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: Text(data.title, style: textTheme.titleSmall)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            data.value,
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            data.subtitle,
            style: textTheme.bodyMedium?.copyWith(color: AppColors.gray[700]),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertsSection(List<HealthMetric> filtered) {
    final textTheme = Theme.of(context).textTheme;
    final alerts = _alerts(filtered);
    final todayKey = _dayKey(DateTime.now());
    final loggedToday = _metrics
        .where((m) => _dayKey(m.date) == todayKey)
        .map((m) => m.type)
        .toSet();
    final missingToday = _metricConfigs.keys
        .where((type) => !loggedToday.contains(type))
        .take(4)
        .toList();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.white, AppColors.turquoise.withOpacity(0.08)],
        ),
        border: Border.all(color: AppColors.gray[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Coach Feed', style: textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Signals to prioritize today',
            style: textTheme.bodyMedium?.copyWith(color: AppColors.gray[700]),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (alerts.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.turquoise.withOpacity(0.14),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.check_circle_outline_rounded,
                    color: AppColors.turquoise,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  const Expanded(
                    child: Text(
                      'No concerning patterns found in this period. Keep your routine consistent.',
                    ),
                  ),
                ],
              ),
            ),
          ...alerts.map(
            (alert) => Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: AppSpacing.sm),
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: alert.color.withOpacity(0.10),
                borderRadius: BorderRadius.circular(AppRadius.md),
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
                        Text(
                          alert.title,
                          style: textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(alert.description, style: textTheme.bodyMedium),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text('Quick wins for today', style: textTheme.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          if (missingToday.isEmpty)
            Text(
              'You have already logged all tracked metrics today.',
              style: textTheme.bodyMedium?.copyWith(color: AppColors.gray[700]),
            )
          else
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: missingToday.map((type) {
                final config = _metricConfigs[type]!;
                return ActionChip(
                  avatar: Icon(config.icon, size: 16, color: config.color),
                  label: Text('Log ${config.label}'),
                  onPressed: () => _openMetricDialog(presetType: config.key),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildTrendsSection(List<HealthMetric> filtered, double screenWidth) {
    final textTheme = Theme.of(context).textTheme;
    final rankedTypes = _metricConfigs.keys.toList()
      ..sort(
        (a, b) => _entriesForType(
          filtered,
          b,
        ).length.compareTo(_entriesForType(filtered, a).length),
      );
    final selectedTypes = _selectedTypeFilter == 'all'
        ? rankedTypes.take(screenWidth >= 1100 ? 6 : 4).toList()
        : <String>[_selectedTypeFilter];
    final columns = screenWidth >= 1400
        ? 3
        : screenWidth >= 980
        ? 2
        : 1;
    final totalSpacing = AppSpacing.md * (columns - 1);
    final cardWidth = ((screenWidth - totalSpacing) / columns)
        .clamp(280, 500)
        .toDouble();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.gray[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Metric Deep Dive', style: textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Live trends, consistency, and latest values for your top metrics.',
            style: textTheme.bodyMedium?.copyWith(color: AppColors.gray[700]),
          ),
          const SizedBox(height: AppSpacing.md),
          if (selectedTypes.isEmpty)
            const Text(
              'No trend data available. Add entries to unlock insights.',
            )
          else
            Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.md,
              children: selectedTypes.map((type) {
                final config = _metricConfigs[type]!;
                final entries = _entriesForType(filtered, type);
                final history = entries.reversed
                    .take(10)
                    .map((m) => m.value)
                    .toList();
                final trend = _trendPercent(history);
                final positive = _isPositiveTrend(type, trend);
                final trendColor = trend == 0
                    ? AppColors.gray[700]!
                    : positive
                    ? AppColors.turquoise
                    : AppColors.pink;
                final latest = entries.isEmpty ? null : entries.first;
                final average = _averageForType(filtered, type);
                final periodDays = _selectedPeriod == 'all'
                    ? max(_activeDaysCount(filtered), 1)
                    : int.parse(
                        _selectedPeriod.replaceAll(RegExp(r'[^0-9]'), ''),
                      );
                final consistency =
                    (entries.map((e) => _dayKey(e.date)).toSet().length /
                            max(periodDays, 1))
                        .clamp(0, 1);
                final statusColor = latest == null
                    ? AppColors.gray[700]!
                    : latest.value < config.healthyMin
                    ? AppColors.orange
                    : latest.value > config.healthyMax
                    ? AppColors.pink
                    : AppColors.turquoise;

                return SizedBox(
                  width: cardWidth,
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      color: AppColors.gray[100],
                      border: Border.all(color: AppColors.gray[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: config.color.withOpacity(0.18),
                              child: Icon(
                                config.icon,
                                color: config.color,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                config.label,
                                style: textTheme.titleSmall,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm,
                                vertical: AppSpacing.xs,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(
                                  AppRadius.xl,
                                ),
                                color: trendColor.withOpacity(0.12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    trend == 0
                                        ? Icons.trending_flat_rounded
                                        : trend > 0
                                        ? Icons.trending_up_rounded
                                        : Icons.trending_down_rounded,
                                    size: 16,
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
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          latest == null
                              ? '--'
                              : '${_formatValue(latest.value, config.decimals)} ${config.unit}',
                          style: textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          latest == null
                              ? 'No recent entry'
                              : 'Logged ${_formatEntryDate(latest.date)}',
                          style: textTheme.bodyMedium?.copyWith(
                            color: AppColors.gray[700],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(AppRadius.xl),
                          ),
                          child: Text(
                            latest == null
                                ? 'No recent value'
                                : latest.value < config.healthyMin
                                ? 'Below healthy range'
                                : latest.value > config.healthyMax
                                ? 'Above healthy range'
                                : 'In healthy range',
                            style: textTheme.bodyMedium?.copyWith(
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Goal: ${_goalText(config)}',
                          style: textTheme.bodyMedium?.copyWith(
                            color: AppColors.gray[700],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          child: LinearProgressIndicator(
                            minHeight: 8,
                            value: latest == null
                                ? 0
                                : _goalProgress(config, latest.value),
                            backgroundColor: AppColors.gray[200],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              config.color,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Consistency ${(consistency * 100).round()}% - Avg ${_formatValue(average, config.decimals)} ${config.unit}',
                          style: textTheme.bodyMedium?.copyWith(
                            color: AppColors.gray[700],
                          ),
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
      ),
    );
  }

  Widget _buildMiniBars(List<double> history, Color color) {
    if (history.isEmpty) {
      return SizedBox(
        height: 52,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Not enough history yet',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }

    final minValue = history.reduce(min);
    final maxValue = history.reduce(max);
    final spread = max(maxValue - minValue, 0.001);

    return SizedBox(
      height: 58,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: history.map((value) {
          final normalized = ((value - minValue) / spread).clamp(0.0, 1.0);
          final barHeight = 8 + (normalized * 46);
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Container(
                height: barHeight,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [color.withOpacity(0.35), color.withOpacity(0.85)],
                  ),
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
        borderRadius: BorderRadius.circular(AppRadius.lg),
        color: AppColors.white,
        border: Border.all(color: AppColors.gray[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Goal Board', style: textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'How close each metric is to your target zone.',
            style: textTheme.bodyMedium?.copyWith(color: AppColors.gray[700]),
          ),
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
                      Text(
                        config.label,
                        style: textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        latest == null
                            ? 'No logs'
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
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.gray[700],
                    ),
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
        borderRadius: BorderRadius.circular(AppRadius.lg),
        color: AppColors.white,
        border: Border.all(color: AppColors.gray[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Quick Log Shortcuts', style: textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Tap any metric to add a new entry immediately.',
            style: textTheme.bodyMedium?.copyWith(color: AppColors.gray[700]),
          ),
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
    final logs = filtered.take(40).toList();
    final previewLogs = logs.take(_logPreviewCount).toList();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        color: AppColors.white,
        border: Border.all(color: AppColors.gray[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Recent Logbook', style: textTheme.titleMedium),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      logs.isEmpty
                          ? 'No entries match your current filter'
                          : 'Showing ${previewLogs.length} of ${logs.length} entries',
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.gray[700],
                      ),
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => _openMetricDialog(
                  presetType: _selectedTypeFilter == 'all'
                      ? null
                      : _selectedTypeFilter,
                ),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add entry'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (logs.isEmpty)
            _buildEmptyLogsState()
          else
            ListView.separated(
              itemCount: previewLogs.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) =>
                  _buildLogRow(previewLogs[index], textTheme),
            ),
          if (logs.length > _logPreviewCount) ...[
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => _openFullLogbook(logs),
                icon: const Icon(Icons.open_in_new_rounded),
                label: const Text('View full logbook'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _openFullLogbook(List<HealthMetric> logs) async {
    final textTheme = Theme.of(context).textTheme;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.75,
          minChildSize: 0.55,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppRadius.xl),
                ),
                border: Border.all(color: AppColors.gray[200]!),
              ),
              child: Column(
                children: [
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.gray[300],
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Full Logbook (${logs.length})',
                            style: textTheme.titleMedium,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Close',
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.all(AppSpacing.md),
                      itemCount: logs.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, index) =>
                          _buildLogRow(logs[index], textTheme),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLogRow(HealthMetric metric, TextTheme textTheme) {
    final config = _metricConfigs[metric.type];
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.gray[200]!),
        color: AppColors.gray[100],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 15,
            backgroundColor:
                (config?.color ?? AppColors.gray).withOpacity(0.18),
            child: Icon(
              config?.icon ?? Icons.health_and_safety_outlined,
              color: config?.color ?? AppColors.gray[800],
              size: 16,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  metric.name,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatEntryDate(metric.date),
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.gray[700],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            '${_formatValue(metric.value, config?.decimals ?? 1)} ${metric.unit}',
            style: textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
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
            presetType: _selectedTypeFilter == 'all'
                ? null
                : _selectedTypeFilter,
          ),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Add entry'),
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
    final time = '${_twoDigits(date.hour)}:${_twoDigits(date.minute)}';
    if (diff == 0) {
      return 'Today - $time';
    }
    if (diff == 1) {
      return 'Yesterday - $time';
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

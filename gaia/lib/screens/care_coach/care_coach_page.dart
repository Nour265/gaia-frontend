import 'package:flutter/material.dart';
import 'package:gaia/app/routes.dart';
import 'package:gaia/values/values.dart';
import 'package:gaia/widgets/navbar.dart';
import 'package:gaia/widgets/sections/footer.dart';

class CareCoachPage extends StatefulWidget {
  const CareCoachPage({super.key});

  @override
  State<CareCoachPage> createState() => _CareCoachPageState();
}

class _CareCoachPageState extends State<CareCoachPage> {
  int _selectedMood = 1;
  double _symptomIntensity = 4;
  bool _hydrationDone = true;
  bool _medicationDone = false;
  bool _restDone = false;

  static const List<String> _moods = ['Worse', 'Same', 'Better'];

  double get _riskScore {
    var score = _symptomIntensity * 10;
    if (_selectedMood == 0) {
      score += 15;
    } else if (_selectedMood == 2) {
      score -= 12;
    } else {
      score += 4;
    }

    if (!_hydrationDone) score += 3;
    if (!_medicationDone) score += 4;
    if (!_restDone) score += 2;

    return score.clamp(5.0, 95.0);
  }

  String get _riskLabel {
    if (_riskScore >= 70) return 'High';
    if (_riskScore >= 40) return 'Moderate';
    return 'Low';
  }

  Color get _riskColor {
    if (_riskScore >= 70) return AppColors.peach;
    if (_riskScore >= 40) return AppColors.orange.shade100;
    return AppColors.turquoise.shade100;
  }

  String get _coachMessage {
    if (_riskScore >= 75) {
      return 'Risk is elevated. Seek urgent medical care now.';
    }
    if (_riskScore >= 55) {
      return 'Book a clinic visit today and keep monitoring every 6-8 hours.';
    }
    if (_riskScore >= 35) {
      return 'Continue home monitoring and re-check tonight.';
    }
    return 'Trend looks stable. Maintain your care plan and check in tomorrow.';
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final textTheme = Theme.of(context).textTheme;
    final contentWidth = size.width < 900 ? size.width * 0.9 : size.width * 0.7;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(72.0),
        child: Container(
          color: AppColors.white,
          child: Center(
            child: SizedBox(
              width: size.width * 0.7,
              child: const NavBar(showLogin: true),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHero(context, textTheme, size, contentWidth),
            _buildCommandCenter(textTheme, contentWidth),
            _buildCapabilities(textTheme, contentWidth),
            _buildCarePathTimeline(textTheme, contentWidth),
            const Footer(),
          ],
        ),
      ),
    );
  }

  Widget _buildHero(
    BuildContext context,
    TextTheme textTheme,
    Size size,
    double contentWidth,
  ) {
    final compact = size.width < 980;
    final heroHeight = compact ? 560.0 : size.height * 0.7;

    return Container(
      width: double.infinity,
      height: heroHeight,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.turquoise.shade100,
            AppColors.purple.shade100.withValues(alpha: 0.45),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -120,
            top: -80,
            child: _glow(300, AppColors.purple.shade100.withValues(alpha: 0.5)),
          ),
          Positioned(
            left: -100,
            bottom: -120,
            child: _glow(
              260,
              AppColors.turquoise.shade800.withValues(alpha: 0.18),
            ),
          ),
          Center(
            child: SizedBox(
              width: contentWidth,
              child: Flex(
                direction: compact ? Axis.vertical : Axis.horizontal,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Care Coach',
                          style: textTheme.displayMedium?.copyWith(
                            color: AppColors.gray.shade900,
                            height: 1.08,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'A continuous care layer after symptom checks. It adapts daily guidance based on how you feel, what changed, and what needs escalation.',
                          style: textTheme.bodyLarge?.copyWith(
                            color: AppColors.gray.shade800,
                            height: 1.65,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Wrap(
                          spacing: AppSpacing.md,
                          runSpacing: AppSpacing.sm,
                          children: [
                            _heroChip(textTheme, 'Dynamic risk scoring'),
                            _heroChip(textTheme, 'Follow-up reminders'),
                            _heroChip(textTheme, 'Doctor-ready summary'),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.sm,
                          children: [
                            SizedBox(
                              height: 46,
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.pushNamed(context, Routes.wizard);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.purple,
                                  foregroundColor: AppColors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.md,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  'Run Symptom Check',
                                  style: textTheme.titleSmall?.copyWith(
                                    color: AppColors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(
                              height: 46,
                              child: OutlinedButton(
                                onPressed: () {},
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.gray.shade900,
                                  side: BorderSide(
                                    color: AppColors.gray.shade300,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.md,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  'Start Daily Check-In',
                                  style: textTheme.titleSmall?.copyWith(
                                    color: AppColors.gray.shade900,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (!compact) const SizedBox(width: AppSpacing.xl),
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: EdgeInsets.only(
                        top: compact ? AppSpacing.lg : 0,
                      ),
                      child: _buildHeroVisual(textTheme),
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

  Widget _buildHeroVisual(TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.gray.shade200),
        boxShadow: [
          BoxShadow(
            color: AppColors.gray.shade200,
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: Image.asset(
              ImagePath.consult,
              fit: BoxFit.cover,
              height: 170,
              width: double.infinity,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _metricCard(
                  textTheme,
                  title: '7 day',
                  subtitle: 'coach streak',
                  icon: Icons.local_fire_department_outlined,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _metricCard(
                  textTheme,
                  title: '08:00 PM',
                  subtitle: 'next check-in',
                  icon: Icons.notifications_active_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.purple.shade100,
                  AppColors.turquoise.shade100,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.monitor_heart_outlined,
                  color: AppColors.purple,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Live trend monitor active for respiratory symptom cluster.',
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.gray.shade900,
                      fontWeight: FontWeight.w600,
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

  Widget _buildCommandCenter(TextTheme textTheme, double contentWidth) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xxl,
      ),
      child: Center(
        child: SizedBox(
          width: contentWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Care Coach Command Center',
                style: textTheme.titleLarge?.copyWith(
                  color: AppColors.gray.shade900,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Daily check-in, risk signal, and action plan in one place.',
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.gray.shade700,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              LayoutBuilder(
                builder: (context, constraints) {
                  final singleColumn = constraints.maxWidth < 1000;
                  final paneWidth = singleColumn
                      ? constraints.maxWidth
                      : (constraints.maxWidth - AppSpacing.md) / 2;

                  return Wrap(
                    spacing: AppSpacing.md,
                    runSpacing: AppSpacing.md,
                    children: [
                      _buildCheckinPanel(textTheme, paneWidth),
                      _buildInsightPanel(textTheme, paneWidth),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCheckinPanel(TextTheme textTheme, double width) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.gray.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Today Check-In',
            style: textTheme.headlineSmall?.copyWith(
              color: AppColors.gray.shade900,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Update your status in under 30 seconds.',
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.gray.shade700,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Compared to yesterday, you feel:',
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.gray.shade900,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: List.generate(_moods.length, (index) {
              final selected = _selectedMood == index;
              return ChoiceChip(
                label: Text(_moods[index]),
                selected: selected,
                onSelected: (_) => setState(() => _selectedMood = index),
                selectedColor: AppColors.purple.shade100,
                backgroundColor: AppColors.gray.shade100,
                side: BorderSide(
                  color: selected ? AppColors.purple : AppColors.gray.shade200,
                ),
                labelStyle: textTheme.bodyMedium?.copyWith(
                  color: selected ? AppColors.purple : AppColors.gray.shade800,
                  fontWeight: FontWeight.w600,
                ),
              );
            }),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Symptom intensity (1-10): ${_symptomIntensity.toInt()}',
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.gray.shade900,
              fontWeight: FontWeight.w600,
            ),
          ),
          Slider(
            value: _symptomIntensity,
            min: 1,
            max: 10,
            divisions: 9,
            activeColor: AppColors.purple,
            inactiveColor: AppColors.gray.shade200,
            label: _symptomIntensity.toStringAsFixed(0),
            onChanged: (value) => setState(() => _symptomIntensity = value),
          ),
          const SizedBox(height: AppSpacing.sm),
          _taskSwitch(
            textTheme,
            label: 'Hydration target completed',
            value: _hydrationDone,
            onChanged: (value) => setState(() => _hydrationDone = value),
          ),
          _taskSwitch(
            textTheme,
            label: 'Medication taken on time',
            value: _medicationDone,
            onChanged: (value) => setState(() => _medicationDone = value),
          ),
          _taskSwitch(
            textTheme,
            label: 'Recovery rest scheduled',
            value: _restDone,
            onChanged: (value) => setState(() => _restDone = value),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightPanel(TextTheme textTheme, double width) {
    final trend = [42.0, 48.0, 45.0, 58.0, 60.0, 54.0, _riskScore];

    return Container(
      width: width,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.gray.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Risk Signal',
            style: textTheme.headlineSmall?.copyWith(
              color: AppColors.gray.shade900,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              SizedBox(
                width: 112,
                height: 112,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: _riskScore / 100,
                      strokeWidth: 10,
                      backgroundColor: AppColors.gray.shade200,
                      color: AppColors.purple,
                    ),
                    Text(
                      _riskScore.toStringAsFixed(0),
                      style: textTheme.titleLarge?.copyWith(
                        color: AppColors.gray.shade900,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: _riskColor,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Text(
                    'Current risk band: $_riskLabel',
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.gray.shade900,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: _riskColor,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.gray.shade200),
            ),
            child: Text(
              _coachMessage,
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.gray.shade900,
                fontWeight: FontWeight.w600,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            '7-day progression',
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.gray.shade900,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: trend.map((value) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Container(
                    height: value,
                    decoration: BoxDecoration(
                      color: value == trend.last
                          ? AppColors.purple
                          : AppColors.purple.shade100,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCapabilities(TextTheme textTheme, double contentWidth) {
    final features = [
      _CoachFeature(
        icon: Icons.notifications_active_outlined,
        title: 'Smart Escalation',
        body:
            'Detects worsening trends across check-ins and pushes timely guidance.',
      ),
      _CoachFeature(
        icon: Icons.route_outlined,
        title: 'Adaptive Daily Plan',
        body:
            'Auto-adjusts care tasks based on symptom changes and user adherence.',
      ),
      _CoachFeature(
        icon: Icons.chat_bubble_outline,
        title: 'Context-Aware Coach Notes',
        body:
            'Turns risk signals into plain-language next actions for each day.',
      ),
      _CoachFeature(
        icon: Icons.summarize_outlined,
        title: 'Visit Prep Snapshot',
        body:
            'Compiles symptom history and actions into a doctor-ready summary.',
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.xxl,
      ),
      child: Center(
        child: SizedBox(
          width: contentWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Feature Modules',
                style: textTheme.titleLarge?.copyWith(
                  color: AppColors.gray.shade900,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final cardWidth = width < 900
                      ? width
                      : (width - AppSpacing.md) / 2;
                  return Wrap(
                    spacing: AppSpacing.md,
                    runSpacing: AppSpacing.md,
                    children: features
                        .map(
                          (feature) => _featureCard(
                            textTheme,
                            width: cardWidth,
                            feature: feature,
                          ),
                        )
                        .toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCarePathTimeline(TextTheme textTheme, double contentWidth) {
    final steps = [
      _CarePathStep(
        step: '01',
        title: 'Check-In',
        body: 'You report mood trend and symptom intensity.',
      ),
      _CarePathStep(
        step: '02',
        title: 'Risk Recalculation',
        body: 'Coach updates risk band from your latest signals.',
      ),
      _CarePathStep(
        step: '03',
        title: 'Action Plan',
        body: 'You receive a clear next step and reminder window.',
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.xxl,
      ),
      child: Center(
        child: SizedBox(
          width: contentWidth,
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              color: AppColors.gray.shade100,
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(color: AppColors.gray.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'How Care Coach Works Daily',
                  style: textTheme.titleLarge?.copyWith(
                    color: AppColors.gray.shade900,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final oneColumn = constraints.maxWidth < 980;
                    final itemWidth = oneColumn
                        ? constraints.maxWidth
                        : (constraints.maxWidth - AppSpacing.md * 2) / 3;

                    return Wrap(
                      spacing: AppSpacing.md,
                      runSpacing: AppSpacing.md,
                      children: steps
                          .map(
                            (step) => Container(
                              width: itemWidth,
                              padding: const EdgeInsets.all(AppSpacing.md),
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(
                                  AppRadius.lg,
                                ),
                                border: Border.all(
                                  color: AppColors.gray.shade200,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.sm,
                                      vertical: AppSpacing.xs,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.purple.shade100,
                                      borderRadius: BorderRadius.circular(
                                        AppRadius.md,
                                      ),
                                    ),
                                    child: Text(
                                      step.step,
                                      style: textTheme.labelLarge?.copyWith(
                                        color: AppColors.purple,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  Text(
                                    step.title,
                                    style: textTheme.titleSmall?.copyWith(
                                      color: AppColors.gray.shade900,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(
                                    step.body,
                                    style: textTheme.bodyMedium?.copyWith(
                                      color: AppColors.gray.shade700,
                                      height: 1.55,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _heroChip(TextTheme textTheme, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.gray.shade200),
      ),
      child: Text(
        label,
        style: textTheme.bodyMedium?.copyWith(
          color: AppColors.gray.shade800,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _metricCard(
    TextTheme textTheme, {
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.gray.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.purple),
          const SizedBox(height: AppSpacing.xs),
          Text(
            title,
            style: textTheme.titleSmall?.copyWith(
              color: AppColors.gray.shade900,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            subtitle,
            style: textTheme.bodySmall?.copyWith(
              color: AppColors.gray.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _taskSwitch(
    TextTheme textTheme, {
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      value: value,
      onChanged: onChanged,
      activeThumbColor: AppColors.purple,
      title: Text(
        label,
        style: textTheme.bodyMedium?.copyWith(
          color: AppColors.gray.shade800,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _featureCard(
    TextTheme textTheme, {
    required double width,
    required _CoachFeature feature,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.gray.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.purple.shade100,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(feature.icon, color: AppColors.purple, size: 22),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            feature.title,
            style: textTheme.titleSmall?.copyWith(
              color: AppColors.gray.shade900,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            feature.body,
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.gray.shade700,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _glow(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [BoxShadow(color: color, blurRadius: 80, spreadRadius: 10)],
      ),
    );
  }
}

class _CoachFeature {
  const _CoachFeature({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;
}

class _CarePathStep {
  const _CarePathStep({
    required this.step,
    required this.title,
    required this.body,
  });

  final String step;
  final String title;
  final String body;
}

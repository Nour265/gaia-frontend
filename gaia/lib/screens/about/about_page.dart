import 'package:flutter/material.dart';
import 'package:gaia/app/routes.dart';
import 'package:gaia/values/values.dart';
import 'package:gaia/widgets/navbar.dart';
import 'package:gaia/widgets/sections/footer.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.white,
      extendBodyBehindAppBar: false,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(72.0),
        child: Container(
          color: AppColors.white,
          child: Center(
            child: SizedBox(
              width: size.width * 0.7,
              child: const NavBar(),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHero(context, size, textTheme),
            _buildHighlights(size, textTheme),
            _buildFeatureSection(size, textTheme),
            _buildHowItWorks(size, textTheme),
            _buildTrustSection(size, textTheme),
            _buildFaqSection(size, textTheme),
            const Footer(),
          ],
        ),
      ),
    );
  }

  Widget _buildHero(
    BuildContext context,
    Size size,
    TextTheme textTheme,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 84),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.white,
            AppColors.gray.shade100,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -80,
            top: -40,
            child: _glowBubble(
              color: AppColors.purple.withOpacity(0.18),
              size: 220,
            ),
          ),
          Positioned(
            left: -60,
            bottom: -80,
            child: _glowBubble(
              color: AppColors.turquoise.withOpacity(0.18),
              size: 200,
            ),
          ),
          Positioned(
            right: 140,
            bottom: -30,
            child: _glowBubble(
              color: AppColors.orange.withOpacity(0.16),
              size: 140,
            ),
          ),
          Center(
            child: SizedBox(
              width: size.width * 0.7,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _eyebrow(
                          'Our Mission',
                          textTheme,
                          color: AppColors.gray.shade700,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'About GAIA',
                          style: textTheme.displayMedium?.copyWith(
                            height: 1.05,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'GAIA is a privacy-first symptom checker built to help you '
                          'understand what your symptoms could mean and what to do next.',
                          style: textTheme.bodyLarge?.copyWith(
                            color: AppColors.gray.shade800,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            _pill(textTheme, 'Fast guidance'),
                            _pill(textTheme, 'Evidence-informed'),
                            _pill(textTheme, 'Private by design'),
                            _pill(textTheme, 'Clear next steps'),
                          ],
                        ),
                        const SizedBox(height: 28),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
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
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  elevation: 0,
                                ),
                                child: Text(
                                  'Start Symptom Check',
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
                                onPressed: () {
                                  Navigator.pushNamed(
                                    context,
                                    Routes.landing,
                                  );
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.gray.shade900,
                                  side: BorderSide(
                                    color: AppColors.gray.shade300,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: Text(
                                  'Back to Home',
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
                  const SizedBox(width: 32),
                  Expanded(
                    flex: 2,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.purple.shade100,
                              AppColors.turquoise.shade100,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(26),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.purple.shade100,
                              blurRadius: 30,
                              offset: const Offset(0, 18),
                            ),
                          ],
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: Image.asset(
                            ImagePath.consult,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
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

  Widget _buildHighlights(Size size, TextTheme textTheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border(
          top: BorderSide(color: AppColors.gray.shade200),
          bottom: BorderSide(color: AppColors.gray.shade200),
        ),
      ),
      child: Center(
        child: SizedBox(
          width: size.width * 0.7,
          child: Wrap(
            spacing: 24,
            runSpacing: 16,
            alignment: WrapAlignment.spaceBetween,
            children: [
              _statTile(
                textTheme,
                icon: Icons.schedule,
                title: '24/7',
                body: 'Always-on guidance',
              ),
              _statTile(
                textTheme,
                icon: Icons.verified_user_outlined,
                title: 'Privacy',
                body: 'Built for confidentiality',
              ),
              _statTile(
                textTheme,
                icon: Icons.bolt,
                title: '< 2 min',
                body: 'Fast symptom checks',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureSection(Size size, TextTheme textTheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 72),
      color: AppColors.turquoise,
      child: Center(
        child: SizedBox(
          width: size.width * 0.7,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionHeaderWithColors(
                'Features',
                'What GAIA Helps You Do',
                textTheme,
                titleColor: AppColors.white,
                accentColor: AppColors.white,
                eyebrowColor: AppColors.white.withOpacity(0.85),
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 20,
                runSpacing: 20,
                children: [
                  _featureCard(
                    textTheme,
                    icon: Icons.medical_services,
                    title: 'Symptom triage',
                    body:
                        'Answer a few targeted questions to understand urgency.',
                  ),
                  _featureCard(
                    textTheme,
                    icon: Icons.lightbulb_outline,
                    title: 'Actionable guidance',
                    body:
                        'Get clear next steps: self-care, clinic, or urgent care.',
                  ),
                  _featureCard(
                    textTheme,
                    icon: Icons.timeline,
                    title: 'Track patterns',
                    body:
                        'Capture symptom duration and severity to see trends.',
                  ),
                  _featureCard(
                    textTheme,
                    icon: Icons.health_and_safety,
                    title: 'Safety checks',
                    body:
                        'Highlights red-flag symptoms that need faster attention.',
                  ),
                  _featureCard(
                    textTheme,
                    icon: Icons.lock_outline,
                    title: 'Privacy-first',
                    body:
                        'Your inputs stay private and are used only to help you.',
                  ),
                  _featureCard(
                    textTheme,
                    icon: Icons.support_agent,
                    title: 'Support-ready',
                    body:
                        'Built to fit real life decisions, not just a diagnosis.',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHowItWorks(Size size, TextTheme textTheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 72),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.gray.shade100,
            AppColors.white,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Center(
        child: SizedBox(
          width: size.width * 0.7,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionHeader('Workflow', 'How It Works', textTheme),
              const SizedBox(height: 24),
              Wrap(
                spacing: 24,
                runSpacing: 24,
                children: [
                  _stepCard(
                    textTheme,
                    step: '01',
                    title: 'Tell us what you feel',
                    body: 'Select symptoms, severity, and duration.',
                  ),
                  _stepCard(
                    textTheme,
                    step: '02',
                    title: 'We analyze safely',
                    body: 'GAIA weighs risk factors and known patterns.',
                  ),
                  _stepCard(
                    textTheme,
                    step: '03',
                    title: 'Get clear next steps',
                    body: 'You receive simple guidance and safety notes.',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrustSection(Size size, TextTheme textTheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 72),
      child: Center(
        child: SizedBox(
          width: size.width * 0.7,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionHeader(
                'Safety',
                'Safety, Ethics, and Transparency',
                textTheme,
              ),
              const SizedBox(height: 16),
              Text(
                'GAIA does not provide a medical diagnosis. It is a decision-support tool '
                'that helps you understand whether to seek care and how urgently.',
                style: textTheme.bodyLarge?.copyWith(
                  color: AppColors.gray.shade800,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 20,
                runSpacing: 20,
                children: [
                  _infoCard(
                    textTheme,
                    title: 'Responsible use',
                    body:
                        'Always seek professional help if symptoms feel severe or unusual.',
                  ),
                  _infoCard(
                    textTheme,
                    title: 'Privacy by design',
                    body:
                        'We minimize data collection and avoid unnecessary storage.',
                  ),
                  _infoCard(
                    textTheme,
                    title: 'Transparent guidance',
                    body:
                        'We explain next steps so you can act confidently.',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFaqSection(Size size, TextTheme textTheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 72),
      color: AppColors.turquoise,
      child: Center(
        child: SizedBox(
          width: size.width * 0.7,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionHeaderWithColors(
                'FAQ',
                'Frequently Asked Questions',
                textTheme,
                titleColor: AppColors.white,
                accentColor: AppColors.white,
                eyebrowColor: AppColors.white.withOpacity(0.85),
              ),
              const SizedBox(height: 20),
              _FaqItem(
                textTheme: textTheme,
                question: 'Is GAIA a medical diagnosis tool?',
                answer:
                    'No. GAIA provides decision-support guidance, not a medical diagnosis.',
              ),
              const SizedBox(height: 12),
              _FaqItem(
                textTheme: textTheme,
                question: 'How does GAIA decide urgency?',
                answer:
                    'It looks at symptom severity, duration, and risk patterns to suggest next steps.',
              ),
              const SizedBox(height: 12),
              _FaqItem(
                textTheme: textTheme,
                question: 'Is my data stored?',
                answer:
                    'GAIA is built to minimize data collection. Only essential inputs are used to help you.',
              ),
              const SizedBox(height: 12),
              _FaqItem(
                textTheme: textTheme,
                question: 'When should I seek professional care?',
                answer:
                    'If symptoms feel severe, unusual, or rapidly worsening, seek professional care.',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String label, String title, TextTheme textTheme) {
    return _sectionHeaderWithColors(
      label,
      title,
      textTheme,
      titleColor: AppColors.gray.shade900,
      accentColor: AppColors.purple,
      eyebrowColor: AppColors.gray.shade700,
    );
  }

  Widget _sectionHeaderWithColors(
    String label,
    String title,
    TextTheme textTheme, {
    required Color titleColor,
    required Color accentColor,
    required Color eyebrowColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _eyebrow(label, textTheme, color: eyebrowColor),
        const SizedBox(height: 8),
        Text(
          title,
          style: textTheme.titleLarge?.copyWith(
            color: titleColor,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          height: 3,
          width: 56,
          decoration: BoxDecoration(
            color: accentColor,
            borderRadius: BorderRadius.circular(99),
          ),
        ),
      ],
    );
  }

  Widget _eyebrow(String label, TextTheme textTheme, {required Color color}) {
    return Text(
      label.toUpperCase(),
      style: textTheme.labelLarge?.copyWith(
        color: color,
        letterSpacing: 2,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _pill(TextTheme textTheme, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.purple.shade100,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: textTheme.labelLarge?.copyWith(
          color: AppColors.purple,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _featureCard(
    TextTheme textTheme, {
    required IconData icon,
    required String title,
    required String body,
  }) {
    return Container(
      width: 240,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.gray.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.purple.shade100,
                  AppColors.turquoise.shade100,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppColors.purple, size: 22),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: textTheme.titleSmall?.copyWith(
              color: AppColors.gray.shade900,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: textTheme.bodySmall?.copyWith(
              color: AppColors.gray.shade700,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepCard(
    TextTheme textTheme, {
    required String step,
    required String title,
    required String body,
  }) {
    return Container(
      width: 260,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.gray.shade200),
        boxShadow: [
          BoxShadow(
            color: AppColors.gray.shade200,
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.purple.shade100,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              step,
              style: textTheme.labelLarge?.copyWith(
                color: AppColors.purple,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: textTheme.titleSmall?.copyWith(
              color: AppColors.gray.shade900,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: textTheme.bodySmall?.copyWith(
              color: AppColors.gray.shade700,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard(
    TextTheme textTheme, {
    required String title,
    required String body,
  }) {
    return Container(
      width: 260,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.gray.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gray.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: textTheme.titleSmall?.copyWith(
              color: AppColors.gray.shade900,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: textTheme.bodySmall?.copyWith(
              color: AppColors.gray.shade700,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statTile(
    TextTheme textTheme, {
    required IconData icon,
    required String title,
    required String body,
  }) {
    return Container(
      width: 220,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.gray.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.purple.shade100,
                  AppColors.turquoise.shade100,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.purple, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: textTheme.titleSmall?.copyWith(
                  color: AppColors.gray.shade900,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                body,
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.gray.shade700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _glowBubble({required Color color, required double size}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: color,
            blurRadius: 60,
            spreadRadius: 10,
          ),
        ],
      ),
    );
  }
}

class _FaqItem extends StatefulWidget {
  const _FaqItem({
    required this.textTheme,
    required this.question,
    required this.answer,
  });

  final TextTheme textTheme;
  final String question;
  final String answer;

  @override
  State<_FaqItem> createState() => _FaqItemState();
}

class _FaqItemState extends State<_FaqItem> with SingleTickerProviderStateMixin {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final titleStyle = widget.textTheme.titleSmall ??
        const TextStyle(fontSize: 16, fontWeight: FontWeight.w700);
    final labelStyle = widget.textTheme.labelLarge ??
        const TextStyle(fontSize: 12, fontWeight: FontWeight.w700);
    final bodyStyle = widget.textTheme.bodyMedium ??
        const TextStyle(fontSize: 14, fontWeight: FontWeight.w600);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.gray.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.question,
                      style: titleStyle.copyWith(
                        color: AppColors.gray.shade900,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 160),
                    curve: Curves.easeOut,
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppColors.purple,
                    ),
                  ),
                ],
              ),
            ),
          ),
          ClipRect(
            child: AnimatedSize(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: _expanded
                    ? const BoxConstraints()
                    : const BoxConstraints(maxHeight: 0),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Divider(color: AppColors.gray.shade200, height: 16),
                      Text(
                        'Answer',
                        style: labelStyle.copyWith(
                          color: AppColors.gray.shade700,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.answer,
                        style: bodyStyle.copyWith(
                          color: AppColors.gray.shade900,
                          height: 1.6,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

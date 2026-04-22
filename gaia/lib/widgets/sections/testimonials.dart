import 'package:flutter/material.dart';
import 'package:gaia/app/theme.dart';
import 'package:gaia/values/values.dart';

class Testimonials extends StatelessWidget {
  const Testimonials({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 700;
    final contentWidth = size.width < 980 ? size.width * 0.9 : size.width * 0.7;

    final stepCards = [
      Testimony(
        steptitle: 'Step 1 - Input Symptoms',
        message:
            'Enter what you feel using simple guided questions. GAIA collects relevant information without medical jargon.',
      ),
      Testimony(
        steptitle: 'Step 2 - Intelligent Evaluation',
        message:
            'Our decision-support logic analyzes patterns, severity, and risk indicators to assess your situation.',
      ),
      Testimony(
        steptitle: 'Step 3 - Clear Recommendations',
        message:
            'Receive understandable guidance such as self-care, monitoring, or seeking professional medical attention.',
      ),
    ];

    return Container(
      width: double.infinity,
      color: AppColors.turquoise,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
      child: Center(
        child: SizedBox(
          width: contentWidth,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 980;
              final cardHeight = isWide ? 256.0 : 248.0;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'How GAIA Guides You',
                    style: (isMobile ? textTheme.headlineLarge : textTheme.displayMedium)
                        ?.copyWith(color: AppColors.white),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Clear, step-by-step guidance from symptoms to action.',
                    style: lead1.copyWith(color: AppColors.white),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  if (!isWide)
                    Column(
                      children: stepCards
                          .map(
                            (step) => Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppSpacing.md,
                              ),
                              child: SizedBox(
                                width: double.infinity,
                                height: cardHeight,
                                child: step,
                              ),
                            ),
                          )
                          .toList(),
                    )
                  else
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: cardHeight,
                            child: stepCards[0],
                          ),
                        ),
                        const _StepConnector(),
                        Expanded(
                          child: SizedBox(
                            height: cardHeight,
                            child: stepCards[1],
                          ),
                        ),
                        const _StepConnector(),
                        Expanded(
                          child: SizedBox(
                            height: cardHeight,
                            child: stepCards[2],
                          ),
                        ),
                      ],
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class Testimony extends StatelessWidget {
  const Testimony({
    Key? key,
    required this.message,
    required this.steptitle,
    this.width,
    this.height,
  }) : super(key: key);

  final String message;
  final String steptitle;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(steptitle, style: textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          Text(
            message,
            style: lead1.copyWith(
              fontSize: 15,
              color: AppColors.gray.shade800,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _StepConnector extends StatelessWidget {
  const _StepConnector();

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Icon(
        Icons.arrow_forward_rounded,
        color: AppColors.white,
        size: 26,
      ),
    );
  }
}

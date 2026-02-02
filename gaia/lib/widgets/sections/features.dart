import 'package:flutter/material.dart';
import 'package:gaia/app/theme.dart';
import 'package:gaia/values/values.dart';

class Features extends StatelessWidget {
  const Features({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final size = MediaQuery.of(context).size;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 60),
            Text('Why GAIA?', style: textTheme.displayMedium),
            const SizedBox(height: 20),
            Text(
              'GAIA is an intelligent symptom checker built for decision support.',
              style: lead1,
            ),
            const SizedBox(height: 8),
            Text(
              'It helps users understand symptoms and choose the right level of care—responsibly.',
              style: lead1,
            ),
            const SizedBox(height: 48),
            Wrap(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: FeatureItem(
                    width: size.width / 4,
                    icon: Image.asset(ImagePath.featureIcon1),
                    title: 'Symptom-to-Guidance Flow',
                    description: 'A structured step-by-step wizard collects symptoms and provides clear next-step guidance.',
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: FeatureItem(
                    width: size.width / 4,
                    icon: Image.asset(ImagePath.featureIcon2),
                    title: 'Personalized Recommendations',
                    description: 'Recommendations adapt to user inputs such as symptom severity, duration, and key risk factors.',
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: FeatureItem(
                    width: size.width / 4,
                    icon: Image.asset(ImagePath.featureIcon3),
                    title: 'Clear and Simple UI',
                    description: 'Designed to be easy to use, with plain language explanations and a calm medical interface.',
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: FeatureItem(
                    width: size.width / 4,
                    icon: Image.asset(ImagePath.featureIcon4),
                    title: 'Multiple Entry Paths',
                    description: 'Users can start from symptoms, body area, or common complaints for faster navigation.',
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: FeatureItem(
                    width: size.width / 4,
                    icon: Image.asset(ImagePath.featureIcon5),
                    title: 'AI-Assisted Decision Support',
                    description: 'Machine learning supports consistent triage suggestions, while keeping safety rules in place.',
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: FeatureItem(
                    width: size.width / 4,
                    icon: Image.asset(ImagePath.featureIcon6),
                    title: 'Safety and Disclaimer Built-in',
                    description: 'GAIA emphasizes that it is not a diagnosis and highlights urgent-care scenarios when needed.',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 60),
          ],
        ),
      ],
    );
  }
}

class FeatureItem extends StatelessWidget {
  const FeatureItem({
    Key? key,
    required this.icon,
    required this.title,
    required this.description,
    this.width,
    this.height,
  }) : super(key: key);

  final String title;
  final Widget icon;
  final String description;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SizedBox(
      width: width,
      height: height,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon,
          const SizedBox(height: 24),
          Text(title, style: textTheme.headlineSmall),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              description,
              textAlign: TextAlign.center,
              style: textTheme.bodyLarge,
            ),
          ),
        ],
      ),
    );
  }
}
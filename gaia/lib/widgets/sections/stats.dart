import 'package:flutter/material.dart';
import 'package:gaia/app/theme.dart';
import 'package:gaia/values/values.dart';

class Stats extends StatelessWidget {
  const Stats({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final size = MediaQuery.of(context).size;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 80.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size.width / 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Trusted Healthcare Guidance, Backed by Data',
                  style: textTheme.displayMedium,
                ),
                const SizedBox(height: 8),
                Text('Helping people make safer health decisions every day.', style: lead1),

                   
              ],
            ),
          ),
          const SizedBox(width: 30),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  StatsSegment(
                    icon: ImagePath.featureIcon1,
                    title: '250,000+',
                    subtitle: 'Checks Completed         ',
                  ),
                  SizedBox(width: 30),
                  StatsSegment(
                    icon: ImagePath.featureIcon4,
                    title: '92%',
                    subtitle: 'User Satisfaction',
                  ),
                ],
              ),
              const SizedBox(height: 40),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  StatsSegment(
                    icon: ImagePath.featureIcon5,
                    title: '< 30s',
                    subtitle: 'Response Time',
                  ),
                  SizedBox(width: 90),
                  StatsSegment(
                    icon: ImagePath.featureIcon7,
                    title: '24/7',
                    subtitle: 'Availability',
                  ),
                ],
              ),
            ],
          )
        ],
      ),
    );
  }
}

class StatsSegment extends StatelessWidget {
  const StatsSegment({
    Key? key,
    required this.icon,
    required this.title,
    required this.subtitle,
  }) : super(key: key);

  final String icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(icon),
        const SizedBox(width: 16),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: textTheme.headlineMedium),
            Text(subtitle, style: textTheme.bodyLarge),
          ],
        ),
      ],
    );
  }
}
import 'package:flutter/material.dart';
import 'package:gaia/app/routes.dart';
import 'package:gaia/values/values.dart';

class Footer extends StatelessWidget {
  const Footer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final textTheme = Theme.of(context).textTheme;
    final muted = AppColors.gray.shade300;
    final dim = AppColors.gray.shade700;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.black,
            AppColors.gray.shade900,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: SizedBox(
          width: size.width * 0.7,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 64),
            child: DefaultTextStyle.merge(
              style: textTheme.bodyMedium!.copyWith(color: AppColors.white),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Wrap(
                    spacing: 56,
                    runSpacing: 32,
                    alignment: WrapAlignment.spaceBetween,
                    children: [
                      SizedBox(
                        width: 300,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Image.asset(
                                  ImagePath.logo,
                                  width: 44,
                                  height: 44,
                                  fit: BoxFit.contain,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'GAIA',
                                  style: textTheme.titleMedium!.copyWith(
                                    color: AppColors.white,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Private, fast symptom guidance to help you decide your next step with confidence.',
                              style: textTheme.bodyMedium!.copyWith(
                                color: muted,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              height: 40,
                              child: OutlinedButton(
                                onPressed: () {
                                  Navigator.pushNamed(context, Routes.wizard);
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.white,
                                  side: const BorderSide(
                                    color: AppColors.purple,
                                    width: 1.4,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                  ),
                                ),
                                child: Text(
                                  'Start Symptom Check',
                                  style: textTheme.labelLarge?.copyWith(
                                    color: AppColors.white,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 180,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Navigate',
                              style: textTheme.titleSmall!.copyWith(
                                color: muted,
                                letterSpacing: 0.6,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _footerLink(
                              context,
                              label: 'About',
                              onTap: () {
                                Navigator.pushNamed(context, Routes.about);
                              },
                              color: dim,
                            ),
                            const SizedBox(height: 10),
                            Text('Contact', style: TextStyle(color: dim)),
                            const SizedBox(height: 10),
                            Text('Blog', style: TextStyle(color: dim)),
                            const SizedBox(height: 10),
                            Text('Resources', style: TextStyle(color: dim)),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 200,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Support',
                              style: textTheme.titleSmall!.copyWith(
                                color: muted,
                                letterSpacing: 0.6,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text('help@gaia.health', style: TextStyle(color: dim)),
                            const SizedBox(height: 10),
                            Text('Mon-Fri, 9am-6pm', style: TextStyle(color: dim)),
                            const SizedBox(height: 10),
                            Text('Response within 24h', style: TextStyle(color: dim)),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 200,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Legal',
                              style: textTheme.titleSmall!.copyWith(
                                color: muted,
                                letterSpacing: 0.6,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text('Privacy Policy', style: TextStyle(color: dim)),
                            const SizedBox(height: 10),
                            Text('Terms of Use', style: TextStyle(color: dim)),
                            const SizedBox(height: 10),
                            Text('Data Protection', style: TextStyle(color: dim)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  Container(height: 1, color: AppColors.gray.shade800),
                  const SizedBox(height: 20),
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    runSpacing: 8,
                    children: [
                      Text(
                        '(c) 2026 GAIA. All rights reserved',
                        style: textTheme.bodySmall!.copyWith(color: muted),
                      ),
                      Text(
                        'Decision-support only - not medical advice.',
                        style: textTheme.bodySmall!.copyWith(color: muted),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _footerLink(
    BuildContext context, {
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Text(label, style: TextStyle(color: color)),
      ),
    );
  }
}

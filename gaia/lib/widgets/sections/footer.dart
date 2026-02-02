import 'package:flutter/material.dart';
import 'package:gaia/values/values.dart';

class Footer extends StatelessWidget {
  const Footer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      color: AppColors.black,
      child: Center(
        child: SizedBox(
          width: size.width * 0.7,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 56),
            child: DefaultTextStyle.merge(
              style: textTheme.bodyLarge!.copyWith(color: AppColors.white),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Image.asset(
                              ImagePath.logo,
                              width: 100,   // change this number until it looks right
                              height: 100,  // optional
                              fit: BoxFit.contain,
                            ),

                      const SizedBox(height: 24),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Text('Download Now'),
                          SizedBox(width: 24),
                          Text('License'),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Text('About'),
                          SizedBox(width: 24),
                          Text('Features'),
                          SizedBox(width: 24),
                          Text('Pricing'),
                          SizedBox(width: 24),
                          Text('Help'),
                          SizedBox(width: 24),
                          Text('Privacy Policy'),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text(
                        '© 2026 GAIA. All rights reserved',
                        style: textTheme.bodyMedium!.copyWith(
                          color: AppColors.gray.shade300,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Get the App',
                        style: textTheme.titleSmall!.copyWith(
                          color: AppColors.gray.shade300,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Image.asset(ImagePath.appStore),
                      const SizedBox(height: 16),
                      Image.asset(ImagePath.googlePlay),
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
}
import 'package:flutter/material.dart';
import 'package:gaia/app/routes.dart';
import 'package:gaia/values/values.dart';

class Heros extends StatelessWidget {
  const Heros({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 700;

    final double mockupWidth = size.width * 0.36;
    final double mockupDown = 90;
    final double mockupRightPadding = 24;

    final contentWidth = isMobile ? size.width - 32 : size.width * 0.7;

    return Container(
      width: size.width,
      height: isMobile ? size.height * 0.55 : size.height * 0.7,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage(ImagePath.background),
          fit: BoxFit.cover,
        ),
      ),
      child: Column(
        children: [
          SizedBox(height: isMobile ? 48 : 90),
          SizedBox(
            width: contentWidth,
            child: isMobile
                ? _buildContent(context, textTheme)
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: _buildContent(context, textTheme),
                      ),
                      SizedBox(width: size.width * 0.02),
                      Expanded(
                        flex: 2,
                        child: Padding(
                          padding: EdgeInsets.only(right: mockupRightPadding),
                          child: Align(
                            alignment: Alignment.topRight,
                            child: Transform.translate(
                              offset: Offset(0, mockupDown),
                              child: SizedBox(
                                width: mockupWidth,
                                child: Image.asset(
                                  ImagePath.desktop,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
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

  Column _buildContent(BuildContext context, TextTheme textTheme) {
    // If your text is too big, change displayLarge to displayMedium (or apply copyWith(fontSize: ...))
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 90),
        Text('Your Health.', style: textTheme.displayMedium),
        const SizedBox(height: 24),
        Text('Our Priority.', style: textTheme.displayMedium),
        const SizedBox(height: 40),
        TextButton(
          onPressed: () {
            Navigator.pushNamed(context, Routes.wizard);
          },
          style: TextButton.styleFrom(
            foregroundColor: AppColors.white,
            backgroundColor: AppColors.purple,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          child: Text(
            'Get Started',
            style: textTheme.titleSmall!.copyWith(color: AppColors.white),
          ),
        ),
      ],
    );
  }
}

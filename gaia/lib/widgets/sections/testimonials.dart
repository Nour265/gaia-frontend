import 'package:flutter/material.dart';
import 'package:gaia/app/theme.dart';
import 'package:gaia/values/values.dart';

class Testimonials extends StatelessWidget {
  const Testimonials({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      height: size.height - 100,
      color: AppColors.turquoise,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Align(
            alignment: const Alignment(-0.57, -0.75),
            child: Image.asset(ImagePath.quoteMark),
          ),
          Align(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'How GAIA Guides You',
                      style: textTheme.displayMedium,
                    ),
                    const SizedBox(height: 8),
                    Text('Clear, step-by-step guidance from symptoms to action.', style: lead1),
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.only(left: 150),
                      child: Testimony(
                        width: size.width * 0.17,
                        icon: ImagePath.symptomsLogo,
                        steptitle: 'Step 1 - Input Symptoms',
                        message:
                            'Enter what you feel using simple guided questions. GAIA collects relevant information without medical jargon.',
                       
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 30),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Testimony(
                      width: size.width * 0.22,
                      icon: ImagePath.brain,
                      steptitle: 'Step 2 - Intelligent Evaluation',
                      message: 'Our decision-support logic analyzes patterns, severity, and risk indicators to assess your situation.',
                     
                    ),
                    const SizedBox(height: 30),
                    Testimony(
                      width: size.width * 0.17,
                      icon: ImagePath.check,
                      steptitle: 'Step 3 - Clear Recommendations',
                      message: 'Receive understandable guidance such as self-care, monitoring, or seeking professional medical attention.',
                      
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

class Testimony extends StatelessWidget {
  const Testimony({
    Key? key,
    required this.icon,
    required this.message,
    required this.steptitle,
    
    this.width,
    this.height,
  }) : super(key: key);

  final String icon;
  final String message;
  final String steptitle;
 
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: width,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
         
          
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Flexible(
                  child: Image.asset(
                    ImagePath.quoteMark,
                    width: 16,
                    height: 14,
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: width != null ? width! * 0.7 : 100,
                  child: Text(
                    message,
                    softWrap: true,
                    style: lead1.copyWith(
                      letterSpacing: 1.0,
                      height: 1.2,
                    ),
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.only(left: 30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(steptitle, style: textTheme.titleMedium),
                
              ],
            ),
          ),
        ],
      ),
    );
  }
}
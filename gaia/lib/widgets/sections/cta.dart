

import 'package:flutter/material.dart';
import 'package:gaia/app/theme.dart';
import 'package:gaia/values/values.dart';

class Cta extends StatelessWidget {
  const Cta({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Screen size (used to compute responsive widths)
    final size = MediaQuery.of(context).size;

    // Text styles from your global theme
    final textTheme = Theme.of(context).textTheme;

    // CTA content width (same pattern you used elsewhere: 70% of screen)
    final ctaWidth = size.width * 0.7;

    return Container(
      width: double.infinity,


      padding: const EdgeInsets.symmetric(vertical: 80),

    
      color: AppColors.turquoise,

      child: Center(
        child: SizedBox(
          width: ctaWidth,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
 
              SizedBox(
                width: ctaWidth * 0.45,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Headline
                    Text(
                      'Check Your Symptoms with Confidence',
                      style: textTheme.displayMedium,
                      softWrap: true,
                    ),

                    const SizedBox(height: 12),

                    // Description
                    Text(
                      'GAIA helps you understand your symptoms and decide whether self-care or professional medical attention is needed. Fast, private, and available anytime.',
                      style: lead1,
                      softWrap: true,
                    ),

                    const SizedBox(height: 32),

                  

                    const SizedBox(height: 12),

                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () {
                          
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.purple,
                          foregroundColor: AppColors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 28),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
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

                    const SizedBox(height: 12),

                    
                    Text(
                      'Decision-support only — not a medical diagnosis.',
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.gray.shade800,
                      ),
                    ),
                  ],
                ),
              ),

             
              const Spacer(),

           
              SizedBox(
                width: ctaWidth * 0.45,
                child: Align(
                      alignment: Alignment.centerRight,
                      child: Transform.translate(
                        offset: const Offset(40, 0), // +x = right, +y = down
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight: size.height * 0.45,
                            maxWidth: ctaWidth * 0.45,
                          ),
                          child: Image.asset(
                            ImagePath.interaction,
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
    );
  }
}

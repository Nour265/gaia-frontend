import 'package:flutter/material.dart';
import 'package:gaia/values/values.dart';
import 'package:gaia/widgets/navbar.dart';
import 'package:gaia/widgets/sections/cta.dart';
import 'package:gaia/widgets/sections/features.dart';
import 'package:gaia/widgets/sections/footer.dart';
import 'package:gaia/widgets/sections/heros.dart';
import 'package:gaia/widgets/sections/stats.dart';
import 'package:gaia/widgets/sections/testimonials.dart';
import 'package:gaia/services/api_service.dart';

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.white,
      extendBodyBehindAppBar: false, // IMPORTANT
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(72.0),
        child: Container(
          color: AppColors.white, // keeps it white and non-overlapping
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
          mainAxisSize: MainAxisSize.min,
          children: [
            const Heros(),
            const Features(),
            const Testimonials(),
            const Stats(),
            const Cta(),

            // 🔽 THIS IS THE BACKEND TEST BUTTON 🔽
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32.0),
              child: ElevatedButton(
                onPressed: () async {
                  try {
                    final result = await ApiService.createAssessment(
                      age: 30,
                      gender: "male",
                      symptoms: [
                        {
                          "name": "fever",
                          "severity": 4,
                          "duration_days": 2
                        },
                        {
                          "name": "cough",
                          "severity": 2,
                          "duration_days": 5
                        },
                      ],
                    );

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            "Backend OK: ${result["risk_level"]}",
                          ),
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Backend Error: $e"),
                        ),
                      );
                    }
                  }
                },
                child: const Text("Test Backend"),
              ),
            ),
            // 🔼 END BACKEND TEST BUTTON 🔼

            const Footer(),
          ],
        ),
      ),
    );
  }
}
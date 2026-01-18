import 'package:flutter/material.dart';
import '../../app/routes.dart';

/// This widget represents the landing (home) page of the application.
/// It is the first screen the user sees when the app starts.
class LandingPage extends StatelessWidget {
  // const constructor because this widget does not change state
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Scaffold is the basic page layout structure in Flutter.
    // It provides:
    // - AppBar (top bar)
    // - Body (main content)
    // - Background color (from theme)
    return Scaffold(
      appBar: AppBar(
        // The title shown in the top bar
        title: const Text('GAIA'),

        // Centering the title looks cleaner on web and mobile
        centerTitle: true,
      ),

      // The body contains the main content of the screen
      body: Padding(
        // Padding adds space around the content so it doesn’t touch screen edges
        padding: const EdgeInsets.all(20.0),

        // Column means we stack widgets vertically
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Main title text
            const Text(
              'Check your symptoms.\nGet guidance.\nStay safe.',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            // Subtitle text
            const Text(
              'An intelligent decision-support tool that helps you understand '
              'whether professional medical care is recommended.',
              style: TextStyle(fontSize: 14),
            ),

            const SizedBox(height: 30),

            // Start button
            SizedBox(
              width: double.infinity, // makes the button stretch horizontally
              child: ElevatedButton(
                // When the user clicks the button, we navigate to the wizard screen
                onPressed: () {
                  Navigator.pushNamed(context, Routes.wizard);
                },
                child: const Text('Start Symptom Check'),
              ),
            ),

            const SizedBox(height: 12),

            // Secondary button to show About/Disclaimer
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pushNamed(context, Routes.about);
                },
                child: const Text('About & Disclaimer'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

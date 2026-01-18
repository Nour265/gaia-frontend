import 'package:flutter/material.dart';

/// This widget represents the About / Disclaimer screen.
/// It will explain:
/// - What GAIA is
/// - That it is not a medical diagnosis tool
/// - Ethical limitations
class AboutPage extends StatelessWidget {
  // const constructor because this widget has no state
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About & Disclaimer'),
        centerTitle: true,
      ),
      body: const Padding(
        padding: EdgeInsets.all(20.0),
        child: Text(
          'GAIA is an intelligent symptom checker designed to provide guidance '
          'and support decision making. It does not replace healthcare professionals '
          'and does not provide medical diagnosis.',
          style: TextStyle(fontSize: 14),
        ),
      ),
    );
  }
}

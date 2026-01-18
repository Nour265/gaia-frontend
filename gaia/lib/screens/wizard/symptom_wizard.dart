import 'package:flutter/material.dart';

/// This widget represents the Symptom Checking Wizard screen.
/// It will later contain the multi-step form for collecting user symptoms.
/// For now, it is a placeholder so routing works.
class SymptomWizard extends StatelessWidget {
  // const constructor because this widget does not hold any mutable state yet
  const SymptomWizard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Symptom Wizard'),
        centerTitle: true,
      ),
      body: const Center(
        // Temporary placeholder text
        child: Text(
          'Symptom Wizard Screen\n(Under Construction)',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}

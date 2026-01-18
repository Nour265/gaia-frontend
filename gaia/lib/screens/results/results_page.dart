import 'package:flutter/material.dart';

/// This widget represents the Results screen.
/// It will display:
/// - Risk level
/// - Possible conditions
/// - Recommendation
/// - Explanation
class ResultsPage extends StatelessWidget {
  // const constructor because this widget is static for now
  const ResultsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Results'),
        centerTitle: true,
      ),
      body: const Center(
        child: Text(
          'Results Screen\n(Under Construction)',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}

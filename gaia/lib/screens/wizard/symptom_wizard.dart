import 'package:flutter/material.dart';
import 'dart:developer' as dev;
class SymptomWizard extends StatefulWidget {
  const SymptomWizard({super.key});

  @override
  State<SymptomWizard> createState() => _SymptomWizardState();
}

class _SymptomWizardState extends State<SymptomWizard> {
  int _currentStep = 0;
  
  // Stores the selections for each step
  final Map<int, List<String>> _selections = {
    0: [], // Step 0 selections
    1: [], // Step 1 selections
    2: [], // Step 2 selections
  };

  final List<Map<String, dynamic>> _steps = [
    {
      'title': 'Primary Symptoms',
      'question': 'What are you feeling?',
      'options': ['Headache', 'Fever', 'Cough', 'Dry Throat', 'Fatigue'],
    },
    {
      'title': 'Severity',
      'question': 'How intense is the pain/discomfort?',
      'options': ['Mild', 'Moderate', 'Severe', 'Unbearable'],
    },
    {
      'title': 'Duration',
      'question': 'How long has this been going on?',
      'options': ['Few hours', '1-2 Days', '3-5 Days', 'Over a week'],
    },
  ];

  void _handleSelection(String option) {
    setState(() {
      if (_selections[_currentStep]!.contains(option)) {
        _selections[_currentStep]!.remove(option);
      } else {
        // For severity and duration, we might want single choice only:
        if (_currentStep > 0) _selections[_currentStep]!.clear(); 
        _selections[_currentStep]!.add(option);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // Pulls from your AppTheme.light()
    final currentStepData = _steps[_currentStep];

    return Scaffold(
      appBar: AppBar(
        title: Text(currentStepData['title']),
        // Back button logic
        leading: _currentStep > 0 
          ? IconButton(
              icon: const Icon(Icons.chevron_left), 
              onPressed: () => setState(() => _currentStep--)) 
          : null,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            // Progress Bar using your primaryColor
            LinearProgressIndicator(
              value: (_currentStep + 1) / _steps.length,
              backgroundColor: theme.primaryColor.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
              borderRadius: BorderRadius.circular(10),
            ),
            const SizedBox(height: 30),
            
            Text(currentStepData['question'], style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text("Select the most accurate options.", style: theme.textTheme.bodyMedium),
            const SizedBox(height: 24),

            // Options List
            Expanded(
              child: ListView(
                children: currentStepData['options'].map<Widget>((option) {
                  final isSelected = _selections[_currentStep]!.contains(option);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      onTap: () => _handleSelection(option),
                      borderRadius: BorderRadius.circular(16),
                      child: Card(
                        // The 'side' property belongs inside 'shape'
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16), // Keeps it consistent with your theme
                          side: BorderSide(
                            color: isSelected ? theme.primaryColor : Colors.transparent,
                            width: 2,
                        ),),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                          child: Row(
                            children: [
                              Icon(
                                isSelected ? Icons.check_circle : Icons.circle_outlined,
                                color: isSelected ? theme.primaryColor : const Color(0xFFCBD5E1),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                option,
                                style: TextStyle(
                                  color: isSelected ? theme.primaryColor : const Color(0xFF1E293B),
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            // Action Button
            Padding(
              padding: const EdgeInsets.only(bottom: 30, top: 10),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _selections[_currentStep]!.isEmpty 
                    ? null // Disable button if nothing is selected
                    : () {
                        if (_currentStep < _steps.length - 1) {
                          setState(() => _currentStep++);
                        } else {
                          dev.log('Collected Data: $_selections', name: 'SymptomWizard');
                        }
                      },
                  child: Text(_currentStep == _steps.length - 1 ? 'Finish Assessment' : 'Continue'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:gaia/values/values.dart'; 
import 'package:gaia/app/routes.dart';

class SymptomWizard extends StatefulWidget {
  const SymptomWizard({super.key});

  @override
  State<SymptomWizard> createState() => _SymptomWizardState();
}

class _SymptomWizardState extends State<SymptomWizard> {
  // Navigation history allows the user to go "Back" in a branching tree
  final List<String> _history = ['root'];
  
  // Collected symptoms to pass to the ResultsPage
  final Set<String> _finalSymptoms = {};

  // THE DECISION TREE
  // Built from your dataset clusters: Respiratory, GI, Neuro, and Musculoskeletal
  final Map<String, Map<String, dynamic>> _tree = {
    'root': {
      'question': 'What is the primary area of discomfort?',
      'subtitle': 'Select the most relevant category',
      'options': ['Chest & Breathing', 'Stomach & Digestion', 'Head & Neurological', 'Muscles & Skin'],
      'next': {
        'Chest & Breathing': 'resp_start',
        'Stomach & Digestion': 'gi_start',
        'Head & Neurological': 'neuro_start',
        'Muscles & Skin': 'body_start',
      }
    },
    
    // --- RESPIRATORY BRANCH ---
    'resp_start': {
      'question': 'Which of these is most prominent?',
      'subtitle': 'Focusing on chest and airways',
      'options': ['Shortness of breath', 'Cough', 'Chest Tightness', 'Sharp Chest Pain'],
      'next': {'Cough': 'cough_details', 'default': 'resp_severity'}
    },
    'cough_details': {
      'question': 'Tell me about the cough:',
      'subtitle': 'Check for secondary symptoms',
      'options': ['Coughing up sputum', 'Sore throat', 'Nasal congestion', 'Hoarse voice'],
      'next': {'default': 'resp_severity'}
    },
    'resp_severity': {
      'question': 'Any additional breathing issues?',
      'options': ['Wheezing', 'Difficulty breathing', 'Breathing fast', 'Painful sinuses'],
      'next': {'default': 'general_finish'}
    },

    // --- GASTROINTESTINAL BRANCH ---
    'gi_start': {
      'question': 'What best describes the stomach pain?',
      'subtitle': 'Select the closest match',
      'options': ['Sharp abdominal pain', 'Burning abdominal pain', 'Lower abdominal pain', 'Upper abdominal pain'],
      'next': {'default': 'gi_secondary'}
    },
    'gi_secondary': {
      'question': 'Are you experiencing these as well?',
      'options': ['Vomiting', 'Nausea', 'Stomach bloating', 'Heartburn'],
      'next': {'default': 'gi_finish'}
    },

    // --- NEUROLOGICAL BRANCH ---
    'neuro_start': {
      'question': 'Which neurological symptom is strongest?',
      'options': ['Headache', 'Dizziness', 'Fainting', 'Loss of sensation'],
      'next': {'Headache': 'headache_details', 'default': 'neuro_finish'}
    },
    'headache_details': {
      'question': 'Where is the headache located?',
      'options': ['Frontal headache', 'Throbbing/Migraine', 'Visual spots', 'Ache all over'],
      'next': {'default': 'neuro_finish'}
    },

    // --- MUSCLE & SKIN BRANCH ---
    'body_start': {
      'question': 'Where is the issue located?',
      'options': ['Back pain', 'Leg pain', 'Arm pain', 'Skin rash'],
      'next': {'Skin rash': 'skin_details', 'default': 'body_finish'}
    },
    'skin_details': {
      'question': 'Describe the skin changes:',
      'options': ['Itching of skin', 'Skin swelling', 'Skin lesion', 'Abnormal appearing skin'],
      'next': {'default': 'body_finish'}
    },

    // LEAF NODES (Exit points)
    'general_finish': {'question': 'Final check: Do you have a fever?', 'options': ['Fever', 'Chills', 'Sweating', 'No, none of these'], 'next': {'default': 'finish'}},
    'gi_finish': {'question': 'Any bowel changes?', 'options': ['Diarrhea', 'Constipation', 'Blood in stool', 'None'], 'next': {'default': 'finish'}},
    'neuro_finish': {'question': 'Any movement issues?', 'options': ['Weakness', 'Paresthesia', 'Seizures', 'None'], 'next': {'default': 'finish'}},
    'body_finish': {'question': 'How is your movement?', 'options': ['Joint pain', 'Stiffness/Tightness', 'Problems with movement', 'None'], 'next': {'default': 'finish'}},
  };

  void _handleChoice(String choice) {
    setState(() {
      _finalSymptoms.add(choice);
      String currentKey = _history.last;
      String nextNode = _tree[currentKey]?['next'][choice] ?? 
                        _tree[currentKey]?['next']['default'] ?? 
                        'finish';

      if (nextNode == 'finish' || _history.length >= 15) {
        // Navigate to results and pass the list of symptoms collected along the path
        Navigator.pushNamed(context, Routes.results, arguments: _finalSymptoms.toList());
      } else {
        _history.add(nextNode);
      }
    });
  }

  void _prevStep() {
    if (_history.length > 1) {
      setState(() {
        _history.removeLast();
        // We keep the symptoms in the set for now, or you could implement logic to remove the last one
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final activeColor = theme.colorScheme.secondary;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F9FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF0F9FF),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: _prevStep,
        ),
        title: Row(
          children: [
            Icon(Icons.monitor_heart, color: activeColor),
            const SizedBox(width: 8),
            Text('GAIA', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
          ],
        ),
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1200),
          padding: const EdgeInsets.all(24),
          child: size.width < 900 
              ? _buildQuestionCard(theme, activeColor, isMobile: true)
              : _buildDesktopLayout(theme, activeColor),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(ThemeData theme, Color activeColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          flex: 5,
          child: SizedBox(
            height: 600,
            child: _buildQuestionCard(theme, activeColor, isMobile: false),
          ),
        ),
        const SizedBox(width: 60),
        Expanded(
          flex: 4,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                height: 350, width: 350,
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Image.asset('assets/images/Wizard-Doctor.png', fit: BoxFit.contain),
                ),
              ),
              const SizedBox(height: 24),
              Text("Narrowing down possibilities...", style: theme.textTheme.headlineSmall),
              Text("Analyzing path: ${_history.length} / 15 nodes", style: const TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionCard(ThemeData theme, Color activeColor, {required bool isMobile}) {
    final String currentKey = _history.last;
    final node = _tree[currentKey]!;
    final List<String> options = node['options'] as List<String>;

    return Container(
      padding: EdgeInsets.all(isMobile ? 24 : 40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LinearProgressIndicator(
            value: _history.length / 15,
            backgroundColor: Colors.grey.shade100,
            color: activeColor,
          ),
          const SizedBox(height: 32),
          Text(
            node['question'],
            style: theme.textTheme.displaySmall?.copyWith(fontSize: isMobile ? 24 : 32),
          ),
          const SizedBox(height: 8),
          Text(node['subtitle'] ?? 'Choose the option that fits best', style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 32),
          Expanded(
            child: ListView.builder(
              itemCount: options.length,
              itemBuilder: (context, index) {
                return _buildOptionTile(options[index], activeColor, theme);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionTile(String option, Color activeColor, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: InkWell(
        onTap: () => _handleChoice(option),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200, width: 1),
          ),
          child: Row(
            children: [
              Icon(Icons.radio_button_off, color: Colors.grey.shade400),
              const SizedBox(width: 16),
              Text(
                option,
                style: theme.textTheme.titleMedium?.copyWith(color: const Color(0xFF0F172A)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
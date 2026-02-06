import 'package:flutter/material.dart';
import 'package:gaia/values/values.dart'; 
import 'package:gaia/app/routes.dart';
import 'package:gaia/widgets/navbar.dart'; // Ensure this path and class name match your file

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

  // Track the currently highlighted option before confirmation
  String? _selectedOption;

  // THE DECISION TREE
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

  void _selectOption(String choice) {
    setState(() {
      _selectedOption = choice;
    });
  }

  void _confirmSelection() {
    if (_selectedOption == null) return;

    setState(() {
      _finalSymptoms.add(_selectedOption!);
      String currentKey = _history.last;
      String nextNode = _tree[currentKey]?['next'][_selectedOption!] ?? 
                        _tree[currentKey]?['next']['default'] ?? 
                        'finish';

      if (nextNode == 'finish' || _history.length >= 15) {
        // Navigate to results and pass the list of symptoms collected
        Navigator.pushNamed(context, Routes.results, arguments: _finalSymptoms.toList());
      } else {
        _history.add(nextNode);
        _selectedOption = null; // Reset selection for the next question
      }
    });
  }

  void _prevStep() {
    if (_history.length > 1) {
      setState(() {
        _history.removeLast();
        _selectedOption = null; // Clear selection when going back
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
      
      // Fixed Navbar at the top of the page
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(80), 
        child: NavBar(), 
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

          const SizedBox(height: 24),

          // BACK and CONFIRMATION buttons inside the card
          Row(
            children: [
              if (_history.length > 1) 
                Expanded(
                  child: OutlinedButton(
                    onPressed: _prevStep,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("Back", style: TextStyle(color: Colors.black54)),
                  ),
                ),
              
              if (_history.length > 1) const SizedBox(width: 12),

              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _selectedOption != null ? _confirmSelection : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: activeColor,
                    disabledBackgroundColor: Colors.grey.shade200,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: Text(
                    "Confirm Choice",
                    style: TextStyle(
                      color: _selectedOption != null ? Colors.white : Colors.grey.shade500,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOptionTile(String option, Color activeColor, ThemeData theme) {
    final bool isSelected = _selectedOption == option;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: InkWell(
        onTap: () => _selectOption(option),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            color: isSelected ? activeColor.withOpacity(0.05) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? activeColor : Colors.grey.shade200, 
              width: isSelected ? 2 : 1
            ),
          ),
          child: Row(
            children: [
              Icon(
                isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: isSelected ? activeColor : Colors.grey.shade400,
              ),
              const SizedBox(width: 16),
              Text(
                option,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: isSelected ? activeColor : const Color(0xFF0F172A),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
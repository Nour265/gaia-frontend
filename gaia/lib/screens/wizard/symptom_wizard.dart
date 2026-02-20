import 'package:flutter/material.dart';
import 'package:gaia/values/values.dart'; 
import 'package:gaia/app/routes.dart';
import 'package:gaia/widgets/navbar.dart';
import 'package:gaia/screens/results/results_page.dart';

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
  
  // User data for assessment
  int age = 30; // TODO: Collect from user
  String gender = 'male'; // TODO: Collect from user

  // THE DECISION TREE - COMPLETELY RESTRUCTURED FOR DATA-DRIVEN ACCURACY
  // Based on CSV analysis of 100 diseases and 230 symptoms
  final Map<String, Map<String, dynamic>> _tree = {
    'root': {
      'question': 'What is your main symptom?',
      'subtitle': 'Select the most prominent symptom you\'re experiencing',
      'options': [
        'Lower abdomen or urinary issues',
        'Respiratory, cough, or nasal problems',
        'Back, neck, or joint pain with numbness',
        'Eye redness, itching, or allergies',
        'Difficulty swallowing or upper stomach pain',
        'Weakness, seizures, or neurological symptoms',
        'Menstrual, gynecological, or pelvic issues',
        'Other symptoms'
      ],
      'next': {
        'Lower abdomen or urinary issues': 'urinary_branch1',
        'Respiratory, cough, or nasal problems': 'respiratory_branch1',
        'Back, neck, or joint pain with numbness': 'pain_neurology_branch1',
        'Eye redness, itching, or allergies': 'eye_allergy_branch1',
        'Difficulty swallowing or upper stomach pain': 'swallowing_branch1',
        'Weakness, seizures, or neurological symptoms': 'weakness_branch1',
        'Menstrual, gynecological, or pelvic issues': 'gynecology_branch1',
        'Other symptoms': 'other_branch1'
      }
    },

    // === URINARY & LOWER ABDOMEN BRANCH ===
    // Key diseases: Cystitis, Vulvodynia, Urinary tract infection
    'urinary_branch1': {
      'question': 'Do you have involuntary urination or frequent urination?',
      'options': ['Yes, involuntary urination', 'Yes, frequent urination', 'Both', 'No'],
      'next': {
        'Yes, involuntary urination': 'urinary_branch2a',
        'Yes, frequent urination': 'urinary_branch2a',
        'Both': 'urinary_branch2a',
        'No': 'urinary_branch2b'
      }
    },
    'urinary_branch2a': {
      'question': 'Do you experience pain with these urinary symptoms?',
      'options': ['Painful urination', 'Lower abdominal pain', 'Suprapubic pain (above bladder)', 'All of above'],
      'next': {'default': 'urinary_branch3'}
    },
    'urinary_branch2b': {
      'question': 'What is the main lower abdominal symptom?',
      'options': ['Lower abdominal pain', 'Pelvic pain', 'Side pain', 'Vaginal discharge or itching'],
      'next': {'default': 'urinary_branch3'}
    },
    'urinary_branch3': {
      'question': 'Do you have any of these additional symptoms?',
      'options': ['Blood in urine', 'Fever', 'Back pain', 'Nausea'],
      'next': {'default': 'urinary_finish'}
    },
    'urinary_finish': {
      'question': 'Is there anything else we should know?',
      'options': ['Recent sexual activity', 'Retention of urine', 'No other symptoms', 'Skip'],
      'next': {'default': 'check_finish'}
    },

    // === RESPIRATORY BRANCH ===
    // Key diseases: Nose disorder, Asthma, Bronchitis, Common cold, Pneumonia
    'respiratory_branch1': {
      'question': 'Which respiratory symptom is most prominent?',
      'options': ['Cough', 'Nasal congestion or nosebleed', 'Difficulty breathing or wheezing', 'Sore throat'],
      'next': {
        'Cough': 'respiratory_branch2a',
        'Nasal congestion or nosebleed': 'respiratory_branch2b',
        'Difficulty breathing or wheezing': 'respiratory_branch2c',
        'Sore throat': 'respiratory_branch2d'
      }
    },
    'respiratory_branch2a': {
      'question': 'What type of cough?',
      'options': ['Coughing up sputum (phlegm)', 'Dry cough', 'Persistent cough for weeks', 'Triggers wheezing'],
      'next': {'default': 'respiratory_branch3'}
    },
    'respiratory_branch2b': {
      'question': 'Nasal symptoms with:',
      'options': ['Nosebleed', 'Facial pain', 'Sinus congestion and headache', 'Sneezing'],
      'next': {'default': 'respiratory_branch3'}
    },
    'respiratory_branch2c': {
      'question': 'Breathing issues include:',
      'options': ['Wheezing sounds', 'Rapid breathing', 'Congestion in chest', 'Hurts to breathe'],
      'next': {'default': 'respiratory_branch3'}
    },
    'respiratory_branch2d': {
      'question': 'Sore throat accompanied by:',
      'options': ['Fever', 'Nasal congestion', 'Swollen tonsils', 'Hoarse voice'],
      'next': {'default': 'respiratory_branch3'}
    },
    'respiratory_branch3': {
      'question': 'Associated symptoms?',
      'options': ['Fever', 'Chills', 'Ache all over', 'None'],
      'next': {'default': 'respiratory_finish'}
    },
    'respiratory_finish': {
      'question': 'Duration and triggers?',
      'options': ['Sudden onset', 'Gradual onset', 'Worse with activity', 'No pattern'],
      'next': {'default': 'check_finish'}
    },

    // === PAIN + NEUROLOGICAL BRANCH ===
    // Key diseases: Spondylosis, Complex Regional Pain Syndrome, Peripheral Nerve Disorder
    'pain_neurology_branch1': {
      'question': 'Where is the pain located?',
      'options': ['Back pain', 'Neck pain', 'Multiple joints (widespread)', 'Limbs with numbness'],
      'next': {
        'Back pain': 'pain_neuro_branch2a',
        'Neck pain': 'pain_neuro_branch2a',
        'Multiple joints (widespread)': 'pain_neuro_branch2a',
        'Limbs with numbness': 'pain_neuro_branch2a'
      }
    },
    'pain_neuro_branch2a': {
      'question': 'Associated neurological symptoms?',
      'options': ['Loss of sensation or numbness', 'Paresthesia (tingling/pins & needles)', 'Abnormal involuntary movements', 'All of above'],
      'next': {'default': 'pain_neuro_branch3'}
    },
    'pain_neuro_branch3': {
      'question': 'Pain and motion characteristics?',
      'options': ['Stiffness or tightness', 'Problems with movement', 'Weakness', 'All of above'],
      'next': {'default': 'pain_neuro_finish'}
    },
    'pain_neuro_finish': {
      'question': 'When did symptoms start?',
      'options': ['After injury or trauma', 'Gradual progression', 'Sudden onset', 'Unknown'],
      'next': {'default': 'check_finish'}
    },

    // === EYE & ALLERGY BRANCH ===
    // Key diseases: Conjunctivitis, Allergic conjunctivitis
    'eye_allergy_branch1': {
      'question': 'What are the main eye symptoms?',
      'options': ['Eye redness', 'Itchiness of eye', 'Both redness and itching', 'Vision problems'],
      'next': {'default': 'eye_allergy_branch2'}
    },
    'eye_allergy_branch2': {
      'question': 'Associated symptoms?',
      'options': ['Sneezing', 'Nasal congestion', 'Lacrimation (tearing)', 'Swollen eye'],
      'next': {'default': 'eye_allergy_branch3'}
    },
    'eye_allergy_branch3': {
      'question': 'Other signs of allergy?',
      'options': ['Allergic reaction', 'Seasonal pattern', 'Triggered by exposure', 'None'],
      'next': {'default': 'check_finish'}
    },

    // === SWALLOWING DIFFICULTY BRANCH ===
    // Key diseases: Esophagitis, Gastroenteritis
    'swallowing_branch1': {
      'question': 'Swallowing difficulty with:',
      'options': ['Difficulty in swallowing', 'Upper abdominal pain', 'Both', 'Neither'],
      'next': {
        'Difficulty in swallowing': 'swallowing_branch2',
        'Upper abdominal pain': 'swallowing_branch2',
        'Both': 'swallowing_branch2',
        'Neither': 'other_branch1'
      }
    },
    'swallowing_branch2': {
      'question': 'Additional GI symptoms?',
      'options': ['Vomiting or nausea', 'Sore throat', 'Heartburn or chest pain', 'Multiple of above'],
      'next': {'default': 'swallowing_branch3'}
    },
    'swallowing_branch3': {
      'question': 'Symptom timeline?',
      'options': ['During or after eating', 'Constant discomfort', 'Intermittent', 'Recent onset'],
      'next': {'default': 'check_finish'}
    },

    // === WEAKNESS & NEUROLOGICAL BRANCH ===
    // Key diseases: Hypoglycemia, Peripheral Nerve Disorder, Neurological Conditions
    'weakness_branch1': {
      'question': 'Type of weakness or neurological symptom?',
      'options': ['Leg weakness', 'Arm weakness', 'Seizures or convulsions', 'General weakness'],
      'next': {'default': 'weakness_branch2'}
    },
    'weakness_branch2': {
      'question': 'Associated symptoms?',
      'options': ['Loss of sensation', 'Dizziness or fainting', 'Feeling ill', 'Abnormal movements'],
      'next': {'default': 'weakness_branch3'}
    },
    'weakness_branch3': {
      'question': 'Onset characteristics?',
      'options': ['Sudden onset', 'Gradual onset', 'Comes and goes', 'Progressive'],
      'next': {'default': 'check_finish'}
    },

    // === GYNECOLOGICAL BRANCH ===
    // Key diseases: Vaginal cyst, Vulvodynia, Pelvic inflammatory disease
    'gynecology_branch1': {
      'question': 'Main gynecological symptom?',
      'options': ['Menstrual abnormalities', 'Vaginal discharge or itching', 'Pelvic or vaginal pain', 'Bleeding or spotting'],
      'next': {'default': 'gynecology_branch2'}
    },
    'gynecology_branch2': {
      'question': 'Associated abdominal symptoms?',
      'options': ['Lower abdominal pain', 'Pelvic pain', 'Cramps and spasms', 'No pain'],
      'next': {'default': 'gynecology_branch3'}
    },
    'gynecology_branch3': {
      'question': 'Other symptoms?',
      'options': ['Fever or feeling ill', 'Pain during intercourse', 'Vaginal redness', 'None'],
      'next': {'default': 'check_finish'}
    },

    // === OTHER SYMPTOMS BRANCH ===
    'other_branch1': {
      'question': 'What other main symptom are you experiencing?',
      'options': ['Skin rash or growth', 'Headache or dizziness', 'Fever', 'Chest or heart symptoms'],
      'next': {
        'Skin rash or growth': 'other_branch_skin',
        'Headache or dizziness': 'other_branch_neuro',
        'Fever': 'other_branch_fever',
        'Chest or heart symptoms': 'other_branch_chest'
      }
    },
    'other_branch_skin': {
      'question': 'Skin symptoms include:',
      'options': ['Skin rash', 'Skin growth', 'Abnormal skin appearance', 'Itching of skin'],
      'next': {'default': 'other_branch_skin2'}
    },
    'other_branch_skin2': {
      'question': 'Any fever or spreading?',
      'options': ['With fever', 'Spreading rash', 'Itchy rash', 'Non-spreading'],
      'next': {'default': 'check_finish'}
    },
    'other_branch_neuro': {
      'question': 'Details:',
      'options': ['Severe headache', 'Dizziness or vertigo', 'Disturbance of memory', 'Combination'],
      'next': {'default': 'check_finish'}
    },
    'other_branch_fever': {
      'question': 'Associated symptoms:',
      'options': ['With cough', 'With sore throat', 'With body aches', 'Fever alone'],
      'next': {'default': 'check_finish'}
    },
    'other_branch_chest': {
      'question': 'Type of chest symptom:',
      'options': ['Chest pain', 'Palpitations', 'Shortness of breath', 'Combination'],
      'next': {'default': 'check_finish'}
    },

    // === FINISHING NODE ===
    'check_finish': {
      'question': 'Any final relevant symptoms we missed?',
      'options': ['Fever', 'Fatigue', 'Sweating', 'None'],
      'next': {'default': 'general_finish'}
    },

    // === FINAL QUALIFYING QUESTIONS ===
    'general_finish': {
      'question': 'Impact on daily activities?',
      'options': ['Mild - functioning normally', 'Moderate - some limitation', 'Severe - very limited', 'Unable to function'],
      'next': {'default': 'finish'}
    },
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

      if (nextNode == 'finish' || _history.length >= 25) {
        // Navigate to results and pass the list of symptoms collected
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ResultsPage(
              age: age,
              gender: gender,
              symptoms: _finalSymptoms.toList(),
            ),
          ),
        );
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
              Text("Analyzing path: ${_history.length} / 25 nodes", style: const TextStyle(color: Colors.grey)),
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
            value: _history.length / 25,
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
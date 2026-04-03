import 'package:flutter/material.dart';

import 'package:gaia/widgets/navbar.dart';
import 'package:gaia/screens/results/results_page.dart';
import 'package:gaia/services/auth_session.dart';
class SymptomWizard extends StatefulWidget {
  const SymptomWizard({super.key});

  @override
  State<SymptomWizard> createState() => _SymptomWizardState();
}

// Data Structure to hold dynamically generated pages
class WizardStepData {
  final String mainCategory;
  final String subCategory;
  final List<String> symptoms;

  WizardStepData(this.mainCategory, this.subCategory, this.symptoms);
}

// MAPPING: ALL 230 symptoms are now fully broken down into UI sub-areas!
final Map<String, Map<String, List<String>>> SYMPTOM_BRANCHES = {
  'Pain & Discomfort': {
    'Head, Face & Neck': ['headache', 'frontal headache', 'neck pain', 'facial pain', 'toothache', 'mouth pain', 'pain in gums', 'gum pain', 'pain in eye', 'eye burns or stings', 'painful sinuses', 'ear pain'],
    'Torso & Back': ['sharp chest pain', 'burning chest pain', 'rib pain', 'hurts to breath', 'back pain', 'low back pain', 'back cramps or spasms', 'back stiffness or tightness', 'heartburn'],
    'Abdominal & Pelvic': ['sharp abdominal pain', 'lower abdominal pain', 'burning abdominal pain', 'upper abdominal pain', 'suprapubic pain', 'pelvic pain', 'pain during pregnancy', 'painful menstruation', 'painful urination', 'pain during intercourse', 'pain in testicles', 'vaginal pain', 'pain of the anus', 'groin pain'],
    'Limbs & Joints': ['leg pain', 'hip pain', 'knee pain', 'foot or toe pain', 'ankle pain', 'arm pain', 'hand or finger pain', 'wrist pain', 'elbow pain', 'shoulder pain', 'joint pain', 'arm stiffness or tightness', 'hand or finger stiffness or tightness', 'knee stiffness or tightness', 'hip stiffness or tightness', 'shoulder stiffness or tightness'],
    'General Body Pain': ['ache all over', 'bones are painful', 'cramps and spasms', 'lower body pain', 'side pain'],
  },
  'Abdominal & Digestive': {
    'Stomach & Digestion': ['nausea', 'vomiting', 'vomiting blood', 'regurgitation', 'regurgitation.1', 'decreased appetite', 'stomach bloating'],
    'Bowel & Rectal': ['diarrhea', 'constipation', 'blood in stool', 'melena', 'rectal bleeding', 'changes in stool appearance'],
    'Throat & Swallowing': ['difficulty in swallowing'],
  },
  'Respiratory & Chest': {
    'Breathing & Cough': ['shortness of breath', 'breathing fast', 'difficulty breathing', 'abnormal breathing sounds', 'apnea', 'cough', 'coughing up sputum', 'hemoptysis', 'wheezing', 'sneezing'],
    'Heart & Chest': ['chest tightness', 'congestion in chest', 'palpitations', 'irregular heartbeat', 'decreased heart rate', 'increased heart rate'],
    'Nose & Sinus': ['nasal congestion', 'sinus congestion', 'coryza'],
  },
  'Neurological & Psychological': {
    'Mood & Behavior': ['anxiety and nervousness', 'depression', 'depressive or psychotic symptoms', 'hostile behavior', 'excessive anger', 'temper problems', 'low self-esteem', 'obsessions and compulsions', 'antisocial behavior', 'hysterical behavior'],
    'Cognitive & Sleep': ['delusions or hallucinations', 'restlessness', 'insomnia', 'sleepiness', 'disturbance of memory'],
    'Neurological & Physical': ['dizziness', 'fainting', 'seizures', 'difficulty speaking', 'abnormal involuntary movements', 'abnormal movement of eyelid', 'problems with movement'],
    'Weakness & Sensation': ['weakness', 'loss of sensation', 'focal weakness', 'hand or finger weakness', 'arm weakness', 'leg weakness', 'paresthesia', 'foreign body sensation in eye'],
  },
  'Skin & Swelling': {
    'Skin Issues & Rashes': ['abnormal appearing skin', 'skin lesion', 'acne or pimples', 'skin growth', 'skin moles', 'itching of skin', 'skin dryness, peeling, scaliness, or roughness', 'skin irritation', 'skin rash', 'diaper rash', 'irregular appearing scalp', 'itchy scalp', 'warts'],
    'Head, Neck & Face Swelling': ['throat swelling', 'lip swelling', 'neck mass', 'jaw swelling', 'neck swelling', 'mass on eyelid', 'eyelid swelling', 'eyelid lesion or rash'],
    'Body & Limbs Swelling': ['skin swelling', 'peripheral edema', 'hand or finger swelling', 'wrist swelling', 'arm swelling', 'knee swelling', 'leg swelling', 'foot or toe swelling', 'ankle swelling', 'elbow swelling', 'kidney mass', 'hand or finger lump or mass', 'back mass or lump', 'arm lump or mass', 'mass or swelling around the anus'],
    'Other & Localized Itching': ['swelling of scrotum', 'vaginal itching', 'mouth ulcer', 'irregular appearing nails', 'itchy ear(s)', 'itchiness of eye', 'itching of the anus'],
  },
  'Head, Eye, Ear & Throat': {
    'Eyes & Vision': ['white discharge from eye', 'diminished vision', 'double vision', 'symptoms of eye', 'spots or clouds in vision', 'eye redness', 'lacrimation', 'blindness', 'bleeding from eye', 'swollen eye'],
    'Ears & Hearing': ['diminished hearing', 'pus draining from ear', 'ringing in ear', 'plugged feeling in ear', 'fluid in ear', 'pulling at ears', 'redness in ear', 'bleeding from ear'],
    'Nose, Throat & Mouth': ['hoarse voice', 'sore throat', 'mouth dryness', 'symptoms of the face', 'nosebleed', 'swollen or red tonsils', 'fears and phobias'],
  },
  'Urinary & Pelvic': {
    'Urinary & Kidney': ['retention of urine', 'involuntary urination', 'frequent urination', 'blood in urine', 'unusual color or odor to urine', 'symptoms of the kidneys', 'excessive urination at night', 'symptoms of bladder', 'hesitancy', 'low urine output'],
    'Female Reproductive': ['vaginal discharge', 'intermenstrual bleeding', 'vaginal redness', 'problems during pregnancy', 'spotting or bleeding during pregnancy', 'blood clots during menstrual periods', 'recent pregnancy', 'uterine contractions', 'long menstrual periods', 'heavy menstrual flow', 'infertility', 'unpredictable menstruation', 'frequent menstruation'],
    'Male Reproductive': ['symptoms of the scrotum and testes', 'impotence', 'symptoms of prostate'],
  },
  'Systemic & General': {
    'Fever & Fatigue': ['feeling ill', 'hot flashes', 'fever', 'chills', 'fatigue', 'flu-like syndrome', 'sweating'],
    'Infants & Growth': ['lack of growth', 'irritable infant', 'infant feeding problem'],
    'Habits & Other': ['abusing alcohol', 'drug abuse', 'jaundice', 'weight gain', 'allergic reaction', 'fluid retention', 'bleeding gums'],
  },
};

class _SymptomWizardState extends State<SymptomWizard> {
  bool _inScreeningPhase = true;
  int _currentStep = 0;
  final ScrollController _scrollController = ScrollController();
  final ScrollController _screeningScrollController = ScrollController();
  
  // Tracking Selections
  final Set<String> _selectedCategoryScreens = {};
  final Set<String> _selectedSubCategories = {}; // Tracks specific sub-areas
  final Set<String> _selectedSymptoms = {};
  
  // Dynamic list of pages generated based on screening answers
  List<WizardStepData> _wizardSteps = [];

  final List<Map<String, String>> _screeningQuestions = [
    {
      'question': 'Any pain or discomfort (back, neck, joints, limbs)?',
      'category': 'Pain & Discomfort',
    },
    {
      'question': 'Any abdominal pain, nausea, or digestive issues?',
      'category': 'Abdominal & Digestive',
    },
    {
      'question': 'Any respiratory issues, chest pain, or palpitations?',
      'category': 'Respiratory & Chest',
    },
    {
      'question': 'Any neurological symptoms (headache, dizziness, anxiety, memory)?',
      'category': 'Neurological & Psychological',
    },
    {
      'question': 'Any skin rash, swelling, or lesions?',
      'category': 'Skin & Swelling',
    },
    {
      'question': 'Any eye, ear, nose, throat, or facial symptoms?',
      'category': 'Head, Eye, Ear & Throat',
    },
    {
      'question': 'Any urinary, pelvic, or reproductive issues?',
      'category': 'Urinary & Pelvic',
    },
    {
      'question': 'Any general symptoms like fever, fatigue, or weight changes?',
      'category': 'Systemic & General',
    },
  ];

  void _toggleScreeningAnswer(String category) {
    setState(() {
      if (_selectedCategoryScreens.contains(category)) {
        _selectedCategoryScreens.remove(category);
        // Clear subcategories if main is unchecked
        _selectedSubCategories.removeAll(SYMPTOM_BRANCHES[category]!.keys);
      } else {
        _selectedCategoryScreens.add(category);
      }
    });
  }

  void _finishScreening() {
    _wizardSteps.clear();

    // Generate pages ONLY for the explicitly SELECTED categories
    for (String mainCat in _selectedCategoryScreens) {
      final subMap = SYMPTOM_BRANCHES[mainCat]!;
      bool hasAnySubSelected = subMap.keys.any((s) => _selectedSubCategories.contains(s));

      for (String subCat in subMap.keys) {
        // Add the page if it's General, explicitly selected, or if no sub-areas were selected at all
        if (subCat == 'General' || _selectedSubCategories.contains(subCat) || !hasAnySubSelected) {
          _wizardSteps.add(WizardStepData(mainCat, subCat, subMap[subCat]!));
        }
      }
    }

    setState(() {
      _inScreeningPhase = false;
      _currentStep = 0;
    });
  }

  void _toggleSymptom(String symptom) {
    setState(() {
      if (_selectedSymptoms.contains(symptom)) {
        _selectedSymptoms.remove(symptom);
      } else {
        _selectedSymptoms.add(symptom);
      }
    });
  }

  void _nextCategory() {
    if (_currentStep < _wizardSteps.length - 1) {
      setState(() {
        _currentStep++;
      });
    } else {
      if (_selectedSymptoms.length >= 3) {
        // Check if the user is logged in to get their actual age, otherwise default to 25
        final int assessmentAge = AuthSession.isLoggedIn 
            ? (AuthSession.user?.age ?? 25) 
            : 25;
            
        // Check if the user is logged in to get their gender, otherwise default to 'other'
        final String assessmentGender = AuthSession.isLoggedIn 
            ? (AuthSession.user?.gender ?? 'other').toLowerCase() 
            : 'other';

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ResultsPage(
              age: assessmentAge,
              gender: assessmentGender,
              symptoms: _selectedSymptoms.toList(),
            ),
          ),
        );

      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text(
              'Please select at least 3 symptoms for an accurate prediction. (Selected: ${_selectedSymptoms.length})',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
            backgroundColor: Colors.red.shade600,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _prevCategory() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    } else {
      setState(() {
        _inScreeningPhase = true;
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
      appBar: const GaiaNavBarAppBar(),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1200),
          padding: const EdgeInsets.all(24),
          child: _inScreeningPhase
              ? _buildScreeningCard(theme, activeColor)
              : _buildSymptomCard(theme, activeColor, size),
        ),
      ),
    );
  }

  Widget _buildScreeningCard(ThemeData theme, Color activeColor) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Let\'s narrow it down',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select any general areas where you are experiencing symptoms.',
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: Scrollbar(
              controller: _screeningScrollController,
              thumbVisibility: true,                  
              thickness: 6.0,
              radius: const Radius.circular(8),
              child: SingleChildScrollView(
                controller: _screeningScrollController, 
                padding: const EdgeInsets.only(right: 16), // Adds space so scrollbar doesn't cover text
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // LEFT COLUMN (Evens: Pain, Respiratory, Skin, Urinary)
                    Expanded(
                      child: Column(
                        children: [
                          for (int i = 0; i < _screeningQuestions.length; i += 2)
                            _buildScreeningTile(
                              _screeningQuestions[i]['question']!,
                              _screeningQuestions[i]['category']!,
                              _selectedCategoryScreens.contains(_screeningQuestions[i]['category']),
                              activeColor,
                              theme,
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16), // Spacing between the 2 columns
                    
                    // RIGHT COLUMN (Odds: Abdominal, Neurological, Head/Eye/Ear, Systemic)
                    Expanded(
                      child: Column(
                        children: [
                          for (int i = 1; i < _screeningQuestions.length; i += 2)
                            _buildScreeningTile(
                              _screeningQuestions[i]['question']!,
                              _screeningQuestions[i]['category']!,
                              _selectedCategoryScreens.contains(_screeningQuestions[i]['category']),
                              activeColor,
                              theme,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _selectedCategoryScreens.isNotEmpty ? _finishScreening : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: activeColor,
              disabledBackgroundColor: Colors.grey.shade200,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Container(
              width: double.infinity,
              alignment: Alignment.center,
              child: Text(
                'Continue to Detailed Symptoms →',
                style: TextStyle(
                  color: _selectedCategoryScreens.isNotEmpty
                      ? Colors.white
                      : Colors.grey.shade500,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScreeningTile(
    String question,
    String category,
    bool isSelected,
    Color activeColor,
    ThemeData theme,
  ) {
    final subMap = SYMPTOM_BRANCHES[category]!;
    final hasSubCategories = subMap.keys.length > 1 && subMap.keys.first != 'General';

    return Column(
      children: [
        // Main Category Button
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            onTap: () => _toggleScreeningAnswer(category),
            borderRadius: BorderRadius.circular(16),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              constraints: const BoxConstraints(minHeight: 88),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: isSelected ? activeColor.withOpacity(0.08) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? activeColor : Colors.grey.shade300,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      question,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        color: isSelected ? activeColor : const Color(0xFF334155),
                      ),
                    ),
                  ),
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected ? activeColor : Colors.transparent,
                      border: Border.all(
                        color: isSelected ? activeColor : Colors.grey.shade400,
                        width: 2,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, size: 18, color: Colors.white)
                        : null,
                  ),
                ],
              ),
            ),
          ),
        ),

        // Dynamic Sub-area Question
        if (isSelected && hasSubCategories)
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.only(bottom: 16, left: 24, right: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: activeColor.withOpacity(0.04),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: activeColor.withOpacity(0.15)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Where specifically? (Select all that apply)',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: activeColor.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: subMap.keys.map((subCat) {
                    final isSubSelected = _selectedSubCategories.contains(subCat);
                    return FilterChip(
                      label: Text(subCat),
                      selected: isSubSelected,
                      selectedColor: activeColor.withOpacity(0.2),
                      checkmarkColor: activeColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      side: BorderSide(
                        color: isSubSelected ? activeColor : Colors.grey.shade300,
                      ),
                      labelStyle: TextStyle(
                        color: isSubSelected ? activeColor : Colors.grey.shade700,
                        fontWeight: isSubSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      onSelected: (bool selected) {
                        setState(() {
                          if (selected) {
                            _selectedSubCategories.add(subCat);
                          } else {
                            _selectedSubCategories.remove(subCat);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildSymptomCard(ThemeData theme, Color activeColor, Size size) {
    final stepData = _wizardSteps[_currentStep];
    final progress = (_currentStep + 1) / _wizardSteps.length;
    final isHighPriority = _selectedCategoryScreens.contains(stepData.mainCategory);

    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Step ${_currentStep + 1} of ${_wizardSteps.length}',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              if (isHighPriority)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.priority_high, size: 14, color: Colors.orange.shade700),
                      const SizedBox(width: 4),
                      Text(
                        'Priority Area',
                        style: TextStyle(
                          color: Colors.orange.shade700,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(activeColor),
            ),
          ),
          const SizedBox(height: 32),
          
          Text(
            stepData.mainCategory,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F172A),
            ),
          ),
          if (stepData.subCategory != 'General') ...[
            const SizedBox(height: 8),
            Text(
              'Specific Area: ${stepData.subCategory}',
              style: theme.textTheme.titleLarge?.copyWith(
                color: activeColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            'Select all symptoms you are experiencing:',
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 32),

          Expanded(
            child: stepData.symptoms.isEmpty
                ? const Center(child: Text('No symptoms available for this category.'))
                : Scrollbar(
                    controller: _scrollController, // 1. Attach controller
                    thumbVisibility: true,         // 2. Forces scrollbar to always show!
                    thickness: 6.0,                // Optional: make it a bit thicker
                    radius: const Radius.circular(8),
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      childAspectRatio: 4,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: stepData.symptoms.length,
                    itemBuilder: (context, index) {
                      final symptom = stepData.symptoms[index];
                      final isSelected = _selectedSymptoms.contains(symptom);
                      return _buildSymptomTile(
                        symptom,
                        isSelected,
                        activeColor,
                        theme,
                      );
                    },
                  ),
          ),
          ),

          const SizedBox(height: 32),
          // Navigation Buttons with Smart Label
          Row(
            children: [
              Expanded(
                flex: 1,
                child: OutlinedButton(
                  onPressed: _prevCategory,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _currentStep == 0 ? 'Back to Screening' : 'Back',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF475569), 
                      fontWeight: FontWeight.bold
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _nextCategory,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: activeColor,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    _currentStep < _wizardSteps.length - 1
                        ? 'Next Category →'
                        : 'Get Results',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSymptomTile(
    String symptom,
    bool isSelected,
    Color activeColor,
    ThemeData theme,
  ) {
    return InkWell(
      onTap: () => _toggleSymptom(symptom),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withOpacity(0.1)
              : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? activeColor : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Checkbox(
              value: isSelected,
              onChanged: (_) => _toggleSymptom(symptom),
              activeColor: activeColor,
            ),
            Flexible(
              child: Text(
                symptom,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: isSelected ? activeColor : const Color(0xFF0F172A),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
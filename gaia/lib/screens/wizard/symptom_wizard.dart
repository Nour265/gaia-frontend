import 'package:flutter/material.dart';

import 'package:gaia/widgets/navbar.dart';
import 'package:gaia/screens/results/results_page.dart';

class SymptomWizard extends StatefulWidget {
  const SymptomWizard({super.key});

  @override
  State<SymptomWizard> createState() => _SymptomWizardState();
}

// ACTUAL symptom names from dataset - directly mapped for model
final Map<String, List<String>> SYMPTOM_BRANCHES = {
  'abdominal': [
    'sharp abdominal pain',
    'lower abdominal pain',
    'upper abdominal pain',
    'burning abdominal pain',
    'vomiting',
    'nausea',
    'diarrhea',
    'constipation',
    'stomach bloating',
    'cramps and spasms',
  ],
  'respiratory': [
    'cough',
    'wheezing',
    'difficulty breathing',
    'shortness of breath',
    'coughing up sputum',
    'sore throat',
    'nasal congestion',
    'coryza',
    'chest tightness',
    'congestion in chest',
  ],
  'pain': [
    'back pain',
    'neck pain',
    'joint pain',
    'leg pain',
    'arm pain',
    'hand or finger pain',
    'wrist pain',
    'shoulder pain',
    'ear pain',
    'headache',
  ],
  'cardiac': [
    'sharp chest pain',
    'burning chest pain',
    'palpitations',
    'irregular heartbeat',
    'breathing fast',
    'decreased heart rate',
    'anxiety and nervousness',
    'sweating',
    'dizziness',
    'fainting',
  ],
  'skin': [
    'skin rash',
    'skin lesion',
    'skin growth',
    'acne or pimples',
    'itching of skin',
    'skin swelling',
    'skin moles',
    'skin irritation',
  ],
  'systemic': [
    'fever',
    'chills',
    'fatigue',
    'feeling ill',
    'ache all over',
    'weakness',
    'weight gain',
    'decreased appetite',
  ],
  'neurological': [
    'loss of sensation',
    'paresthesia',
    'dizziness',
    'difficulty speaking',
    'seizures',
    'disturbance of memory',
    'abnormal involuntary movements',
    'focal weakness',
  ],
  'ent': [
    'hoarse voice',
    'difficulty in swallowing',
    'throat swelling',
    'swollen or red tonsils',
    'diminished hearing',
    'eye redness',
    'pus draining from ear',
    'nosebleed',
  ],
  'gynecological': [
    'painful urination',
    'vaginal itching',
    'vaginal discharge',
    'vaginal pain',
    'vaginal redness',
    'pelvic pain',
    'painful menstruation',
    'heavy menstrual flow',
  ],
  'urinary': [
    'frequent urination',
    'painful urination',
    'involuntary urination',
    'blood in urine',
    'retention of urine',
    'suprapubic pain',
  ],
};

// Old mapping - DEPRECATED but keeping for reference
final Map<String, String> SYMPTOM_MAPPING = {
  // Cardiac symptoms
  'Crushing chest pain': 'sharp chest pain',
  'Burning or crushing chest pain': 'burning chest pain',
  'Tight chest feeling': 'chest tightness',
  'Palpitations or irregular heartbeat': 'palpitations',
  'Shortness of breath without pain': 'shortness of breath',
  'Combination of above': 'chest tightness',
  'Radiating to left arm, shoulder, or jaw': 'sharp chest pain',
  'Occurs with exertion or activity': 'shortness of breath',
  'Occurs at rest or stress': 'anxiety and nervousness',
  'With sweating or nausea': 'sweating',
  'With dizziness or fainting': 'dizziness',
  'Heart rate too fast (tachycardia)': 'breathing fast',
  'Heart rate too slow (bradycardia)': 'decreased heart rate',
  'Irregular heartbeat pattern': 'irregular heartbeat',
  'Leg swelling or fluid retention': 'peripheral edema',
  'Fatigue with minimal activity': 'fatigue',
  'Sudden onset (minutes)': 'sharp chest pain',
  'Gradual over hours or days': 'chest tightness',
  'Recurring episodes': 'palpitations',
  
  // Respiratory symptoms
  'Persistent cough': 'cough',
  'Difficulty breathing or wheezing': 'difficulty breathing',
  'Shortness of breath with minimal activity': 'shortness of breath',
  'Cough with mucus/phlegm': 'coughing up sputum',
  'Nasal congestion or sinus issues': 'nasal congestion',
  'Sneezing or allergic symptoms': 'coryza',
  'Dry persistent cough': 'cough',
  'Coughing up sputum or mucus': 'coughing up sputum',
  'Cough worse at night': 'cough',
  'Cough triggered by activity': 'cough',
  'Wheezing sounds when breathing': 'wheezing',
  'Rapid or labored breathing': 'breathing fast',
  'Breathing difficulty when lying down': 'difficulty breathing',
  'Chest congestion or tightness': 'congestion in chest',
  'Hourly to daily sleep interruption': 'apnea',
  'Fever or chills': 'fever',
  'Sore throat or hoarse voice': 'sore throat',
  'Nasal congestion with cough': 'nasal congestion',
  'Fatigue or body aches': 'fatigue',
  'No fever or systemic symptoms': 'cough',
  'Triggered by allergens or animals': 'allergic reaction',
  
  // Fever & Systemic
  'High fever (38-40°C / 100-104°F)': 'fever',
  'Low-grade fever (37-38°C / 98-100°F)': 'fever',
  'No fever but feeling very ill': 'feeling ill',
  'Recurring fever with chills': 'chills',
  'Fever with sweating': 'sweating',
  'Cough or respiratory symptoms': 'cough',
  'Sore throat and swollen tonsils': 'swollen or red tonsils',
  'Abdominal pain or diarrhea': 'diarrhea',
  'Aches and pains throughout body': 'ache all over',
  'Headache with neck stiffness': 'headache',
  'Fatigue and general malaise': 'fatigue',
  'Mild - can function normally': 'feeling ill',
  'Moderate - limited activities': 'fatigue',
  'Severe - bedridden': 'fatigue',
  'With confusion or altered mental status': 'disturbance of memory',
  
  // GI symptoms
  'Sharp/acute abdominal pain': 'sharp abdominal pain',
  'Cramping or spasms': 'cramps and spasms',
  'Upper abdominal pain': 'upper abdominal pain',
  'Lower abdominal pain': 'lower abdominal pain',
  'Nausea or vomiting': 'nausea',
  'Diarrhea or constipation': 'diarrhea',
  'Right upper abdomen (liver/gallbladder area)': 'upper abdominal pain',
  'Upper middle abdomen (stomach)': 'upper abdominal pain',
  'Right lower abdomen (appendix area)': 'lower abdominal pain',
  'Left lower abdomen': 'lower abdominal pain',
  'Lower middle abdomen': 'lower abdominal pain',
  'Diffuse across abdomen': 'burning abdominal pain',
  'Vomiting or nausea': 'vomiting',
  'Diarrhea (loose, frequent)': 'diarrhea',
  'Constipation (hard to pass)': 'constipation',
  'Bloating or stomach distension': 'stomach bloating',
  'Blood in stool or dark stool': 'blood in stool',
  'Changes in bowel habits': 'changes in stool appearance',
  'Triggered by eating certain foods': 'nausea',
  'Worse after fatty meals': 'burning abdominal pain',
  'Related to stress': 'stomach bloating',
  'Constant or recurring': 'burning abdominal pain',
  'Sudden onset': 'sharp abdominal pain',
  'No obvious trigger': 'nausea',
  'Weight loss or decreased appetite': 'decreased appetite',
  'Jaundice (yellowing)': 'jaundice',
  'Heartburn or acid reflux': 'heartburn',
  'Recent antibiotics or medication': 'diarrhea',
  
  // Neurological
  'Severe headache (frontal or generalized)': 'frontal headache',
  'Migraines or throbbing pain': 'headache',
  'Dizziness or vertigo': 'dizziness',
  'Fainting or near-fainting': 'fainting',
  'Memory problems or confusion': 'disturbance of memory',
  'Tingling or numbness': 'paresthesia',
  'Sudden severe onset (thunderclap)': 'headache',
  'Gradual worsening over days': 'headache',
  'Throbbing on one side': 'headache',
  'Pressure or tightness': 'headache',
  'Associated with visual changes': 'double vision',
  'Associated with nausea': 'nausea',
  'Vision changes or double vision': 'double vision',
  'Weakness or paralysis': 'focal weakness',
  'Loss of sensation/numbness': 'loss of sensation',
  'Seizure or convulsions': 'seizures',
  'Slurred speech or difficulty speaking': 'difficulty speaking',
  'Balance or coordination problems': 'paresthesia',
  'After head trauma or injury': 'headache',
  'During or after stress/anxiety': 'anxiety and nervousness',
  'During panic episodes': 'anxiety and nervousness',
  'Progressive over weeks/months': 'headache',
  'Recurring pattern': 'headache',
  'First time experiencing this': 'dizziness',
  
  // Pain & Musculoskeletal
  'Back pain (lower or upper)': 'back pain',
  'Neck pain or stiffness': 'neck pain',
  'Joint pain (arthritis-like)': 'joint pain',
  'Sharp localized pain': 'sharp abdominal pain',
  'Widespread muscle aches': 'ache all over',
  'Hand, wrist, or finger pain': 'hand or finger pain',
  'Stiffness, especially in morning': 'back stiffness or tightness',
  'Worse with movement or activity': 'back pain',
  'Swelling or warmth in joint': 'peripheral edema',
  'Limiting range of motion': 'problems with movement',
  'Severe sharp episodes': 'sharp abdominal pain',
  'Chronic dull ache': 'back pain',
  'Tingling or numbness (nerve-related)': 'paresthesia',
  'Weakness in affected area': 'arm weakness',
  'Visible swelling or redness': 'skin swelling',
  'Rash or skin changes': 'skin rash',
  'Fever or feeling ill': 'fever',
  'After injury or trauma': 'back pain',
  'Gradually over time': 'back pain',
  'Repetitive strain (occupation)': 'wrist pain',
  'Sudden without cause': 'back pain',
  
  // Urinary
  'Frequent urination (many times daily)': 'frequent urination',
  'Urgency - sudden need to urinate': 'painful urination',
  'Painful or burning urination': 'painful urination',
  'Involuntary leakage (incontinence)': 'involuntary urination',
  'Blood in urine': 'blood in urine',
  'Retention or difficulty urinating': 'retention of urine',
  'Suprapubic pain (above bladder)': 'suprapubic pain',
  'Lower abdominal or pelvic pain': 'lower abdominal pain',
  'Urgency and frequency together': 'frequent urination',
  'Dark or discolored urine': 'blood in urine',
  'Urgency at night (nocturia)': 'excessive urination at night',
  'Back or flank pain': 'back pain',
  'Recent unprotected sexual contact': 'painful urination',
  
  // Gynecological
  'Painful menstruation': 'idiopathic painful menstruation',
  'Heavy or long menstrual periods': 'long menstrual periods',
  'Irregular cycle or unpredictable': 'idiopathic irregular menstrual cycle',
  'Vaginal discharge or odor': 'vaginal discharge',
  'Vaginal itching or burning': 'vaginal itching',
  'Vaginal pain or discomfort': 'vaginal pain',
  'Severe cramping before/during period': 'cramps and spasms',
  'Abnormal amount of bleeding': 'blood clots during menstrual periods',
  'Clots in menstrual blood': 'blood clots during menstrual periods',
  'Yellow, white, or thick discharge': 'vaginal discharge',
  'Itching with vaginal discharge': 'vaginal itching',
  'Redness or swelling of vulva': 'vaginal redness',
  'Lower abdominal pain between periods': 'lower abdominal pain',
  'Pelvic pain or discomfort': 'pelvic pain',
  'Pain during intercourse': 'pain during intercourse',
  'Infertility concerns': 'infertility',
  
  // Skin
  'Rash with redness and itching': 'skin rash',
  'Dry, flaky, or scaly skin': 'skin dryness, peeling, scaliness, or roughness',
  'Blisters or weeping sores': 'skin rash',
  'Skin lesion or growth': 'skin lesion',
  'Acne or pimples': 'acne or pimples',
  'Discoloration or pigmentation change': 'skin pigmentation disorder',
  'Itchy and inflamed (eczema-like)': 'itching of skin',
  'Thick, scaly patches (psoriasis-like)': 'skin rash',
  'Clustered blisters (herpes-like)': 'skin rash',
  'Widespread vs localized': 'skin rash',
  'Weeping or draining pus': 'skin rash',
  'Brown/tan spots or moles': 'skin moles',
  'After contact with allergen': 'allergic reaction',
  'Worse with sweat or moisture': 'itching of skin',
  'Spreading to other areas': 'skin rash',
  'Sun exposure': 'skin rash',
  'Severe pain or burning': 'skin irritation',
  'Constant itching': 'itching of skin',
  'Signs of infection (pus, warmth)': 'skin rash',
  'Recently infected or scabbing': 'skin rash',
  'Affecting joints (psoriasis sign)': 'joint pain',
  
  // ENT
  'Sore throat or difficulty swallowing': 'sore throat',
  'Earache or ear pain': 'ear pain',
  'Nasal congestion or sinus pain': 'nasal congestion',
  'Hearing loss or ear fullness': 'diminished hearing',
  'Eye symptoms: redness or stye': 'eye redness',
  'Hoarseness or voice changes': 'hoarse voice',
  'Severe sore throat': 'sore throat',
  'Swollen or red tonsils': 'swollen or red tonsils',
  'White patches on throat': 'sore throat',
  'Difficulty swallowing': 'difficulty in swallowing',
  'Hoarse voice': 'hoarse voice',
  'Ear pain or earache': 'ear pain',
  'Pus or drainage from ear': 'pus draining from ear',
  'Ringing in ears': 'ringing in ear',
  'Fluid feeling in ear': 'fluid in ear',
  'Sinus pain or pressure': 'sinus congestion',
  'Nosebleed': 'nosebleed',
  'Sinus drainage': 'sinus congestion',
  'Persistent cough from drainage': 'cough',
  
  // Psychiatric
  'Persistent sadness (depression)': 'depression',
  'Excessive worry or anxiety': 'anxiety and nervousness',
  'Panic attacks or panic disorder': 'anxiety and nervousness',
  'Mood swings or emotional instability': 'excessive anger',
  'Unusual thoughts or beliefs': 'delusions or hallucinations',
  'Behavioral or personality changes': 'personality disorder',
  'Loss of interest in activities': 'depression',
  'Sleep disturbance (insomnia)': 'insomnia',
  'Excessive fatigue or low energy': 'fatigue',
  'Difficulty concentrating': 'disturbance of memory',
  'Feelings of worthlessness': 'depression',
  'Thoughts of self-harm': 'depressive or psychotic symptoms',
  'Heart palpitations during anxiety': 'palpitations',
  'Sweating or trembling': 'sweating',
  'Restlessness or agitation': 'restlessness',
  'Appetite or weight changes': 'weight gain',
  'Headaches or body aches': 'headache',
  'Recent onset (days/weeks)': 'anxiety and nervousness',
  'Longstanding (months)': 'depression',
  'Triggered by specific events': 'anxiety and nervousness',
  'No clear trigger': 'depression',
  'Progressive worsening': 'depression',
  
  // Other & finishing
  'Hair, scalp, or nail issues': 'irregular appearing nails',
  'Hearing loss or balance problems': 'diminished hearing',
  'Weight gain or metabolic issues': 'weight gain',
  'Swelling in legs or feet': 'peripheral edema',
  'Sweating or night sweats': 'sweating',
  'Weight loss': 'weight gain',
  'None of these': 'feeling ill',
  'Mild symptoms - living normally': 'feeling ill',
  'Moderate symptoms - some limitations': 'fatigue',
  'Severe symptoms - very limited': 'fatigue',
  'Very severe - unable to function': 'weakness',
  'Symptom is worsening': 'fatigue',
  'Symptom is stable/chronic': 'fatigue',
  'Recent medication change': 'feeling ill',
  'Recent lifestyle change': 'fatigue',
  'No obvious cause': 'feeling ill',
  'Triggered by specific activity': 'fatigue',
};

class _SymptomWizardState extends State<SymptomWizard> {
  // Multi-select symptom collection
  final Set<String> _selectedSymptoms = {};
  
  // Wizard phases
  bool _inScreeningPhase = true;
  int _currentStep = 0;
  Set<String> _selectedCategoryScreens = {}; // Categories selected during screening
  
  // User data for assessment
  int age = 30; // TODO: Collect from user
  String gender = 'male'; // TODO: Collect from user

  // General screening questions (yes/no to narrow down)
  final List<Map<String, String>> _screeningQuestions = [
    {'question': 'Do you have fever or chills?', 'category': 'systemic'},
    {'question': 'Any respiratory issues (cough, difficulty breathing, sore throat)?', 'category': 'respiratory'},
    {'question': 'Any chest pain or heart palpitations?', 'category': 'cardiac'},
    {'question': 'Any abdominal pain, nausea, or digestive issues?', 'category': 'abdominal'},
    {'question': 'Any pain (back, neck, joints, limbs)?', 'category': 'pain'},
    {'question': 'Any neurological symptoms (headache, dizziness, memory issues)?', 'category': 'neurological'},
    {'question': 'Any skin rash, lesions, or irritation?', 'category': 'skin'},
    {'question': 'Any ear, nose, or throat symptoms?', 'category': 'ent'},
    {'question': 'Any urinary or bladder issues?', 'category': 'urinary'},
    {'question': 'Any gynecological symptoms (women only)?', 'category': 'gynecological'},
  ];

  // Symptom categories (shown in priority order after screening)
  final List<String> _allCategories = [
    'systemic',
    'respiratory',
    'cardiac',
    'abdominal',
    'pain',
    'neurological',
    'skin',
    'ent',
    'urinary',
    'gynecological',
  ];

  List<String> get _prioritizedCategories {
    // Put selected categories first, then the rest
    final selected = _allCategories.where((c) => _selectedCategoryScreens.contains(c)).toList();
    final unselected = _allCategories.where((c) => !_selectedCategoryScreens.contains(c)).toList();
    return [...selected, ...unselected];
  }

  void _toggleScreeningAnswer(String category) {
    setState(() {
      if (_selectedCategoryScreens.contains(category)) {
        _selectedCategoryScreens.remove(category);
      } else {
        _selectedCategoryScreens.add(category);
      }
    });
  }

  void _finishScreening() {
    setState(() {
      _inScreeningPhase = false;
      _currentStep = 0;
    });
  }

  void _backToScreening() {
    setState(() {
      _inScreeningPhase = true;
      _currentStep = 0;
      _selectedSymptoms.clear();
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
    final currentCategory = _prioritizedCategories[_currentStep];
    if (_currentStep < _prioritizedCategories.length - 1) {
      setState(() {
        _currentStep++;
      });
    } else {
      // Finish - go to results
      if (_selectedSymptoms.isNotEmpty) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ResultsPage(
              age: age,
              gender: gender,
              symptoms: _selectedSymptoms.toList(),
            ),
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
    }
  }

  Map<String, String> _getCategoryInfo() {
    final category = _prioritizedCategories[_currentStep];
    
    final categoryNames = {
      'abdominal': 'Abdominal & Digestive',
      'respiratory': 'Respiratory & Breathing',
      'cardiac': 'Cardiac & Chest',
      'pain': 'Pain & Joints',
      'systemic': 'Fever & Systemic',
      'neurological': 'Neurological & Senses',
      'skin': 'Skin Conditions',
      'ent': 'ENT & Throat',
      'urinary': 'Urinary & Urogenital',
      'gynecological': 'Gynecological',
    };
    
    final categoryDescriptions = {
      'abdominal': 'Select all symptoms related to your abdomen, stomach, and digestion:',
      'respiratory': 'Select all symptoms related to breathing and your respiratory system:',
      'cardiac': 'Select all symptoms related to your heart and chest:',
      'pain': 'Select all pain and joint-related symptoms you experience:',
      'systemic': 'Select general systemic symptoms:',
      'neurological': 'Select all neurological and sensory symptoms:',
      'skin': 'Select any skin conditions you have:',
      'ent': 'Select ear, nose, and throat symptoms:',
      'urinary': 'Select any urinary symptoms:',
      'gynecological': 'Select any gynecological symptoms:',
    };

    return {
      'name': categoryNames[category] ?? category,
      'description': categoryDescriptions[category] ?? 'Select symptoms:',
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final activeColor = theme.colorScheme.secondary;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F9FF),
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(80),
        child: NavBar(),
      ),
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
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            'General Health Screening',
            style: theme.textTheme.displaySmall?.copyWith(fontSize: 28),
          ),
          const SizedBox(height: 8),
          Text(
            'Select any symptoms that apply to help narrow down the diagnosis:',
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 32),

          // Screening questions (checkboxes - NOT sequential)
          Expanded(
            child: ListView.builder(
              itemCount: _screeningQuestions.length,
              itemBuilder: (context, index) {
                final q = _screeningQuestions[index];
                final category = q['category']!;
                final isSelected = _selectedCategoryScreens.contains(category);
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: InkWell(
                    onTap: () => _toggleScreeningAnswer(category),
                    borderRadius: BorderRadius.circular(12),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      decoration: BoxDecoration(
                        color: isSelected ? activeColor.withOpacity(0.05) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? activeColor : Colors.grey.shade200,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isSelected ? Icons.check_box : Icons.check_box_outline_blank,
                            color: isSelected ? activeColor : Colors.grey.shade400,
                          ),
                          const SizedBox(width: 16),
                          Flexible(
                            child: Text(
                              q['question']!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: isSelected ? activeColor : const Color(0xFF0F172A),
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 24),

          // Count and action button
          Text(
            'Selected symptom areas: ${_selectedCategoryScreens.length}',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),

          const SizedBox(height: 16),

          ElevatedButton(
            onPressed: _selectedCategoryScreens.isNotEmpty ? _finishScreening : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: activeColor,
              disabledBackgroundColor: Colors.grey.shade200,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: Container(
              width: double.infinity,
              alignment: Alignment.center,
              child: Text(
                'Continue to Detailed Symptoms →',
                style: TextStyle(
                  color: _selectedCategoryScreens.isNotEmpty ? Colors.white : Colors.grey.shade500,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSymptomCard(ThemeData theme, Color activeColor, Size size) {
    final category = _prioritizedCategories[_currentStep];
    final categoryInfo = _getCategoryInfo();
    final symptoms = SYMPTOM_BRANCHES[category] ?? [];
    final progress = (_currentStep + 1) / _prioritizedCategories.length;
    final isHighPriority = _selectedCategoryScreens.contains(category);

    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress bar
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey.shade100,
            color: activeColor,
          ),
          const SizedBox(height: 20),

          // Priority indicator
          if (isHighPriority)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber),
              ),
              child: const Text(
                '★ High Priority (from screening)',
                style: TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),

          const SizedBox(height: 12),

          // Question text
          Text(
            categoryInfo['name'] ?? '',
            style: theme.textTheme.displaySmall?.copyWith(fontSize: 28),
          ),
          const SizedBox(height: 8),
          Text(
            categoryInfo['description'] ?? '',
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 32),

          // Symptoms grid (multi-select)
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 10,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: symptoms.length,
              itemBuilder: (context, index) {
                final symptom = symptoms[index];
                final isSelected = _selectedSymptoms.contains(symptom);
                return _buildSymptomTile(symptom, isSelected, activeColor, theme);
              },
            ),
          ),

          const SizedBox(height: 24),

          // Selected count
          Text(
            'Total selected: ${_selectedSymptoms.length} symptoms',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),

          const SizedBox(height: 16),

          // Navigation buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _backToScreening,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("← Back to Screening", style: TextStyle(color: Colors.black54)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: _currentStep > 0 ? _prevCategory : null,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("← Previous", style: TextStyle(color: Colors.black54)),
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: Text(
                    _currentStep == _prioritizedCategories.length - 1 ? 'Get Results →' : 'Next →',
                    style: const TextStyle(
                      color: Colors.white,
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

  Widget _buildSymptomTile(String symptom, bool isSelected, Color activeColor, ThemeData theme) {
    return InkWell(
      onTap: () => _toggleSymptom(symptom),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withOpacity(0.1) : const Color(0xFFF8FAFC),
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
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

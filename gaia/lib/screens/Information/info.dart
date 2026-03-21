import 'package:flutter/material.dart';
import 'package:gaia/values/values.dart';
import 'package:gaia/widgets/navbar.dart';

// A simple model to hold the name and description
class MedicalItem {
  final String name;
  final String description;

  const MedicalItem(this.name, this.description);
}

class DiseasesAndSymptomsPage extends StatefulWidget {
  const DiseasesAndSymptomsPage({Key? key}) : super(key: key);

  @override
  State<DiseasesAndSymptomsPage> createState() => _DiseasesAndSymptomsPageState();
}

class _DiseasesAndSymptomsPageState extends State<DiseasesAndSymptomsPage> {
  // State variable to hold the current search text
  String _searchQuery = '';

  // --- FULL DISEASES DATASET ---
  final List<MedicalItem> diseases = const [
    MedicalItem('panic disorder', 'An anxiety disorder characterized by unexpected and repeated panic attacks.'),
    MedicalItem('vaginitis', 'Inflammation of the vagina that can result in discharge, itching, and pain.'),
    MedicalItem('problem during pregnancy', 'General complications or abnormalities occurring during gestation.'),
    MedicalItem('acute pancreatitis', 'Sudden inflammation of the pancreas.'),
    MedicalItem('asthma', 'A condition in which the airways narrow and swell, causing breathing difficulties.'),
    MedicalItem('infectious gastroenteritis', 'Stomach and intestinal inflammation caused by a viral, bacterial, or parasitic infection.'),
    MedicalItem('acute sinusitis', 'Short-term inflammation of the tissue lining the sinuses.'),
    MedicalItem('cornea infection', 'An infection of the clear front surface of the eye (keratitis).'),
    MedicalItem('marijuana abuse', 'Overuse or dependence on cannabis.'),
    MedicalItem('bursitis', 'Inflammation of the fluid-filled pads (bursae) that act as cushions at the joints.'),
    MedicalItem('actinic keratosis', 'A rough, scaly patch on the skin caused by years of sun exposure.'),
    MedicalItem('chronic obstructive pulmonary disease (copd)', 'A group of lung diseases that block airflow and make it difficult to breathe.'),
    MedicalItem('spondylosis', 'Age-related wear and tear of the spinal disks.'),
    MedicalItem('injury to the arm', 'Physical trauma or damage to the upper limb.'),
    MedicalItem('complex regional pain syndrome', 'Chronic arm or leg pain developing after injury, surgery, stroke, or heart attack.'),
    MedicalItem('injury to the trunk', 'Trauma to the chest, abdomen, or back.'),
    MedicalItem('vulvodynia', 'Chronic, unexplained pain in the area around the opening of the vagina.'),
    MedicalItem('concussion', 'A brain injury caused by a blow to the head.'),
    MedicalItem('hypoglycemia', 'Dangerously low blood sugar levels.'),
    MedicalItem('hiatal hernia', 'A condition where part of the stomach pushes up through the diaphragm.'),
    MedicalItem('allergy', 'Immune system reaction to a foreign substance (allergen).'),
    MedicalItem('acute bronchospasm', 'Sudden constriction of the muscles in the walls of the bronchioles.'),
    MedicalItem('degenerative disc disease', 'Osteoarthritis of the spine, usually in the neck or lower back.'),
    MedicalItem('pain after an operation', 'Post-surgical discomfort or localized pain.'),
    MedicalItem('injury to the leg', 'Physical damage or trauma to the lower limb.'),
    MedicalItem('gout', 'A form of arthritis characterized by severe pain, redness, and tenderness in joints (often the big toe).'),
    MedicalItem('otitis media', 'Inflammation or infection of the middle ear.'),
    MedicalItem('acute kidney injury', 'Sudden episode of kidney failure or damage.'),
    MedicalItem('threatened pregnancy', 'Vaginal bleeding during early pregnancy indicating a potential miscarriage.'),
    MedicalItem('gum disease', 'Infection of the tissues that hold teeth in place (gingivitis/periodontitis).'),
    MedicalItem('gastrointestinal hemorrhage', 'Bleeding anywhere in the digestive tract.'),
    MedicalItem('anxiety', 'Intense, excessive, and persistent worry and fear about everyday situations.'),
    MedicalItem('conjunctivitis due to allergy', 'Eye inflammation caused by an allergic reaction (allergic pink eye).'),
    MedicalItem('drug reaction', 'Adverse physical response to a medication.'),
    MedicalItem('macular degeneration', 'An eye disease that causes vision loss in the center of the field of vision.'),
    MedicalItem('pneumonia', 'Infection that inflames air sacs in one or both lungs.'),
    MedicalItem('vaginal cyst', 'A fluid-filled sac or lump within the vaginal wall.'),
    MedicalItem('carpal tunnel syndrome', 'Numbness, tingling, or weakness in the hand caused by a pinched nerve in the wrist.'),
    MedicalItem('nose disorder', 'Any anatomical or functional problem affecting the nasal passages.'),
    MedicalItem('dental caries', 'Tooth decay or cavities.'),
    MedicalItem('hypertensive heart disease', 'Heart conditions caused by high blood pressure.'),
    MedicalItem('seasonal allergies (hay fever)', 'Allergic reaction to pollen from trees, grasses, and weeds.'),
    MedicalItem('fungal infection of the hair', 'Fungal invasion of the hair shaft (e.g., ringworm of the scalp).'),
    MedicalItem('rectal disorder', 'A medical condition affecting the rectum (e.g., prolapse, bleeding).'),
    MedicalItem('stye', 'A red, painful lump near the edge of the eyelid.'),
    MedicalItem('heart attack', 'Blockage of blood flow to the heart muscle.'),
    MedicalItem('obstructive sleep apnea (osa)', 'Intermittent airflow blockage during sleep.'),
    MedicalItem('psoriasis', 'A skin condition that causes red, itchy scaly patches.'),
    MedicalItem('arthritis of the hip', 'Inflammation and wearing away of the cartilage in the hip joint.'),
    MedicalItem('sickle cell crisis', 'Severe pain caused by blocked blood vessels in sickle cell anemia.'),
    MedicalItem('otitis externa (swimmer\'s ear)', 'Infection of the outer ear canal.'),
    MedicalItem('acute bronchiolitis', 'Lung infection that causes inflammation and congestion in the small airways (bronchioles) of infants.'),
    MedicalItem('pyogenic skin infection', 'A bacterial skin infection that produces pus.'),
    MedicalItem('noninfectious gastroenteritis', 'Stomach inflammation not caused by an infection (e.g., food intolerance, medications).'),
    MedicalItem('benign prostatic hyperplasia (bph)', 'Age-associated prostate gland enlargement that can cause urination difficulty.'),
    MedicalItem('spinal stenosis', 'Narrowing of the spaces within the spine, which can put pressure on the nerves.'),
    MedicalItem('acute bronchitis', 'Short-term inflammation of the bronchial tubes.'),
    MedicalItem('croup', 'An upper airway infection that blocks breathing and has a distinctive barking cough.'),
    MedicalItem('idiopathic excessive menstruation', 'Abnormally heavy or prolonged menstrual bleeding with no known cause.'),
    MedicalItem('ear drum damage', 'A tear or hole in the tympanic membrane.'),
    MedicalItem('temporary or benign blood in urine', 'Non-harmful, short-lived presence of red blood cells in the urine.'),
    MedicalItem('common cold', 'A viral infection of the nose and throat.'),
    MedicalItem('depression', 'A mood disorder causing a persistent feeling of sadness and loss of interest.'),
    MedicalItem('idiopathic irregular menstrual cycle', 'Unpredictable menstrual cycles with no identified underlying cause.'),
    MedicalItem('schizophrenia', 'A severe mental disorder affecting how a person thinks, feels, and behaves.'),
    MedicalItem('sepsis', 'A life-threatening, extreme body response to an infection.'),
    MedicalItem('cholecystitis', 'Inflammation of the gallbladder, often caused by gallstones.'),
    MedicalItem('cystitis', 'Inflammation of the bladder, usually caused by a urinary tract infection.'),
    MedicalItem('hemorrhoids', 'Swollen and inflamed veins in the rectum and anus.'),
    MedicalItem('contact dermatitis', 'A skin rash caused by contact with a certain substance.'),
    MedicalItem('sinus bradycardia', 'A slower-than-normal heart rate.'),
    MedicalItem('pelvic inflammatory disease', 'An infection of the female reproductive organs.'),
    MedicalItem('liver disease', 'Any of various conditions that damage the liver and prevent it from functioning well.'),
    MedicalItem('chronic constipation', 'Infrequent bowel movements or difficult passage of stools that persists for weeks.'),
    MedicalItem('skin polyp', 'A small, benign growth protruding from the skin surface (skin tag).'),
    MedicalItem('brachial neuritis', 'Sudden, severe shoulder and arm pain followed by weakness.'),
    MedicalItem('esophagitis', 'Inflammation that damages the tube running from the throat to the stomach.'),
    MedicalItem('diverticulitis', 'Inflammation or infection of small pouches in the digestive tract.'),
    MedicalItem('sprain or strain', 'Stretching or tearing of ligaments (sprain) or muscles/tendons (strain).'),
    MedicalItem('idiopathic painful menstruation', 'Menstrual cramps occurring without an identifiable pelvic disease.'),
    MedicalItem('eustachian tube dysfunction', 'Failure of the tube connecting the middle ear to the throat to open and close properly.'),
    MedicalItem('appendicitis', 'Inflammation of the appendix.'),
    MedicalItem('hyperemesis gravidarum', 'Extreme, persistent nausea and vomiting during pregnancy.'),
    MedicalItem('urinary tract infection', 'An infection in any part of the urinary system.'),
    MedicalItem('peripheral nerve disorder', 'Damage to the nerves outside the brain and spinal cord (peripheral neuropathy).'),
    MedicalItem('sebaceous cyst', 'A slow-growing, noncancerous bump beneath the skin containing sebum.'),
    MedicalItem('spontaneous abortion', 'Loss of a pregnancy before the 20th week (miscarriage).'),
    MedicalItem('gallstone', 'A hardened deposit of digestive fluid that forms in the gallbladder.'),
    MedicalItem('multiple sclerosis', 'A disease in which the immune system eats away at the protective covering of nerves.'),
    MedicalItem('angina', 'A type of chest pain caused by reduced blood flow to the heart.'),
    MedicalItem('skin pigmentation disorder', 'Conditions that affect the color of the skin (e.g., vitiligo, melasma).'),
    MedicalItem('personality disorder', 'A rigid and unhealthy pattern of thinking, functioning, and behaving.'),
    MedicalItem('strep throat', 'A bacterial infection that causes a sore, scratchy throat.'),
    MedicalItem('developmental disability', 'Chronic conditions that are due to mental or physical impairment in childhood.'),
    MedicalItem('chronic back pain', 'Back pain lasting for 12 weeks or longer.'),
    MedicalItem('heart failure', 'A chronic condition in which the heart doesn\'t pump blood as well as it should.'),
    MedicalItem('conjunctivitis', 'Inflammation or infection of the outer membrane of the eyeball (pink eye).'),
    MedicalItem('herniated disk', 'A problem with a rubbery disk between the spinal bones pushing on a nerve.'),
    MedicalItem('diaper rash', 'Inflamed, red skin on a baby\'s bottom.'),
    MedicalItem('eczema', 'A condition that makes the skin red and itchy (atopic dermatitis).'),
  ];

  // --- FULL SYMPTOMS DATASET ---
  final List<MedicalItem> symptoms = const [
    MedicalItem('anxiety and nervousness', 'Feelings of worry, dread, or unease.'),
    MedicalItem('depression', 'Feelings of severe despondency and dejection.'),
    MedicalItem('depressive or psychotic symptoms', 'Mood drops or losing touch with reality.'),
    MedicalItem('insomnia', 'Inability to sleep.'),
    MedicalItem('abusing alcohol / drug abuse', 'Excessive or destructive use of substances.'),
    MedicalItem('hostile behavior / excessive anger / temper problems', 'Aggressive, furious, or explosive actions.'),
    MedicalItem('restlessness', 'Inability to rest or relax.'),
    MedicalItem('fears and phobias', 'Irrational terror of objects or situations.'),
    MedicalItem('delusions or hallucinations', 'Seeing/hearing things that aren\'t there or holding false beliefs.'),
    MedicalItem('obsessions and compulsions', 'Unwanted repeated thoughts and actions.'),
    MedicalItem('antisocial behavior', 'Actions that harm or lack consideration for the well-being of others.'),
    MedicalItem('hysterical behavior', 'Exaggerated or uncontrollable emotion.'),
    MedicalItem('low self-esteem', 'Lack of confidence in one\'s own worth.'),
    MedicalItem('disturbance of memory', 'Forgetfulness or confusion.'),
    MedicalItem('sleepiness / fatigue', 'Extreme tiredness or drowsiness.'),
    MedicalItem('shortness of breath / difficulty breathing / breathing fast / hurts to breath', 'Various struggles with drawing air into the lungs.'),
    MedicalItem('sharp chest pain / burning chest pain / chest tightness', 'Different sensations of pain or pressure in the chest area.'),
    MedicalItem('palpitations / irregular heartbeat / increased/decreased heart rate', 'Feeling the heart beating too hard, too fast, too slow, or skipping beats.'),
    MedicalItem('cough / coughing up sputum / hemoptysis (coughing blood)', 'Expelling air from the lungs, sometimes with mucus or blood.'),
    MedicalItem('wheezing', 'A high-pitched whistling sound made while breathing.'),
    MedicalItem('apnea', 'Temporary cessation of breathing, especially during sleep.'),
    MedicalItem('abnormal breathing sounds', 'Noises like crackles, stridor, or rhonchi while breathing.'),
    MedicalItem('congestion in chest', 'Mucus buildup in the lungs.'),
    MedicalItem('headache / frontal headache', 'Pain in the head.'),
    MedicalItem('dizziness / fainting', 'Feeling lightheaded or briefly losing consciousness.'),
    MedicalItem('hoarse voice / difficulty speaking', 'Rough voice or trouble articulating words.'),
    MedicalItem('sore throat / throat swelling / swollen or red tonsils', 'Pain, inflammation, or enlargement in the throat.'),
    MedicalItem('difficulty in swallowing', 'Trouble moving food from mouth to stomach.'),
    MedicalItem('nasal congestion / coryza / sneezing / nosebleed / sinus congestion', 'Symptoms involving nasal blockages, discharge, or bleeding.'),
    MedicalItem('lip swelling / mouth ulcer / toothache / mouth dryness / jaw swelling / gum pain / bleeding gums', 'Issues within or around the oral cavity.'),
    MedicalItem('facial pain / symptoms of the face', 'Discomfort or anomalies localized to the face.'),
    MedicalItem('neck pain / neck mass / neck swelling', 'Discomfort or lumps in the neck region.'),
    MedicalItem('diminished vision / double vision / blindness / spots or clouds', 'Varying degrees of sight impairment or visual artifacts.'),
    MedicalItem('pain in eye / eye burns or stings / eye redness / itchiness / bleeding', 'Discomfort, inflammation, or hemorrhage of the eye.'),
    MedicalItem('abnormal movement of eyelid / mass on eyelid / swollen eye / eyelid lesion', 'Structural or functional eyelid issues.'),
    MedicalItem('white discharge from eye / lacrimation (tearing)', 'Fluid or pus coming from the eye.'),
    MedicalItem('foreign body sensation in eye', 'The feeling that something is stuck in the eye.'),
    MedicalItem('symptoms of eye', 'General ocular complaints.'),
    MedicalItem('diminished hearing / ringing in ear / plugged feeling in ear', 'Hearing loss or internal ear noises (tinnitus) and blockages.'),
    MedicalItem('ear pain / itchy ear(s) / redness in ear / bleeding from ear / fluid / pus', 'Signs of ear infection, trauma, or irritation.'),
    MedicalItem('sharp abdominal pain / burning / lower / upper / side pain', 'Specific regional pains in the belly.'),
    MedicalItem('nausea / vomiting / vomiting blood', 'Feeling sick to the stomach and expelling stomach contents.'),
    MedicalItem('diarrhea / constipation / chronic constipation', 'Loose, watery stools or difficulty passing stools.'),
    MedicalItem('blood in stool / melena / rectal bleeding', 'Signs of gastrointestinal bleeding.'),
    MedicalItem('heartburn / regurgitation', 'Acid backup or bringing swallowed food up again.'),
    MedicalItem('stomach bloating', 'Swelling of the belly due to gas.'),
    MedicalItem('changes in stool appearance', 'Altered color, texture, or shape of feces.'),
    MedicalItem('pain of the anus / itching / mass or swelling around the anus', 'Discomfort or physical abnormalities at the rectum end.'),
    MedicalItem('decreased appetite', 'Reduced desire to eat.'),
    MedicalItem('retention of urine / painful urination / involuntary / frequent / hesitancy', 'Problems related to holding, passing, or the frequency of urine.'),
    MedicalItem('blood in urine / unusual color or odor to urine', 'Visual or olfactory abnormalities in urine.'),
    MedicalItem('pelvic pain / suprapubic pain / groin pain', 'Pain in the lower torso.'),
    MedicalItem('vaginal itching / vaginal discharge / vaginal pain / vaginal redness', 'Discomfort or fluids from the vagina.'),
    MedicalItem('pain during intercourse / impotence', 'Sexual dysfunction or pain.'),
    MedicalItem('symptoms of the scrotum and testes / swelling / pain', 'Male reproductive organ issues.'),
    MedicalItem('symptoms of prostate / bladder / kidneys / kidney mass', 'General issues or masses related to specific urinary or male organs.'),
    MedicalItem('intermenstrual bleeding / blood clots / heavy menstrual flow / unpredictable menstruation', 'Menstrual cycle irregularities and discomforts.'),
    MedicalItem('hot flashes', 'Sudden feelings of intense body heat (often menopausal).'),
    MedicalItem('back pain / low back pain / back cramps or spasms / back mass', 'Various issues in the spine or back muscles.'),
    MedicalItem('leg pain / hip pain / arm pain / hand or finger pain / wrist / knee / ankle / shoulder', 'Joint and limb-specific pain.'),
    MedicalItem('leg swelling / hip stiffness / hand swelling / wrist swelling / arm swelling', 'Swelling (edema) or stiffness in extremities and joints.'),
    MedicalItem('bones are painful', 'Aching sensation inside the bones.'),
    MedicalItem('weakness / focal weakness', 'Lack of physical strength in specific areas.'),
    MedicalItem('problems with movement / abnormal involuntary movements', 'Tics, tremors, or impaired mobility.'),
    MedicalItem('loss of sensation / paresthesia', 'Numbness or "pins and needles".'),
    MedicalItem('arm lump or mass / hand or finger lump', 'Physical bumps on the upper extremities.'),
    MedicalItem('abnormal appearing skin / skin lesion / skin growth / skin moles / warts', 'Physical blemishes, bumps, or discolorations on the skin.'),
    MedicalItem('acne or pimples', 'Infected or inflamed sebaceous glands.'),
    MedicalItem('skin swelling / peripheral edema', 'Accumulation of fluid under the skin.'),
    MedicalItem('itching of skin / itchy scalp / skin rash / allergic reaction', 'Systemic or localized allergic or irritant responses.'),
    MedicalItem('skin dryness, peeling, scaliness, or roughness / irritation', 'Textural and inflammatory skin problems.'),
    MedicalItem('irregular appearing nails', 'Discolored, brittle, or deformed nails.'),
    MedicalItem('fever / chills / sweating / feeling ill / ache all over / flu-like syndrome', 'General signs of sickness and systemic infection.'),
    MedicalItem('jaundice', 'Yellowing of the skin or eyes (liver issue).'),
    MedicalItem('weight gain', 'Unintentional or rapid increase in body mass.'),
    MedicalItem('lack of growth', 'Failure to thrive or grow at standard rates in children.'),
    MedicalItem('irritable infant / infant feeding problem', 'Fussy baby or difficulties nursing/taking a bottle.'),
    MedicalItem('pain during pregnancy / spotting or bleeding / uterine contractions / infertility', 'Reproductive or gestational issues and symptoms.'),
  ];

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    // Filter the lists based on the search query
    final filteredDiseases = diseases.where((item) {
      return item.name.toLowerCase().contains(_searchQuery) || 
             item.description.toLowerCase().contains(_searchQuery);
    }).toList();

    final filteredSymptoms = symptoms.where((item) {
      return item.name.toLowerCase().contains(_searchQuery) || 
             item.description.toLowerCase().contains(_searchQuery);
    }).toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.white,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(220.0), 
          child: Container(
            color: AppColors.white,
            child: Column(
              children: [
                // 1. Navigation Bar
                SizedBox(
                  height: 72.0,
                  width: size.width * 0.7,
                  child: const Center(child: NavBar(showLogin: true)),
                ),
                
                // 2. Search Bar
                SizedBox(
                  width: size.width * 0.7,
                  child: Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.sm, bottom: AppSpacing.lg),
                    child: TextField(
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value.toLowerCase();
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Search for a disease or symptom...',
                        hintStyle: TextStyle(color: AppColors.gray[500]),
                        prefixIcon: Icon(Icons.search, color: AppColors.gray[500]),
                        filled: true,
                        fillColor: AppColors.gray[100],
                        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: AppSpacing.md),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                ),

                // 3. Tabs (Counts removed)
                SizedBox(
                  width: size.width * 0.7,
                  child: TabBar(
                    indicatorColor: AppColors.purple,
                    labelColor: AppColors.purple,
                    unselectedLabelColor: AppColors.gray[700],
                    labelStyle: const TextStyle(
                      fontSize: 16, 
                      fontWeight: FontWeight.bold
                    ),
                    tabs: const [
                      Tab(text: 'Diseases'),
                      Tab(text: 'Symptoms'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        body: Center(
          child: SizedBox(
            width: size.width * 0.7,
            child: TabBarView(
              children: [
                // Pass the FILTERED lists to the builder instead of the full lists
                _buildDataList(filteredDiseases, Icons.medical_services_outlined, AppColors.turquoise),
                _buildDataList(filteredSymptoms, Icons.personal_injury_outlined, AppColors.pink),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDataList(List<MedicalItem> items, IconData icon, Color iconColor) {
    if (items.isEmpty) {
      return Center(
        child: Text(
          'No results found for "$_searchQuery"',
          style: TextStyle(
            fontSize: 16,
            color: AppColors.gray[500],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      itemCount: items.length,
      separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) {
        final item = items[index];
        return Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.gray[100], 
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.gray[200]!), 
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name.toUpperCase(),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.gray[900],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      item.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.gray[800],
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
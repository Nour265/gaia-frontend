import 'package:flutter/material.dart';

class BlogArticleSection {
  const BlogArticleSection({required this.title, required this.body});

  final String title;
  final String body;
}

class BlogArticle {
  const BlogArticle({
    required this.id,
    required this.category,
    required this.title,
    required this.excerpt,
    required this.readTime,
    required this.publishedOn,
    required this.icon,
    required this.sections,
    required this.keyTakeaway,
  });

  final String id;
  final String category;
  final String title;
  final String excerpt;
  final String readTime;
  final String publishedOn;
  final IconData icon;
  final List<BlogArticleSection> sections;
  final String keyTakeaway;
}

const List<BlogArticle> gaiaBlogArticles = [
  BlogArticle(
    id: 'symptom-tracking',
    category: 'GUIDE',
    title: 'How to track symptoms before a doctor visit',
    excerpt:
        'A practical checklist that helps you capture details clinicians need for faster and safer decisions.',
    readTime: '6 min read',
    publishedOn: 'March 18, 2026',
    icon: Icons.assignment_outlined,
    keyTakeaway:
        'Consistent tracking makes consultations clearer and helps doctors identify urgency earlier.',
    sections: [
      BlogArticleSection(
        title: 'Capture timing and pattern',
        body:
            'Write down when the symptom started, how long episodes last, and whether it gets better or worse at specific times of day.',
      ),
      BlogArticleSection(
        title: 'Record intensity, not just presence',
        body:
            'Use a simple scale from 1 to 10 and include what you were doing when intensity changed. This gives context that improves triage quality.',
      ),
      BlogArticleSection(
        title: 'Note related signs',
        body:
            'Include associated symptoms such as fever, dizziness, or shortness of breath. The combination often matters more than one symptom alone.',
      ),
    ],
  ),
  BlogArticle(
    id: 'monthly-update',
    category: 'UPDATE',
    title: 'What is new in GAIA this month',
    excerpt:
        'This release focuses on clearer urgency signals, smoother question flow, and better result readability.',
    readTime: '4 min read',
    publishedOn: 'March 17, 2026',
    icon: Icons.new_releases_outlined,
    keyTakeaway:
        'The latest updates reduce decision friction so users can act faster with more confidence.',
    sections: [
      BlogArticleSection(
        title: 'Clearer urgency labels',
        body:
            'Urgency recommendations now use plain language and stronger visual contrast to distinguish monitor, clinic, and urgent care paths.',
      ),
      BlogArticleSection(
        title: 'Faster answer flow',
        body:
            'Question transitions were simplified to reduce repetition and keep focus on factors that change next-step recommendations.',
      ),
      BlogArticleSection(
        title: 'Improved guidance summaries',
        body:
            'Result cards now prioritize actions first, then supporting context, so users understand what to do before reading deeper details.',
      ),
    ],
  ),
  BlogArticle(
    id: 'home-vs-urgent-care',
    category: 'WELLNESS',
    title: 'When to monitor at home vs seek urgent care',
    excerpt:
        'Use these practical checks to decide whether to keep monitoring symptoms or get immediate medical support.',
    readTime: '7 min read',
    publishedOn: 'March 15, 2026',
    icon: Icons.health_and_safety_outlined,
    keyTakeaway:
        'If symptoms escalate quickly, involve breathing, consciousness, or severe pain, urgent care is the safer default.',
    sections: [
      BlogArticleSection(
        title: 'When home monitoring is reasonable',
        body:
            'Mild symptoms that are stable, short-lived, and improving with rest can often be monitored while tracking progression.',
      ),
      BlogArticleSection(
        title: 'Red flags that require urgent care',
        body:
            'Seek urgent care for chest pain, breathing difficulty, confusion, fainting, high persistent fever, or rapidly worsening symptoms.',
      ),
      BlogArticleSection(
        title: 'Prepare before you go',
        body:
            'Bring your symptom timeline, current medications, and known conditions. This shortens assessment time and improves handoff quality.',
      ),
    ],
  ),
  BlogArticle(
    id: 'privacy-explainer',
    category: 'PRIVACY',
    title: 'How GAIA handles your health data',
    excerpt:
        'A plain-language overview of how we minimize data collection and protect sensitive user input.',
    readTime: '5 min read',
    publishedOn: 'March 12, 2026',
    icon: Icons.lock_outline,
    keyTakeaway:
        'A privacy-first approach starts with collecting less, storing less, and clearly explaining what is used.',
    sections: [
      BlogArticleSection(
        title: 'Data minimization by default',
        body:
            'GAIA is designed to request only details needed for decision support, avoiding unnecessary personal data.',
      ),
      BlogArticleSection(
        title: 'Purpose-limited processing',
        body:
            'Inputs are used to generate triage guidance and are not repurposed for unrelated workflows.',
      ),
      BlogArticleSection(
        title: 'Transparent user communication',
        body:
            'Privacy expectations are presented in plain language so users understand what is collected and why.',
      ),
    ],
  ),
];

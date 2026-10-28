import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/knowledge_item.dart';

class KnowledgeService {
  static final KnowledgeService _instance = KnowledgeService._internal();
  factory KnowledgeService() => _instance;
  KnowledgeService._internal();

  List<KnowledgeItem> _items = [];
  bool _isLoaded = false;

  bool get isLoaded => _isLoaded;
  List<KnowledgeItem> get items => _items;

  final List<Map<String, String>> suggestions = [
    {
      'id': 'electricien-laayoune',
      'fr': 'Comment trouver un électricien à Laayoune ?',
      'ar': 'كيف أجد كهربائياً في العيون؟',
      'darija': 'كيفاش نلقى تريسيان ف العيون؟',
    },
    {
      'id': 'artisanat-patrimoine',
      'fr': 'Quels savoir-faire sont valorisés ?',
      'ar': 'ما المهارات التي تُثمّنها المنصة؟',
      'darija': 'شنو هي الصنعة اللي كتدعمها المنصة؟',
    },
    {
      'id': 'inscription-artisan',
      'fr': 'Comment un artisan peut-il rejoindre Le7rayfi ?',
      'ar': 'كيف يمكن للحرفي الانضمام إلى Le7rayfi؟',
      'darija': 'كيفاش يقدر الحرايفي يتسجل ف المنصة؟',
    },
    {
      'id': 'hors-ligne',
      'fr': 'Est-ce que ça marche sans Internet ?',
      'ar': 'هل يعمل دون إنترنت؟',
      'darija': 'واش هادشي خدام بلا أنترنيت؟',
    },
  ];

  Future<void> init() async {
    if (_isLoaded) return;
    try {
      final jsonStr = await rootBundle.loadString('assets/knowledge.json');
      final Map<String, dynamic> data = json.decode(jsonStr);
      final list = data['items'] as List<dynamic>? ?? [];
      _items = list.map((e) => KnowledgeItem.fromJson(e as Map<String, dynamic>)).toList();
      _isLoaded = true;
    } catch (e) {
      // Fallback minimum knowledge
      _items = [
        KnowledgeItem(
          id: 'accueil',
          keywords: ['bonjour', 'salut', 'salam', 'مرحبا', 'السلام عليكم', 'أهلا'],
          fr: 'Salam et bienvenue. Je suis le7raifiBot Mini V1, assistant robot pour les savoir-faire et artisans du Sud.',
          ar: 'السلام عليكم ومرحباً بكم. أنا حريف بوت النسخة الأولى، مساعد للمهن والحرف في الأقاليم الجنوبية.',
          darija: 'السلام عليكم ومرحباً بكم. أنا حريف بوت، الروبوت ديالكم للمهن والصنعة ف الأقاليم الجنوبية.',
        ),
      ];
      _isLoaded = true;
    }
  }

  String normalizeText(String input) {
    String text = input.toLowerCase();
    // Normalize Arabic letters and diacritics
    text = text.replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), ''); // remove harakat
    text = text.replaceAll(RegExp(r'[إأآا]'), 'ا');
    text = text.replaceAll('ة', 'ه');
    text = text.replaceAll('ى', 'ي');
    text = text.replaceAll('ؤ', 'و');
    text = text.replaceAll('ئ', 'ي');
    // Normalize French accents
    text = text
        .replaceAll(RegExp(r'[éèêë]'), 'e')
        .replaceAll(RegExp(r'[àâä]'), 'a')
        .replaceAll(RegExp(r'[îï]'), 'i')
        .replaceAll(RegExp(r'[ôö]'), 'o')
        .replaceAll(RegExp(r'[ùûü]'), 'u')
        .replaceAll('ç', 'c');
    // Remove punctuation
    text = text.replaceAll(RegExp(r'[^\w\s\u0600-\u06FF]'), ' ');
    return text.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  KnowledgeItem? findAnswer(String question) {
    if (_items.isEmpty) return null;
    final normalized = normalizeText(question);
    if (normalized.isEmpty) return null;

    final queryWords = normalized.split(' ').where((w) => w.length > 1).toList();
    if (queryWords.isEmpty) return null;

    KnowledgeItem? bestItem;
    int maxScore = 0;

    for (final item in _items) {
      int score = 0;
      final normKeywords = item.keywords.map(normalizeText).toList();

      // Check full keyword phrase match
      for (final kw in normKeywords) {
        if (kw.isNotEmpty && normalized.contains(kw)) {
          score += 6;
        }
        for (final word in queryWords) {
          if (kw.split(' ').contains(word)) {
            score += 3;
          } else if (kw.contains(word)) {
            score += 1;
          }
        }
      }

      // Check content match in FR/AR
      final normFr = normalizeText(item.fr);
      final normAr = normalizeText(item.ar);
      final normDarija = item.darija != null ? normalizeText(item.darija!) : '';

      for (final word in queryWords) {
        if (normFr.contains(word)) score += 1;
        if (normAr.contains(word)) score += 1;
        if (normDarija.isNotEmpty && normDarija.contains(word)) score += 1;
      }

      if (score > maxScore) {
        maxScore = score;
        bestItem = item;
      }
    }

    if (maxScore >= 3) {
      return bestItem;
    }
    return null;
  }
}

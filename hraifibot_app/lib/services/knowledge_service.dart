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

  static const Set<String> _stopWords = {
    'بغيت', 'باغي', 'خاصني', 'خصني', 'عندي', 'كاين', 'كاينة', 'واش', 'شي',
    'ديال', 'ديالي', 'ف', 'عفاك', 'باش', 'فين', 'كنقلب', 'نلقى', 'نصاوب',
    'نصلح', 'ليا', 'ليك', 'لينا', 'دابا', 'هاد', 'هادي', 'هادا', 'شنو',
    'اش', 'أش', 'علاش', 'شكون', 'كيفاش', 'في', 'من', 'على', 'إلى', 'الى',
    'عن', 'مع', 'هل', 'ما', 'كيف', 'لماذا', 'هذا', 'هذه', 'ذلك', 'و', 'او', 'أو',
    'ثم', 'ان', 'أن', 'لا', 'هو', 'هي', 'انا', 'أنا', 'نحن', 'يمكن',
    'مشكل', 'مشكلة', 'عطب', 'خاسر', 'خاسرة', 'بانة', 'بانا'
  };

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

  static const Map<String, List<String>> _synonyms = {
    'trician': ['تريسيان', 'electricien', 'كهربائي', 'الضو'],
    'trissian': ['تريسيان', 'electricien', 'كهربائي', 'الضو'],
    'electricite': ['كهرباء', 'الضو', 'تريسيان', 'electricien'],
    'electricien': ['تريسيان', 'كهربائي', 'الضو'],
    'blombi': ['بلومبي', 'plombier', 'سباك', 'الما'],
    'plombi': ['بلومبي', 'plombier', 'سباك', 'الما'],
    'plombier': ['بلومبي', 'سباك', 'تسرب'],
    'sbagh': ['صباغ', 'peintre', 'صباغة'],
    'sbagha': ['صباغة', 'peinture', 'صباغ'],
    'peintre': ['صباغ', 'صباغة'],
    'peinture': ['صباغة', 'صباغ'],
    'njar': ['نجار', 'menuisier', 'نجارة'],
    'njara': ['نجارة', 'menuiserie', 'نجار'],
    'menuisier': ['نجار', 'نجارة'],
    'menuiserie': ['نجارة', 'نجار'],
    'bennay': ['بناي', 'بناء', 'macon'],
    'macon': ['بناء', 'بناي'],
    'zlayji': ['زلايجي', 'زليج'],
    'soudeur': ['سودور', 'حداد', 'ferronnerie'],
    'haddad': ['حداد', 'ferronnerie', 'سودور'],
    'clim': ['كليماتيزور', 'climatisation', 'مكيف'],
    'climatiseur': ['كليماتيزور', 'climatisation'],
    'climatisation': ['كليماتيزور', 'مكيف'],
    'mekanik': ['ميكانيك', 'mecanicien'],
    'mecanicien': ['ميكانيك', 'mecanicien'],
    'slm': ['سلام', 'salam'],
    'salamo': ['سلام', 'salam'],
    'alaykom': ['عليكم'],
    'chkon': ['شكون', 'من انت'],
    'chkoune': ['شكون', 'من انت'],
    'labas': ['لاباس', 'خير'],
    'cv': ['لاباس', 'خير'],
    'chokran': ['شكرا', 'merci'],
    'choukrane': ['شكرا', 'merci'],
    'merci': ['شكرا', 'remerciement'],
    'layoun': ['العيون', 'laayoune'],
    '3youn': ['العيون', 'laayoune'],
    'laayoune': ['العيون'],
    'glmim': ['كلميم', 'guelmim'],
    'guelmim': ['كلميم'],
    'dakhla': ['الداخلة'],
    'casa': ['الدار البيضاء', 'كازا'],
    'kaza': ['الدار البيضاء', 'كازا'],
    'marrakech': ['مراكش'],
    'kech': ['مراكش'],
    'rabat': ['الرباط'],
    'tanger': ['طنجة'],
    'agadir': ['أكادير', 'اكادير'],
    'fes': ['فاس'],
  };

  Set<String> _extractTokens(String text) {
    final base = normalizeText(text).split(' ').where((w) => w.length > 1).toList();
    final tokens = <String>{};
    for (final token in base) {
      tokens.add(token);
      if (_synonyms.containsKey(token)) {
        tokens.addAll(_synonyms[token]!);
      }
      if (token.length >= 4) {
        final stripped = token
            .replaceFirst(RegExp(r'^وال'), '')
            .replaceFirst(RegExp(r'^بال'), '')
            .replaceFirst(RegExp(r'^فال'), '')
            .replaceFirst(RegExp(r'^كال'), '')
            .replaceFirst(RegExp(r'^لل'), '')
            .replaceFirst(RegExp(r'^ال'), '');
        if (stripped.length >= 3) {
          tokens.add(stripped);
          if (_synonyms.containsKey(stripped)) {
            tokens.addAll(_synonyms[stripped]!);
          }
        }
      }
    }
    return tokens;
  }

  KnowledgeItem? findAnswer(String question) {
    if (_items.isEmpty) return null;
    final normalized = normalizeText(question);
    if (normalized.isEmpty) return null;

    final tokens = _extractTokens(normalized);
    if (tokens.isEmpty) return null;

    KnowledgeItem? bestItem;
    int maxScore = 0;

    for (final item in _items) {
      int score = 0;
      final normKeywords = item.keywords.map(normalizeText).toList();

      // Check full keyword phrase match
      for (final kw in normKeywords) {
        if (kw.isNotEmpty) {
          if (normalized == kw || normalized.contains(kw) || kw.contains(normalized)) {
            score += 6;
          }
        }
        for (final token in tokens) {
          if (kw.split(' ').contains(token)) {
            score += 4;
          } else if (kw.length >= 4 && (kw.startsWith(token) || token.startsWith(kw))) {
            score += 2;
          }
        }
      }

      // Check content match in FR/AR/Darija
      final normFr = normalizeText(item.fr);
      final normAr = normalizeText(item.ar);
      final normDarija = item.darija != null ? normalizeText(item.darija!) : '';

      for (final token in tokens) {
        if (_stopWords.contains(token)) continue;
        if (normFr.contains(token)) score += 1;
        if (normAr.contains(token)) score += 1;
        if (normDarija.isNotEmpty && normDarija.contains(token)) score += 1;
      }

      if (score > maxScore) {
        maxScore = score;
        bestItem = item;
      }
    }

    if (maxScore >= 2) {
      return bestItem;
    }
    return null;
  }
}

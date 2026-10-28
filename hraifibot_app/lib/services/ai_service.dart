import 'dart:async';
import 'knowledge_service.dart';

/// Instant response service for Le7rayfiBot.
/// Grounded on the official platform data from https://www.le7rayfi.com/.
/// Resolves queries instantaneously via local knowledge matching with zero network delay.
class AiService {
  static final AiService _instance = AiService._internal();
  factory AiService() => _instance;
  AiService._internal();

  /// Instant response resolution without AI network latency.
  /// Resolves answers instantaneously via the comprehensive local knowledge engine.
  Future<({String text, bool isLocal})> ask({
    required String question,
    required String lang,
  }) async {
    // 1. Instant local knowledge base match (0ms latency)
    final localAnswer = KnowledgeService().findAnswer(question);
    if (localAnswer != null) {
      return (text: localAnswer.getTextForLang(lang), isLocal: true);
    }

    // 2. Instant friendly fallback
    final fallbacks = {
      'en':
          'I am Le7rayfiBot, your instant assistant for Le7rayfi. You can find verified artisans in your city (electricians, plumbers, carpenters, painters...) directly on le7rayfi.com.',
      'darija':
          'أنا حريف بوت، المساعد السريع ديال منصة لحرايفي. تقدر تقلب على حرايفية معلمين فمدينتك (تريسيان، بلومبي، نجار، صباغ...) ديريكت فـ le7rayfi.com أو سولني على أي خدمة.',
      'ar':
          'أنا حريف بوت، مساعدكم الفوري لمنصة لحرايفي. يمكنك العثور على حرفيين موثوقين في مدينتك (كهربائي، سباك، نجار، صباغ...) مباشرة عبر le7rayfi.com.',
      'fr':
          'Je suis Le7rayfiBot, votre assistant instantané pour Le7rayfi. Vous pouvez trouver des artisans qualifiés dans votre ville (électriciens, plombiers, menuisiers, peintres...) directement sur le7rayfi.com.',
    };
    return (text: fallbacks[lang] ?? fallbacks['darija']!, isLocal: true);
  }
}

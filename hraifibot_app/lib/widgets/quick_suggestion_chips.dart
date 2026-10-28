import 'package:flutter/material.dart';
import '../services/knowledge_service.dart';
import '../services/localization_service.dart';

class QuickSuggestionChips extends StatelessWidget {
  final Function(String question) onSelectQuestion;

  const QuickSuggestionChips({super.key, required this.onSelectQuestion});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalization();
    final lang = loc.currentLang;
    final suggestions = KnowledgeService().suggestions;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: suggestions.map((s) {
          final text = s[lang] ?? s['ar'] ?? s['fr'] ?? '';
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ActionChip(
              avatar: const Icon(Icons.help_outline_rounded, size: 16, color: Color(0xFFD97706)),
              label: Text(
                text,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
              backgroundColor: const Color(0xFF1E293B),
              side: BorderSide(color: const Color(0xFFD97706).withOpacity(0.35)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              onPressed: () => onSelectQuestion(text),
            ),
          );
        }).toList(),
      ),
    );
  }
}

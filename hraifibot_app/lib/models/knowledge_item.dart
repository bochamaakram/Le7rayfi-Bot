class KnowledgeItem {
  final String id;
  final List<String> keywords;
  final String fr;
  final String ar;
  final String? darija;

  KnowledgeItem({
    required this.id,
    required this.keywords,
    required this.fr,
    required this.ar,
    this.darija,
  });

  factory KnowledgeItem.fromJson(Map<String, dynamic> json) {
    return KnowledgeItem(
      id: json['id'] as String? ?? '',
      keywords: (json['keywords'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      fr: json['fr'] as String? ?? '',
      ar: json['ar'] as String? ?? '',
      darija: json['darija'] as String?,
    );
  }

  String getTextForLang(String lang) {
    if (lang == 'darija') {
      return (darija != null && darija!.isNotEmpty) ? darija! : ar;
    } else if (lang == 'ar') {
      return ar;
    } else {
      return fr;
    }
  }
}

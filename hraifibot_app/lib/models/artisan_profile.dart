class LocalizedField {
  final String fr;
  final String ar;
  final String darija;

  const LocalizedField({
    required this.fr,
    required this.ar,
    required this.darija,
  });

  String get(String lang) {
    if (lang == 'darija') return darija.isNotEmpty ? darija : ar;
    if (lang == 'ar') return ar;
    return fr;
  }
}

class ArtisanProfile {
  final String id;
  final LocalizedField name;
  final LocalizedField trade;
  final LocalizedField zone;
  final LocalizedField availability;
  final LocalizedField contact;
  final LocalizedField note;
  final bool isDemo;

  const ArtisanProfile({
    required this.id,
    required this.name,
    required this.trade,
    required this.zone,
    required this.availability,
    required this.contact,
    required this.note,
    this.isDemo = true,
  });

  static const Map<String, ArtisanProfile> demoProfiles = {
    'ART-DEMO-01': ArtisanProfile(
      id: 'ART-DEMO-01',
      name: LocalizedField(
        fr: 'Amina Exemple',
        ar: 'أمينة نموذج',
        darija: 'أمينة نموذج',
      ),
      trade: LocalizedField(
        fr: 'Électricité — profil fictif',
        ar: 'الكهرباء — ملف افتراضي',
        darija: 'تريسيان — ملف تجريبي',
      ),
      zone: LocalizedField(
        fr: 'Laayoune — démonstration',
        ar: 'العيون — عرض تجريبي',
        darija: 'العيون — تجريبي',
      ),
      availability: LocalizedField(
        fr: 'Sur rendez-vous (fictif)',
        ar: 'بموعد مسبق (افتراضي)',
        darija: 'بالموعد (افتراضي)',
      ),
      contact: LocalizedField(
        fr: 'Non communiqué — démonstration',
        ar: 'غير منشور — عرض تجريبي',
        darija: 'غير منشور — تجريبي',
      ),
      note: LocalizedField(
        fr: 'Profil créé uniquement pour tester le parcours NFC/QR. Aucune qualification, disponibilité ou coordonnée réelle n’est affirmée.',
        ar: 'أُنشئ هذا الملف فقط لاختبار مسار NFC/QR. لا يُثبت أي مؤهل أو توفر أو بيانات اتصال حقيقية.',
        darija: 'هاد الملف تصاوب غير باش نجربو NFC و QR. ما كاين حتى رقم ولا التزام حقيقي.',
      ),
      isDemo: true,
    ),
    'ART-DEMO-02': ArtisanProfile(
      id: 'ART-DEMO-02',
      name: LocalizedField(
        fr: 'Mohamed Exemple',
        ar: 'محمد نموذج',
        darija: 'محمد نموذج',
      ),
      trade: LocalizedField(
        fr: 'Artisanat du bois — profil fictif',
        ar: 'حرفة الخشب — ملف افتراضي',
        darija: 'صنعة الخشب والنجارة — ملف تجريبي',
      ),
      zone: LocalizedField(
        fr: 'Tan-Tan — démonstration',
        ar: 'طانطان — عرض تجريبي',
        darija: 'طانطان — تجريبي',
      ),
      availability: LocalizedField(
        fr: 'Atelier ouvert (fictif)',
        ar: 'ورشة مفتوحة (افتراضية)',
        darija: 'الورشة مفتوحة (افتراضي)',
      ),
      contact: LocalizedField(
        fr: 'Non communiqué — démonstration',
        ar: 'غير منشور — عرض تجريبي',
        darija: 'غير منشور — تجريبي',
      ),
      note: LocalizedField(
        fr: 'Profil créé uniquement pour tester le parcours NFC/QR. Aucune qualification, disponibilité ou coordonnée réelle n’est affirmée.',
        ar: 'أُنشئ هذا الملف فقط لاختبار مسار NFC/QR. لا يُثبت أي مؤهل أو توفر أو بيانات اتصال حقيقية.',
        darija: 'هاد الملف تصاوب غير باش نجربو NFC و QR. ما كاين حتى رقم ولا التزام حقيقي.',
      ),
      isDemo: true,
    ),
  };
}

/* =========================================================
   le7raifiBot Mini V1 — Le7rayfi / Sahara Innovation
   Voice-First Robot Assistant Pipeline:
   Web Audio API Visualizer, Lip-Sync Viseme Engine, Web Speech
   Recognition (FR/AR/Darija), Local Knowledge Verification,
   NFC, QR, JSON Sync & PWA Offline.
   ========================================================= */

(function () {
  'use strict';

  /* ---------------- Constantes & Limites ---------------- */
  const APP_VERSION = '1.2.0';
  const LIMITS = Object.freeze({
    items: 200,
    keywords: 35,
    bytes: 180000
  });

  const STORAGE = Object.freeze({
    knowledge: 'le7raifiBot.knowledge.v1',
    lang: 'le7raifiBot.lang.v1',
    syncUrl: 'le7raifiBot.syncUrl.v1',
    speechRate: 'le7raifiBot.speechRate.v1'
  });

  const DEMO_CARD_ID = 'ART-DEMO-01';

  const SUGGESTIONS = Object.freeze([
    {
      label: { darija: '⚡ تريسيان فالعيون', ar: '⚡ كهربائي بالعيون', en: '⚡ Electrician Laayoune', fr: '⚡ Électricien Laâyoune' },
      query: { darija: 'كيفاش نلقى تريسيان ف العيون؟', ar: 'كيف أجد كهربائياً في العيون؟', en: 'How to find an electrician in Laayoune?', fr: 'Comment trouver un électricien à Laayoune ?' }
    },
    {
      label: { darija: '🔧 بلومبي مستعجل', ar: '🔧 سباك مستعجل', en: '🔧 Urgent Plumber', fr: '🔧 Plombier urgent' },
      query: { darija: 'بغيت بلومبي يصاوب ليا الروبيني', ar: 'أحتاج سباكاً لإصلاح تسرب ماء', en: 'I need an emergency plumber for a leaking pipe', fr: 'Je cherche un plombier pour une fuite d\'eau' }
    },
    {
      label: { darija: '🪵 نجار فالداخلة', ar: '🪵 نجار بالداخلة', en: '🪵 Carpenter Dakhla', fr: '🪵 Menuisier Dakhla' },
      query: { darija: 'كنقلب على نجار محترف فالداخلة', ar: 'أبحث عن نجار مؤهل في الداخلة', en: 'Looking for a qualified carpenter in Dakhla', fr: 'Je cherche un menuisier qualifié à Dakhla' }
    },
    {
      label: { darija: '☀️ طاقة شمسية', ar: '☀️ طاقة شمسية', en: '☀️ Solar Energy', fr: '☀️ Énergie solaire' },
      query: { darija: 'شكون كيركب الطاقة الشمسية فالجنوب؟', ar: 'تركيب أنظمة الطاقة الشمسية', en: 'Who installs solar panels in southern Morocco?', fr: 'Installation solaire dans le Sud marocain' }
    },
    {
      label: { darija: '🧵 حرف وصنعة', ar: '🧵 مهارات وتراث', en: '🧵 Sahara Crafts', fr: '🧵 Savoir-faire valorisés' },
      query: { darija: 'شنو هي الصنعة اللي كتدعمها المنصة؟', ar: 'ما المهارات التي تُثمّنها المنصة؟', en: 'What crafts and skills are featured on Le7rayfi?', fr: 'Quels savoir-faire sont valorisés ?' }
    },
    {
      label: { darija: '📱 بلا أنترنيت', ar: '📱 دون إنترنت', en: '📱 Offline Mode', fr: '📱 Sans Internet' },
      query: { darija: 'واش هادشي خدام بلا أنترنيت؟', ar: 'هل يعمل دون إنترنت؟', en: 'Does it work without internet?', fr: 'Est-ce que ça marche sans Internet ?' }
    }
  ]);

  const DEMO_ARTISANS = Object.freeze({
    'ART-DEMO-01': {
      name: { fr: 'Amina Exemple', ar: 'أمينة نموذج', darija: 'أمينة نموذج' },
      trade: { fr: 'Électricité — profil fictif', ar: 'الكهرباء — ملف افتراضي', darija: 'تريسيان — ملف تجريبي' },
      zone: { fr: 'Laayoune — démonstration', ar: 'العيون — عرض تجريبي', darija: 'العيون — تجريبي' },
      availability: { fr: 'Sur rendez-vous (fictif)', ar: 'بموعد مسبق (افتراضي)', darija: 'بالموعد (افتراضي)' },
      contact: { fr: 'Non communiqué — démonstration', ar: 'غير منشور — عرض تجريبي', darija: 'غير منشور — تجريبي' },
      note: {
        fr: 'Profil créé uniquement pour tester le parcours NFC/QR. Aucune qualification, disponibilité ou coordonnée réelle n’est affirmée.',
        ar: 'أُنشئ هذا الملف فقط لاختبار مسار NFC/QR. لا يُثبت أي مؤهل أو توفر أو بيانات اتصال حقيقية.',
        darija: 'هاد الملف تصاوب غير باش نجربو NFC و QR. ما كاين حتى رقم ولا التزام حقيقي.'
      }
    },
    'ART-DEMO-02': {
      name: { fr: 'Mohamed Exemple', ar: 'محمد نموذج', darija: 'محمد نموذج' },
      trade: { fr: 'Artisanat du bois — profil fictif', ar: 'حرفة الخشب — ملف افتراضي', darija: 'صنعة الخشب والنجارة — ملف تجريبي' },
      zone: { fr: 'Tan-Tan — démonstration', ar: 'طانطان — عرض تجريبي', darija: 'طانطان — تجريبي' },
      availability: { fr: 'Atelier ouvert (fictif)', ar: 'ورشة مفتوحة (افتراضية)', darija: 'الورشة مفتوحة (افتراضي)' },
      contact: { fr: 'Non communiqué — démonstration', ar: 'غير منشور — عرض تجريبي', darija: 'غير منشور — تجريبي' },
      note: {
        fr: 'Profil créé uniquement pour tester le parcours NFC/QR. Aucune qualification, disponibilité ou coordonnée réelle n’est affirmée.',
        ar: 'أُنشئ هذا الملف فقط لاختبار مسار NFC/QR. لا يُثبت أي مؤهل أو توفر أو بيانات اتصال حقيقية.',
        darija: 'هاد الملف تصاوب غير باش نجربو NFC و QR. ما كاين حتى رقم ولا التزام حقيقي.'
      }
    }
  });

  /* ---------------- Dictionnaire des Textes & Langues ---------------- */
  const I18N = {
    en: {
      'page.title': 'Le7rayfiBot Mini V1 — Le7rayfi',
      'brand.sub': 'Artisans & Crafts in Morocco',
      'net.online': 'Online',
      'net.offline': 'Offline',
      'mood.idle': 'Ready to listen',
      'mood.listening': 'Listening to you…',
      'mood.thinking': 'Thinking…',
      'mood.speaking': 'Answering you…',
      'mood.error': 'One moment…',
      'btn.mic': 'Tap to speak',
      'btn.micAria': 'Tap to speak to the robot',
      'voice.idle': 'Tap the microphone and speak naturally.',
      'voice.listening': 'Listening… Speak now.',
      'voice.processing': 'Searching responses…',
      'voice.speaking': 'Le7rayfi is answering…',
      'voice.cancel': 'Cancel',
      'voice.youSaid': 'You said:',
      'chat.title': 'Conversation & Chats',
      'chat.inputLabel': 'Your question',
      'chat.placeholder': 'Or type your question here…',
      'chat.send': 'Send',
      'chat.sendAria': 'Send question',
      'chat.clear': 'Clear',
      'chat.voiceSection': 'Voice control',
      'suggestions.label': 'Quick suggestions:',
      'response.emptyTitle': 'Welcome',
      'response.emptyText': 'Salam! I am Le7rayfi, your assistant robot. Tap the mic to talk to me, or choose a suggestion.',
      'response.localTitle': 'Verified Local Response',
      'response.localBadge': 'Verified Local Card',
      'response.unknownTitle': 'Not listed in local V1',
      'response.unknownText': 'This information is not verified in the local offline database. Check le7rayfi.com for live listings.',
      'response.meta': 'Local card · {id}',
      'btn.speak': 'Read aloud',
      'btn.speakAria': 'Read response aloud',
      'btn.stop': 'Stop',
      'btn.stopAria': 'Stop audio playback',
      'btn.replay': 'Replay',
      'btn.replayAria': 'Replay response',
      'btn.tools': 'Tools',
      'btn.optionsAria': 'Open tools and data',
      'actions.title': 'Tools & Demo',
      'btn.nfcRead': 'Read NFC',
      'btn.nfcReadAria': 'Read an NFC card',
      'btn.nfcWrite': 'Write NFC',
      'btn.nfcWriteAria': 'Write demo card to NFC',
      'btn.qr': 'QR Codes',
      'btn.qrAria': 'Show QR codes',
      'nfc.idle': 'NFC ready on Chrome Android over HTTPS.',
      'nfc.unsupported': 'Web NFC unavailable. Use Chrome Android or QR code.',
      'nfc.scanning': 'Hold NFC card to phone…',
      'nfc.writing': 'Hold blank card to program…',
      'nfc.writeOk': 'Card written: {url}',
      'nfc.readOk': 'Card read: {id}',
      'nfc.timeout': 'NFC timed out. Try again.',
      'nfc.permission': 'NFC permission denied.',
      'nfc.error': 'NFC operation failed. Ensure NFC is enabled.',
      'nfc.cancelled': 'NFC operation cancelled.',
      'artisan.badge': 'DEMO PROFILE',
      'artisan.close': 'Close',
      'artisan.closeAria': 'Close artisan card',
      'artisan.speak': 'Read card',
      'artisan.field.trade': 'Trade',
      'artisan.field.zone': 'Zone',
      'artisan.field.availability': 'Availability',
      'artisan.field.contact': 'Contact',
      'artisan.notFoundName': 'Profile not found',
      'artisan.notFoundText': 'This demo only recognizes demo profiles ART-DEMO-01 and ART-DEMO-02.',
      'artisan.sourceLine': '{id} · demo profile · {date}',
      'footer.demo': 'Demonstrator.',
      'footer.demoText': 'Profiles are for demonstration on le7rayfi.com.',
      'footer.version': 'Le7rayfiBot Mini V1',
      'dialog.close': 'Close',
      'qr.title': 'Backup QR Codes',
      'qr.subtitle': 'Use if NFC is unavailable.',
      'qr.tabSite': 'Le7rayfi Site',
      'qr.tabDemo': 'Demo Card',
      'qr.siteCaption': 'QR to the public Le7rayfi website.',
      'qr.openSite': 'Open site',
      'qr.demoCaption': 'QR to demo card ART-DEMO-01.',
      'qr.demoNote': 'The domain bot.le7rayfi.com is an example.',
      'qr.showDemo': 'Show demo profile',
      'qr.currentUrl': 'Current URL',
      'qr.copy': 'Copy',
      'options.title': 'Options and data',
      'options.subtitle': 'Import, export or sync local responses.',
      'options.modeOffline': 'Force 100% offline mode',
      'options.exportKb': 'Export knowledge base (JSON)',
      'options.importKb': 'Import knowledge base (JSON)',
      'options.sync': 'Sync from server',
      'options.syncing': 'Syncing…',
      'options.syncSuccess': 'Sync successful! {count} items updated.',
      'options.syncFail': 'Sync failed. Check connection.',
      'options.reset': 'Reset to defaults',
      'toast.copied': 'URL copied to clipboard!',
      'toast.copyFail': 'Failed to copy URL.',
      'toast.offline': 'Switched to offline mode.',
      'toast.online': 'Connected to network.',
      'toast.demoShown': 'Demo profile displayed.',
      'toast.speakUnsupported': 'Speech synthesis unsupported in this browser.',
      'toast.recUnsupported': 'Speech recognition unsupported. Try Chrome or Android.',
      'toast.recNoMatch': 'No speech recognized. Please speak clearly.',
      'toast.recError': 'Speech error: {err}',
      'error.knowledgeLoad': 'Failed to load knowledge base.',
    },
    fr: {
      'page.title': 'le7raifiBot Mini V1 — Le7rayfi',
      'brand.sub': 'Artisans & savoir-faire',
      'net.online': 'En ligne',
      'net.offline': 'Hors ligne',
      'mood.idle': 'Prêt à vous écouter',
      'mood.listening': 'Je vous écoute…',
      'mood.thinking': 'Je réfléchis…',
      'mood.speaking': 'Je vous réponds…',
      'mood.error': 'Un instant…',
      'btn.mic': 'Appuyer pour parler',
      'btn.micAria': 'Appuyer pour parler au robot',
      'voice.idle': 'Appuyez sur le micro et parlez naturellement.',
      'voice.listening': 'Je vous écoute… Parlez maintenant.',
      'voice.processing': 'Recherche dans les réponses locales…',
      'voice.speaking': 'Le7rayfi vous répond…',
      'voice.cancel': 'Annuler',
      'voice.youSaid': 'Vous avez dit :',
      'chat.title': 'Conversation & Échanges',
      'chat.inputLabel': 'Votre question',
      'chat.placeholder': 'Ou écrivez votre question ici…',
      'chat.send': 'Envoyer',
      'chat.sendAria': 'Envoyer la question',
      'chat.clear': 'Effacer',
      'chat.voiceSection': 'Contrôle vocal',
      'suggestions.label': 'Suggestions rapides :',
      'response.emptyTitle': 'Bienvenue',
      'response.emptyText': 'Salam ! Je suis Le7rayfi, votre assistant robot. Appuyez sur le micro pour me parler, ou choisissez une suggestion.',
      'response.localTitle': 'Réponse locale vérifiée',
      'response.localBadge': 'Fiche locale vérifiée',
      'response.unknownTitle': 'Non répertorié dans la V1',
      'response.unknownText': "Cette information n'est pas encore vérifiée dans la base locale de cette V1. Aucune coordonnée ou disponibilité réelle ne sera inventée.",
      'response.meta': 'Fiche locale · {id}',
      'btn.speak': 'Lire',
      'btn.speakAria': 'Lire la réponse à voix haute',
      'btn.stop': 'Arrêter',
      'btn.stopAria': 'Arrêter la lecture audio',
      'btn.replay': 'Relire',
      'btn.replayAria': 'Relire la réponse',
      'btn.tools': 'Outils',
      'btn.optionsAria': 'Ouvrir les outils et données',
      'actions.title': 'Outils & Démonstration',
      'btn.nfcRead': 'Lire NFC',
      'btn.nfcReadAria': 'Lire une carte NFC',
      'btn.nfcWrite': 'Écrire NFC',
      'btn.nfcWriteAria': 'Écrire la fiche de démo sur NFC',
      'btn.qr': 'QR Codes',
      'btn.qrAria': 'Afficher les codes QR',
      'nfc.idle': 'NFC prêt sur Chrome Android en HTTPS.',
      'nfc.unsupported': 'Web NFC indisponible ici. Utilisez Chrome Android ou le QR code.',
      'nfc.scanning': 'Approchez une carte NFC du téléphone…',
      'nfc.writing': 'Approchez une carte vierge pour écrire la fiche…',
      'nfc.writeOk': 'Carte écrite : {url}',
      'nfc.readOk': 'Carte lue : {id}',
      'nfc.timeout': 'Délai NFC dépassé. Réessayez.',
      'nfc.permission': 'Autorisation NFC refusée.',
      'nfc.error': "L'opération NFC a échoué. Vérifiez l'activation du NFC.",
      'nfc.cancelled': 'Opération NFC annulée.',
      'artisan.badge': 'DONNÉES FICTIVES — DÉMONSTRATION',
      'artisan.close': 'Fermer',
      'artisan.closeAria': 'Fermer la fiche artisan',
      'artisan.speak': 'Lire la fiche',
      'artisan.field.trade': 'Métier',
      'artisan.field.zone': 'Zone',
      'artisan.field.availability': 'Disponibilité',
      'artisan.field.contact': 'Contact',
      'artisan.notFoundName': 'Fiche introuvable',
      'artisan.notFoundText': 'Cette démonstration ne reconnaît que les fiches fictives ART-DEMO-01 et ART-DEMO-02.',
      'artisan.sourceLine': '{id} · fiche démo · {date}',
      'footer.demo': 'Démonstrateur non certifié.',
      'footer.demoText': 'Toutes les fiches sont fictives et ne prouvent aucune disponibilité réelle.',
      'footer.version': 'le7raifiBot Mini V1 · Guide du 23 octobre 2026',
      'dialog.close': 'Fermer',
      'qr.title': 'QR codes de secours',
      'qr.subtitle': 'À utiliser si le NFC n’est pas disponible.',
      'qr.tabSite': 'Site Le7rayfi',
      'qr.tabDemo': 'Fiche démo',
      'qr.siteCaption': 'QR fourni vers le site public Le7rayfi.',
      'qr.openSite': 'Ouvrir le site',
      'qr.demoCaption': 'QR exemple vers la fiche fictive ART-DEMO-01.',
      'qr.demoNote': 'Le domaine bot.le7rayfi.com est un exemple.',
      'qr.showDemo': 'Afficher la fiche démo (simulation)',
      'qr.currentUrl': 'Adresse actuelle',
      'qr.copy': 'Copier',
      'options.title': 'Options et données',
      'options.subtitle': 'Importer, exporter ou synchroniser les réponses locales.',
      'options.voiceSettingsTitle': 'Paramètres de la Voix',
      'options.voiceSelect': 'Voix de synthèse :',
      'options.speechRate': "Vitesse d'élocution :",
      'options.syncTitle': 'Synchronisation HTTPS',
      'options.syncHint': 'Collez l’URL publique d’un fichier JSON autorisé, puis synchronisez.',
      'options.syncLabel': 'URL du JSON',
      'options.syncPlaceholder': 'https://exemple.ma/knowledge.json',
      'options.sync': 'Synchroniser',
      'options.localTitle': 'Fichier local',
      'options.import': 'Importer JSON',
      'options.export': 'Exporter JSON',
      'options.reset': 'Revenir à la base fournie',
      'options.fileHint': 'UTF-8, structure version + items.',
      'options.limitsTitle': 'Limites contrôlées par l’application',
      'options.limit1': '200 fiches maximum.',
      'options.limit2': '35 mots-clés maximum par fiche.',
      'options.limit3': '180 000 octets maximum pour un fichier.',
      'options.privacy': 'Ne placez aucune donnée confidentielle ou personnelle dans le JSON.',
      'options.stats': 'Version {version} · {count} fiches · source : {source} · mise à jour : {date}',
      'micModal.title': 'Microphone requis pour parler',
      'micModal.subtitle': 'Autorisez l’accès au microphone pour dialoguer avec Le7rayfi',
      'micModal.step1Title': 'Autorisation dans le navigateur',
      'micModal.step1Text': 'Cliquez sur l’icône de cadenas ou de réglages à gauche de la barre d’adresse, puis passez le « Microphone » sur Autoriser.',
      'micModal.step2Title': 'Sur mobile Android',
      'micModal.step2Text': 'Vérifiez les paramètres Android : Applications > Chrome > Autorisations > Microphone.',
      'micModal.step3Title': 'Alternative par écrit',
      'micModal.step3Text': 'Vous pouvez également écrire vos questions dans le champ de texte prévu à cet effet.',
      'micModal.retry': 'Réessayer l’accès micro',
      'micModal.useText': 'Continuer par écrit',
      'toast.copied': 'Adresse copiée dans le presse-papier.',
      'toast.copyFail': 'Copie impossible.',
      'toast.speakUnsupported': 'La synthèse vocale n’est pas supportée sur ce navigateur.',
      'toast.micUnsupported': 'Reconnaissance vocale non disponible. Utilisez le champ texte.',
      'toast.micDenied': 'Accès micro refusé. Activez-le dans les permissions du navigateur.',
      'toast.micFailed': 'Aucune parole détectée. Réessayez ou écrivez votre question.',
      'toast.imported': 'Base de connaissances importée et activée.',
      'toast.exported': 'Sauvegarde JSON téléchargée.',
      'toast.synced': 'Base synchronisée avec succès.',
      'toast.reset': 'Base restaurée au fichier d’origine.',
      'toast.writeSuccess': 'Carte NFC écrite avec succès.',
      'toast.readSuccess': 'Carte NFC lue avec succès.',
      'toast.nfcUnsupported': 'NFC non disponible : utilisez les QR codes.',
      'toast.demoShown': 'Fiche fictive ART-DEMO-01 affichée.'
    },
    ar: {
      'page.title': 'حريف بوت النسخة 1 — Le7rayfi',
      'brand.sub': 'الحرفيون والمعارف التقليدية',
      'net.online': 'متصل',
      'net.offline': 'دون اتصال',
      'mood.idle': 'جاهز للاستماع إليك',
      'mood.listening': 'أستمع إليك… تفضل',
      'mood.thinking': 'أفكر في الإجابة…',
      'mood.speaking': 'أتحدث إليك…',
      'mood.error': 'لحظة واحدة…',
      'btn.mic': 'اضغط للتحدث',
      'btn.micAria': 'اضغط للتحدث مع الروبوت',
      'voice.idle': 'اضغط على الميكروفون وتحدث بشكل طبيعي.',
      'voice.listening': 'أستمع إليك… تحدث الآن.',
      'voice.processing': 'أبحث في الإجابات المحلية الموثقة…',
      'voice.speaking': 'حريف يجيبك…',
      'voice.cancel': 'إلغاء',
      'voice.youSaid': 'سؤالك :',
      'chat.title': 'المحادثة والتبادل',
      'chat.inputLabel': 'سؤالك',
      'chat.placeholder': 'أو اكتب سؤالك هنا…',
      'chat.send': 'إرسال',
      'chat.sendAria': 'إرسال السؤال',
      'chat.clear': 'مسح',
      'chat.voiceSection': 'التحكم الصوتي',
      'suggestions.label': 'أسئلة مقترحة :',
      'response.emptyTitle': 'مرحباً بكم',
      'response.emptyText': 'السلام عليكم ! أنا حريف بوت، مساعدكم الروبوتي. اضغطوا على الميكروفون للحديث أو اكتبوا سؤالكم.',
      'response.localTitle': 'إجابة محلية موثقة',
      'response.localBadge': 'بطاقة محلية موثقة',
      'response.unknownTitle': 'غير موثق في هذه النسخة',
      'response.unknownText': 'هذه المعلومة غير مدرجة بعد في القاعدة المحلية التجريبية. لن يتم اختلاق أي أرقام أو توفر غير مؤكد.',
      'response.meta': 'بطاقة محلية · {id}',
      'btn.speak': 'قراءة',
      'btn.speakAria': 'قراءة الإجابة بصوت عالٍ',
      'btn.stop': 'إيقاف',
      'btn.stopAria': 'إيقاف الصوت',
      'btn.replay': 'إعادة',
      'btn.replayAria': 'إعادة قراءة الإجابة',
      'btn.tools': 'أدوات',
      'btn.optionsAria': 'فتح الأدوات والبيانات',
      'actions.title': 'الأدوات والعرض التجريبي',
      'btn.nfcRead': 'قراءة NFC',
      'btn.nfcReadAria': 'قراءة بطاقة NFC',
      'btn.nfcWrite': 'كتابة NFC',
      'btn.nfcWriteAria': 'كتابة البطاقة التجريبية على NFC',
      'btn.qr': 'رموز QR',
      'btn.qrAria': 'عرض رموز QR',
      'nfc.idle': 'NFC جاهز على Chrome Android عبر HTTPS.',
      'nfc.unsupported': 'Web NFC غير متوفر. استخدم رمز QR.',
      'nfc.scanning': 'قرّب بطاقة NFC من مؤخرة الهاتف…',
      'nfc.writing': 'قرّب بطاقة فارغة لكتابة البطاقة…',
      'nfc.writeOk': 'تمت كتابة البطاقة: {url}',
      'nfc.readOk': 'تمت قراءة البطاقة: {id}',
      'nfc.timeout': 'انتهت مهلة NFC. أعد المحاولة.',
      'nfc.permission': 'تم رفض إذن NFC.',
      'nfc.error': 'فشلت عملية NFC. تحقق من تفعيل NFC.',
      'nfc.cancelled': 'تم إلغاء عملية NFC.',
      'artisan.badge': 'بيانات افتراضية — عرض تجريبي',
      'artisan.close': 'إغلاق',
      'artisan.closeAria': 'إغلاق بطاقة الحرفي',
      'artisan.speak': 'قراءة البطاقة',
      'artisan.field.trade': 'المهنة',
      'artisan.field.zone': 'المنطقة',
      'artisan.field.availability': 'التوفر',
      'artisan.field.contact': 'الاتصال',
      'artisan.notFoundName': 'البطاقة غير موجودة',
      'artisan.notFoundText': 'هذا العرض لا يدعم سوى البطاقتين الافتراضيتين ART-DEMO-01 و ART-DEMO-02.',
      'artisan.sourceLine': '{id} · بطاقة تجريبية · {date}',
      'footer.demo': 'عرض تجريبي غير معتمد.',
      'footer.demoText': 'جميع البطاقات افتراضية ولا تثبت أي توفر حقيقي.',
      'footer.version': 'حريف بوت النسخة 1 · دليل 23 أكتوبر 2026',
      'dialog.close': 'إغلاق',
      'qr.title': 'رموز QR الاحتياطية',
      'qr.subtitle': 'تُستخدم في حال عدم توفر NFC.',
      'qr.tabSite': 'موقع Le7rayfi',
      'qr.tabDemo': 'بطاقة تجريبية',
      'qr.siteCaption': 'رمز QR للموقع العام.',
      'qr.openSite': 'فتح الموقع',
      'qr.demoCaption': 'رمز QR افتراضي لبطاقة ART-DEMO-01.',
      'qr.demoNote': 'نطاق bot.le7rayfi.com افتراضي.',
      'qr.showDemo': 'عرض البطاقة التجريبية (محاكاة)',
      'qr.currentUrl': 'العنوان الحالي',
      'qr.copy': 'نسخ',
      'options.title': 'الخيارات والبيانات',
      'options.subtitle': 'استيراد أو تصدير أو مزامنة الإجابات المحلية.',
      'options.voiceSettingsTitle': 'إعدادات الصوت',
      'options.voiceSelect': 'صوت القراءة :',
      'options.speechRate': 'سرعة الكلام :',
      'options.syncTitle': 'مزامنة HTTPS',
      'options.syncHint': 'الصق رابط ملف JSON المعتمد ثم قم بالمزامنة.',
      'options.syncLabel': 'رابط JSON',
      'options.syncPlaceholder': 'https://exemple.ma/knowledge.json',
      'options.sync': 'مزامنة',
      'options.localTitle': 'ملف محلي',
      'options.import': 'استيراد JSON',
      'options.export': 'تصدير JSON',
      'options.reset': 'الرجوع للقاعدة الأصلية',
      'options.fileHint': 'ترميز UTF-8، بنية version و items.',
      'options.limitsTitle': 'الحدود المضبوطة في التطبيق',
      'options.limit1': '200 بطاقة كحد أقصى.',
      'options.limit2': '35 كلمة مفتاحية لكل بطاقة.',
      'options.limit3': '180,000 بايت كحد أقصى للملف.',
      'options.privacy': 'لا تضع أي بيانات سرية أو شخصية في الملف.',
      'options.stats': 'الإصدار {version} · {count} بطاقة · المصدر : {source} · التحديث : {date}',
      'micModal.title': 'الميكروفون مطلوب للتحدث',
      'micModal.subtitle': 'يرجى السماح بالوصول إلى الميكروفون للتحدث مع حريف',
      'micModal.step1Title': 'تفعيل الميكروفون في المتصفح',
      'micModal.step1Text': 'انقر على رمز القفل أو الإعدادات بجوار شريط العنوان واسمح بالوصول إلى الميكروفون.',
      'micModal.step2Title': 'على هاتف أندرويد',
      'micModal.step2Text': 'تأكد من إذن الميكروفون في: ضبط الهاتف > التطبيقات > Chrome > الأذونات.',
      'micModal.step3Title': 'الكتابة كبديل فوري',
      'micModal.step3Text': 'يمكنكم دائماً كتابة أسئلتكم مباشرة في الحقل النصي أدناه.',
      'micModal.retry': 'إعادة محاولة الميكروفون',
      'micModal.useText': 'المتابعة بالكتابة',
      'toast.copied': 'تم نسخ العنوان.',
      'toast.copyFail': 'تعذر النسخ.',
      'toast.speakUnsupported': 'المتصفح لا يدعم القراءة الصوتية.',
      'toast.micUnsupported': 'التعرف الصوتي غير مدعوم هنا. استخدم حقل الكتابة.',
      'toast.micDenied': 'تم رفض إذن الميكروفون. يرجى تفعيله في المتصفح.',
      'toast.micFailed': 'لم يتم اكتشاف أي كلام. حاول مجدداً أو اكتب سؤالك.',
      'toast.imported': 'تم استيراد قاعدة المعرفة وتفعيلها.',
      'toast.exported': 'تم تحميل النسخة الاحتياطية JSON.',
      'toast.synced': 'تمت المزامنة بنجاح.',
      'toast.reset': 'تمت استعادة القاعدة المرفقة.',
      'toast.writeSuccess': 'تمت كتابة بطاقة NFC بنجاح.',
      'toast.readSuccess': 'تمت قراءة بطاقة NFC بنجاح.',
      'toast.nfcUnsupported': 'NFC غير متوفر: استخدم رموز QR.',
      'toast.demoShown': 'تم عرض البطاقة التجريبية ART-DEMO-01.'
    },
    darija: {
      'page.title': 'حريف بوت النسخة 1 — Le7rayfi',
      'brand.sub': 'صناع بلادي والمعارف الأصيلة',
      'net.online': 'كونيكطي',
      'net.offline': 'أوفلاين',
      'mood.idle': 'واجد نسمع ليك',
      'mood.listening': 'كنسمع ليك… تفضل',
      'mood.thinking': 'كنفكر ف الجواب…',
      'mood.speaking': 'كنجاوبك دابا…',
      'mood.error': 'بلاتي واحد الدقيقة…',
      'btn.mic': 'ورك باش تهضر',
      'btn.micAria': 'ورك باش تهضر مع الروبوت',
      'voice.idle': 'ورك على الميكرو وهضر بشكل طبيعي.',
      'voice.listening': 'كنسمع ليك… هضر دابا.',
      'voice.processing': 'كنقلب ف الإجابات المحلية الموثقة…',
      'voice.speaking': 'حريف كيهضر دابا…',
      'voice.cancel': 'إلغاء',
      'voice.youSaid': 'قلتي لينا :',
      'chat.title': 'المحادثة والتبادل',
      'chat.inputLabel': 'السؤال ديالك',
      'chat.placeholder': 'أو كتب السؤال ديالك هنا…',
      'chat.send': 'صيفط',
      'chat.sendAria': 'صيفط السؤال',
      'chat.clear': 'مسح',
      'chat.voiceSection': 'التحكم بالصوت',
      'suggestions.label': 'أسئلة مقترحة :',
      'response.emptyTitle': 'مرحبا بيك',
      'response.emptyText': 'السلام عليكم ! أنا حريف بوت، المساعد الصوتي ديالك. ورك على الميكرو وهضر معايا ولا كتب ليا سؤالك.',
      'response.localTitle': 'جواب محلي موثق',
      'response.localBadge': 'بطاقة موثقة',
      'response.unknownTitle': 'ما كاينش ف هاد النسخة',
      'response.unknownText': 'هاد المعلومة ما زال ما موثقة ف القاعدة المحلية ديال هاد التجربة. ما غادي نخترعو حتى نمرة ولا توفر.',
      'response.meta': 'بطاقة محلية · {id}',
      'btn.speak': 'سمع',
      'btn.speakAria': 'سمع الجواب بالصوت',
      'btn.stop': 'وقف',
      'btn.stopAria': 'وقف الصوت',
      'btn.replay': 'عاود',
      'btn.replayAria': 'عاود سمع الجواب',
      'btn.tools': 'أدوات',
      'btn.optionsAria': 'حل الأدوات والبيانات',
      'actions.title': 'الأدوات والتجربة',
      'btn.nfcRead': 'قرا NFC',
      'btn.nfcReadAria': 'قرا كارت NFC',
      'btn.nfcWrite': 'كتب فـ NFC',
      'btn.nfcWriteAria': 'كتب البطاقة التجريبية فـ NFC',
      'btn.qr': 'رموز QR',
      'btn.qrAria': 'شوف رموز QR',
      'nfc.idle': 'NFC واجد فـ Chrome Android بـ HTTPS.',
      'nfc.unsupported': 'Web NFC ما كاينش هنا. خدم بـ QR كود.',
      'nfc.scanning': 'قرب كارت NFC من التيلفون…',
      'nfc.writing': 'قرب كارت خاوية باش نكتبو فيها…',
      'nfc.writeOk': 'تمت كتابة الكارت: {url}',
      'nfc.readOk': 'تقرات الكارت: {id}',
      'nfc.timeout': 'فات الوقت. عاود جرب.',
      'nfc.permission': 'الإذن ديال NFC ترفض.',
      'nfc.error': 'وقعات مشكلة فـ NFC. تأكد واش شاعل.',
      'nfc.cancelled': 'تلغات عملية NFC.',
      'artisan.badge': 'معلومات تجريبية — ديمو',
      'artisan.close': 'سد',
      'artisan.closeAria': 'سد بطاقة الحرايفي',
      'artisan.speak': 'قرا البطاقة',
      'artisan.field.trade': 'الحرفة',
      'artisan.field.zone': 'المنطقة',
      'artisan.field.availability': 'التوفر',
      'artisan.field.contact': 'الاتصال',
      'artisan.notFoundName': 'البطاقة ما لقيناهاش',
      'artisan.notFoundText': 'هاد الديمو كيعرف غير ART-DEMO-01 و ART-DEMO-02.',
      'artisan.sourceLine': '{id} · بطاقة تجريبية · {date}',
      'footer.demo': 'ديمو تجريبي غير معتمد رسمي.',
      'footer.demoText': 'كاع هاد البطاقات تجريبية وما كتدل على حتى توفر حقيقي دابا.',
      'footer.version': 'حريف بوت النسخة 1 · دليل 23 أكتوبر 2026',
      'dialog.close': 'سد',
      'qr.title': 'رموز QR د السلك',
      'qr.subtitle': 'خدم بيهم إلا ما كانش عندك NFC.',
      'qr.tabSite': 'السيت د Le7rayfi',
      'qr.tabDemo': 'بطاقة ديمو',
      'qr.siteCaption': 'QR كيدي للموقع العام د Le7rayfi.',
      'qr.openSite': 'حل السيت',
      'qr.demoCaption': 'QR تجريبي كيدي لـ ART-DEMO-01.',
      'qr.demoNote': 'هاد الدومين غير مثال تجريبي.',
      'qr.showDemo': 'بين البطاقة التجريبية',
      'qr.currentUrl': 'العنوان د دابا',
      'qr.copy': 'كوبي',
      'options.title': 'الخيارات والمعطيات',
      'options.subtitle': 'استورد، صيفط، ولا سينكرونيزي الإجابات المحلية.',
      'options.voiceSettingsTitle': 'إعدادات الصوت',
      'options.voiceSelect': 'الصوت د القراءة :',
      'options.speechRate': 'السرعة د الهضرة :',
      'options.syncTitle': 'المزامنة بـ HTTPS',
      'options.syncHint': 'كولي الرابط د JSON معتمد وسينكرونيزي.',
      'options.syncLabel': 'رابط JSON',
      'options.syncPlaceholder': 'https://exemple.ma/knowledge.json',
      'options.sync': 'سينكرونيزي',
      'options.localTitle': 'ملف ف الجهاز',
      'options.import': 'جيب JSON',
      'options.export': 'خرج JSON',
      'options.reset': 'رجع للقاعدة الأصلية',
      'options.fileHint': 'بنية version و items بترميز UTF-8.',
      'options.limitsTitle': 'شروط التطبيق',
      'options.limit1': '200 بطاقة كحد أقصى.',
      'options.limit2': '35 كلمة د المفتاح لكل بطاقة.',
      'options.limit3': '180,000 بايت كحد أقصى.',
      'options.privacy': 'ما تحط حتى معلومة سرية ف هاد الملف.',
      'options.stats': 'النسخة {version} · {count} بطاقة · المصدر : {source} · التاريخ : {date}',
      'micModal.title': 'خاصنا الميكرو باش تهضر',
      'micModal.subtitle': 'عطي الإذن للميكرو باش تدوي مع حريف',
      'micModal.step1Title': 'تفعيل الميكرو ف المتصفح',
      'micModal.step1Text': 'كليكي على رمز القفل ولا الإعدادات حدا الرابط وعطي الإذن للميكروفون.',
      'micModal.step2Title': 'ف التيليفون أندرويد',
      'micModal.step2Text': 'تأكد من إذن الميكرو: ضبط الهاتف > التطبيقات > Chrome > الأذونات.',
      'micModal.step3Title': 'كتب إلا بغيتي',
      'micModal.step3Text': 'تقدر ديما تكتب السؤال ديالك ف الخانة لتحت.',
      'micModal.retry': 'عاود جرب الميكرو',
      'micModal.useText': 'نكمل بالكتابة',
      'toast.copied': 'تكوبات لادريس.',
      'toast.copyFail': 'ما قدرناش نكوبيو.',
      'toast.speakUnsupported': 'المتصفح ما كيدعمش الهضرة بالصوت.',
      'toast.micUnsupported': 'السميع بالصوت ما خدامش هنا. خدم بالكتابة.',
      'toast.micDenied': 'الميكرو مرفوض. فعلو ف باراميطر.',
      'toast.micFailed': 'ما سمعنا والو. عاود جرب ولا كتب السؤال.',
      'toast.imported': 'تم تفعيل قاعدة المعرفة الجديدة.',
      'toast.exported': 'تم تحميل ملف JSON.',
      'toast.synced': 'تسينكرونيزات بنجاح.',
      'toast.reset': 'رجعات القاعدة الأصلية.',
      'toast.writeSuccess': 'تكتبات كارت NFC.',
      'toast.readSuccess': 'تقرات كارت NFC.',
      'toast.nfcUnsupported': 'NFC ما كاينش: خدم بـ QR.',
      'toast.demoShown': 'بانت البطاقة التجريبية ART-DEMO-01.'
    }
  };

  /* ---------------- État Central de l'Application ---------------- */
  const state = {
    lang: 'darija',
    knowledge: null,
    knowledgeSource: 'bundled',
    knowledgeSavedAt: null,
    moodKey: 'mood.idle',
    listening: false,
    processing: false,
    speaking: false,
    currentTranscript: '',
    recognition: null,
    ttsUtterance: null,
    response: null,
    artisan: null,
    nfcStatus: null,
    askTimer: null,
    history: [],
    previousTopic: null,
    audioContext: null,
    analyserNode: null,
    mediaStream: null,
    visualizerAnimId: null,
    lipSyncTimer: null,
    selectedVoice: null,
    speechRate: 0.72
  };

  /* ---------------- Sélecteurs DOM ---------------- */
  const $ = (selector, parent = document) => parent.querySelector(selector);
  const $$ = (selector, parent = document) => Array.from(parent.querySelectorAll(selector));

  const dom = {};

  function cacheDom() {
    dom.netPill = $('#netStatus');
    dom.netLabel = $('#netLabel');
    dom.langFr = $('#langFr');
    dom.langAr = $('#langAr');
    dom.langDarija = $('#langDarija');
    dom.langEn = $('#langEn');
    dom.btnOptions = $('#btnOptions');
    dom.face = $('#face');
    dom.robotMouth = $('#robotMouth');
    dom.robotAntenna = $('#robotAntenna');
    dom.pupilL = $('#pupilL');
    dom.pupilR = $('#pupilR');
    dom.browL = $('#browL');
    dom.browR = $('#browR');
    dom.moodText = $('#moodText');
    dom.speechBubble = $('#speechBubble');
    dom.bubbleSender = $('#bubbleSender');
    dom.bubbleBadge = $('#bubbleBadge');
    dom.respTitle = $('#respTitle');
    dom.respText = $('#respText');
    dom.respMeta = $('#respMeta');
    dom.respSpeak = $('#respSpeak');
    dom.respStop = $('#respStop');
    dom.respReplay = $('#respReplay');
    dom.audioVisualizer = $('#audioVisualizer');
    dom.btnMic = $('#btnMic');
    dom.micBtnText = $('#micBtnText');
    dom.voiceStatus = $('#voiceStatus');
    dom.btnCancelMic = $('#btnCancelMic');
    dom.transcriptCard = $('#transcriptCard');
    dom.transcript = $('#transcript');
    dom.convoMessages = $('#convoMessages');
    dom.btnClearHistory = $('#btnClearHistory');
    dom.suggestions = $('#suggestions');
    dom.askForm = $('#askForm');
    dom.askInput = $('#askInput');
    dom.kbMeta = $('#kbMeta');
    dom.btnNfcRead = $('#btnNfcRead');
    dom.btnNfcWrite = $('#btnNfcWrite');
    dom.btnQr = $('#btnQr');
    dom.nfcStatus = $('#nfcStatus');
    dom.nfcText = $('#nfcText');
    dom.artisanCard = $('#artisanCard');
    dom.artisanName = $('#artisanName');
    dom.artisanSub = $('#artisanSub');
    dom.artisanFields = $('#artisanFields');
    dom.artisanNote = $('#artisanNote');
    dom.artisanSource = $('#artisanSource');
    dom.artisanClose = $('#artisanClose');
    dom.artisanSpeak = $('#artisanSpeak');
    dom.artisanStop = $('#artisanStop');
    dom.toast = $('#toast');
    dom.a11yAnnouncer = $('#a11yAnnouncer');
    dom.qrDialog = $('#qrDialog');
    dom.showDemoCard = $('#showDemoCard');
    dom.currentUrl = $('#currentUrl');
    dom.copyUrl = $('#copyUrl');
    dom.optionsDialog = $('#optionsDialog');
    dom.optionsStats = $('#optionsStats');
    dom.selectVoice = $('#selectVoice');
    dom.rangeSpeechRate = $('#rangeSpeechRate');
    dom.rateValue = $('#rateValue');
    dom.syncUrl = $('#syncUrl');
    dom.btnSync = $('#btnSync');
    dom.btnImport = $('#btnImport');
    dom.btnExport = $('#btnExport');
    dom.btnReset = $('#btnReset');
    dom.fileInput = $('#fileInput');
    dom.micPermissionModal = $('#micPermissionModal');
    dom.btnRetryMic = $('#btnRetryMic');
  }

  /* ---------------- Traduction Helper ---------------- */
  function t(key, vars) {
    const langDict = I18N[state.lang] || I18N.fr;
    let template = langDict[key] || (I18N.fr && I18N.fr[key]) || key;
    if (vars && typeof vars === 'object') {
      for (const [k, v] of Object.entries(vars)) {
        template = template.replace(new RegExp('\\{' + k + '\\}', 'g'), String(v));
      }
    }
    return template;
  }

  /* ---------------- Notifications Toast ---------------- */
  let toastTimer = null;
  function toast(message, type = '') {
    if (!dom.toast) return;
    window.clearTimeout(toastTimer);
    dom.toast.textContent = message;
    dom.toast.className = 'toast' + (type ? ' is-' + type : '');
    dom.toast.hidden = false;
    if (dom.a11yAnnouncer) dom.a11yAnnouncer.textContent = message;
    toastTimer = window.setTimeout(() => {
      dom.toast.hidden = true;
    }, 4200);
  }

  /* =========================================================
     AUDIO VISUALIZER & WEB AUDIO API ENGINE
     ========================================================= */
  const Visualizer = {
    ctx: null,
    canvas: null,
    canvasCtx: null,
    analyser: null,
    dataArray: null,
    phase: 0,

    init() {
      this.canvas = dom.audioVisualizer;
      if (!this.canvas) return;
      this.canvasCtx = this.canvas.getContext('2d');
      this.resize();
      window.addEventListener('resize', () => this.resize());
      this.render();
    },

    resize() {
      if (!this.canvas) return;
      const rect = this.canvas.getBoundingClientRect();
      this.canvas.width = rect.width * (window.devicePixelRatio || 1);
      this.canvas.height = rect.height * (window.devicePixelRatio || 1);
    },

    async attachStream(stream) {
      try {
        const AudioCtx = window.AudioContext || window.webkitAudioContext;
        if (!AudioCtx) return;
        if (!this.ctx) {
          this.ctx = new AudioCtx();
        }
        if (this.ctx.state === 'suspended') {
          await this.ctx.resume();
        }
        const source = this.ctx.createMediaStreamSource(stream);
        this.analyser = this.ctx.createAnalyser();
        this.analyser.fftSize = 64;
        this.analyser.smoothingTimeConstant = 0.8;
        source.connect(this.analyser);
        this.dataArray = new Uint8Array(this.analyser.frequencyBinCount);
      } catch (err) {
        console.warn('AudioContext attach warning:', err);
      }
    },

    detachStream() {
      this.analyser = null;
      this.dataArray = null;
    },

    render() {
      requestAnimationFrame(() => this.render());
      if (!this.canvasCtx || !this.canvas) return;

      const width = this.canvas.width;
      const height = this.canvas.height;
      const ctx = this.canvasCtx;
      this.phase += 0.05;

      ctx.clearRect(0, 0, width, height);

      let avgVolume = 0;
      if (state.listening && this.analyser && this.dataArray) {
        this.analyser.getByteFrequencyData(this.dataArray);
        let sum = 0;
        for (let i = 0; i < this.dataArray.length; i++) {
          sum += this.dataArray[i];
        }
        avgVolume = (sum / this.dataArray.length) / 255;
      }

      // Update robot antenna intensity according to audio volume
      if (dom.face) {
        const targetGlow = state.listening ? 0.4 + avgVolume * 0.9 : (state.speaking ? 0.8 : 0.4);
        dom.face.style.setProperty('--antenna-intensity', targetGlow.toFixed(2));
      }

      // Draw Waveform
      const centerY = height / 2;
      ctx.beginPath();
      ctx.lineWidth = 3 * (window.devicePixelRatio || 1);

      let gradient;
      if (state.listening) {
        gradient = ctx.createLinearGradient(0, 0, width, 0);
        gradient.addColorStop(0, '#06b6d4');
        gradient.addColorStop(0.5, '#22d3ee');
        gradient.addColorStop(1, '#14b8a6');
      } else if (state.speaking) {
        gradient = ctx.createLinearGradient(0, 0, width, 0);
        gradient.addColorStop(0, '#e6a23c');
        gradient.addColorStop(0.5, '#38bdf8');
        gradient.addColorStop(1, '#f59e0b');
      } else if (state.processing) {
        gradient = ctx.createLinearGradient(0, 0, width, 0);
        gradient.addColorStop(0, '#f59e0b');
        gradient.addColorStop(1, '#fbbf24');
      } else {
        gradient = ctx.createLinearGradient(0, 0, width, 0);
        gradient.addColorStop(0, 'rgba(6, 182, 212, 0.4)');
        gradient.addColorStop(0.5, 'rgba(230, 162, 60, 0.5)');
        gradient.addColorStop(1, 'rgba(6, 182, 212, 0.4)');
      }
      ctx.strokeStyle = gradient;

      const points = 48;
      const step = width / points;

      ctx.moveTo(0, centerY);

      for (let i = 0; i <= points; i++) {
        const x = i * step;
        let amp = 4;
        let freq = 1;

        if (state.listening) {
          amp = 8 + avgVolume * (height * 0.45);
          freq = 2.4;
        } else if (state.speaking) {
          amp = 12 + Math.sin(this.phase * 3) * 6;
          freq = 2;
        } else if (state.processing) {
          amp = 6 + Math.sin(this.phase * 4 + i * 0.4) * 4;
          freq = 3;
        } else {
          // Idle breathing sine wave
          amp = 4 + Math.sin(this.phase * 0.8) * 2;
          freq = 1;
        }

        const y = centerY + Math.sin((i / points) * Math.PI * 2 * freq + this.phase) * amp;
        ctx.lineTo(x, y);
      }

      ctx.stroke();
    }
  };

  /* =========================================================
     DYNAMIC LIP-SYNC & FACIAL EXPRESSION ENGINE
     ========================================================= */
  const LipSync = {
    targetMouthOpen: 0,
    currentMouthOpen: 0,
    targetMouthWidth: 0,
    currentMouthWidth: 0,
    targetMouthRound: 0,
    currentMouthRound: 0,
    phonemeMap: {
      a: { open: 0.95, width: 0.5, round: 0.2 },
      o: { open: 0.7, width: -0.3, round: 0.9 },
      u: { open: 0.6, width: -0.4, round: 1.0 },
      e: { open: 0.5, width: 0.8, round: 0.1 },
      i: { open: 0.35, width: 0.9, round: 0.0 },
      m: { open: 0.05, width: 0.0, round: 0.1 },
      b: { open: 0.05, width: 0.0, round: 0.1 },
      p: { open: 0.05, width: 0.0, round: 0.1 },
      s: { open: 0.25, width: 0.6, round: 0.0 },
      t: { open: 0.3, width: 0.4, round: 0.0 },
      r: { open: 0.45, width: 0.3, round: 0.3 },
      default: { open: 0.4, width: 0.2, round: 0.2 }
    },

    init() {
      this.animateLoop();
      this.setupInteractivePupils();
      this.setupBlinking();
    },

    setViseme(char) {
      const c = String(char || '').toLowerCase();
      const profile = this.phonemeMap[c] || this.phonemeMap.default;
      this.targetMouthOpen = profile.open;
      this.targetMouthWidth = profile.width;
      this.targetMouthRound = profile.round;
    },

    resetMouth() {
      this.targetMouthOpen = 0;
      this.targetMouthWidth = 0;
      this.targetMouthRound = 0;
    },

    animateLoop() {
      requestAnimationFrame(() => this.animateLoop());
      // Smooth interpolation towards targets
      this.currentMouthOpen += (this.targetMouthOpen - this.currentMouthOpen) * 0.28;
      this.currentMouthWidth += (this.targetMouthWidth - this.currentMouthWidth) * 0.28;
      this.currentMouthRound += (this.targetMouthRound - this.currentMouthRound) * 0.28;

      if (dom.robotMouth) {
        dom.robotMouth.style.setProperty('--mouth-open', this.currentMouthOpen.toFixed(3));
        dom.robotMouth.style.setProperty('--mouth-width', this.currentMouthWidth.toFixed(3));
        dom.robotMouth.style.setProperty('--mouth-round', this.currentMouthRound.toFixed(3));
      }
    },

    setupInteractivePupils() {
      const handlePointer = (clientX, clientY) => {
        if (!dom.face) return;
        const rect = dom.face.getBoundingClientRect();
        const faceCenterX = rect.left + rect.width / 2;
        const faceCenterY = rect.top + rect.height / 2;
        const deltaX = Math.max(-1, Math.min(1, (clientX - faceCenterX) / 200));
        const deltaY = Math.max(-1, Math.min(1, (clientY - faceCenterY) / 200));
        dom.face.style.setProperty('--eye-x', deltaX.toFixed(3));
        dom.face.style.setProperty('--eye-y', deltaY.toFixed(3));
      };

      window.addEventListener('pointermove', (e) => {
        handlePointer(e.clientX, e.clientY);
      });

      window.addEventListener('touchmove', (e) => {
        if (e.touches && e.touches[0]) {
          handlePointer(e.touches[0].clientX, e.touches[0].clientY);
        }
      }, { passive: true });
    },

    setupBlinking() {
      const scheduleBlink = () => {
        const nextBlinkMs = 2800 + Math.random() * 3800;
        setTimeout(() => {
          if (dom.face) {
            dom.face.classList.add('is-blink');
            setTimeout(() => {
              if (dom.face) dom.face.classList.remove('is-blink');
              // Occasional double blink
              if (Math.random() > 0.7) {
                setTimeout(() => {
                  if (dom.face) dom.face.classList.add('is-blink');
                  setTimeout(() => {
                    if (dom.face) dom.face.classList.remove('is-blink');
                  }, 110);
                }, 140);
              }
              scheduleBlink();
            }, 120);
          }
        }, nextBlinkMs);
      };
      scheduleBlink();
    }
  };

  /* =========================================================
     GESTION DU MOOD & DES ÉTATS DU ROBOT
     ========================================================= */
  function setMood(key) {
    state.moodKey = key;
    if (dom.moodText) dom.moodText.textContent = t(key);
    if (dom.face) {
      dom.face.classList.toggle('is-thinking', key === 'mood.thinking');
      dom.face.classList.toggle('is-speaking', key === 'mood.speaking');
      dom.face.classList.toggle('is-listening', key === 'mood.listening');
    }
    updateVoiceUI();
  }

  function updateVoiceUI() {
    if (dom.btnMic) {
      dom.btnMic.classList.toggle('is-listening', state.listening);
      dom.btnMic.classList.toggle('is-processing', state.processing && !state.listening);
      dom.btnMic.setAttribute('aria-pressed', String(state.listening));
    }
    if (dom.micBtnText) {
      if (state.listening) {
        dom.micBtnText.textContent = t('voice.cancel');
      } else if (state.processing) {
        dom.micBtnText.textContent = t('voice.processing');
      } else if (state.speaking) {
        dom.micBtnText.textContent = t('btn.stop');
      } else {
        dom.micBtnText.textContent = t('btn.mic');
      }
    }
    if (dom.voiceStatus) {
      if (state.listening) dom.voiceStatus.textContent = t('voice.listening');
      else if (state.processing) dom.voiceStatus.textContent = t('voice.processing');
      else if (state.speaking) dom.voiceStatus.textContent = t('voice.speaking');
      else dom.voiceStatus.textContent = t('voice.idle');
    }
    if (dom.btnCancelMic) {
      dom.btnCancelMic.style.display = state.listening ? 'inline-flex' : 'none';
    }
    if (dom.transcriptCard) {
      dom.transcriptCard.style.display = (state.listening || state.currentTranscript) ? 'block' : 'none';
    }
    if (dom.transcript) {
      dom.transcript.textContent = state.currentTranscript || '';
    }
    if (dom.respStop) {
      dom.respStop.disabled = !state.speaking;
    }
    if (dom.respSpeak) {
      dom.respSpeak.classList.toggle('is-active', state.speaking);
      dom.respSpeak.disabled = state.speaking || !state.response;
    }
    if (dom.respReplay) {
      dom.respReplay.disabled = state.speaking || !state.response;
    }
  }

  /* =========================================================
     SYNTHÈSE VOCALE (TEXT-TO-SPEECH) & LIP-SYNC SYNCHRONISÉ
     ========================================================= */
  let speechFallbackTimer = null;

  function stopSpeaking() {
    if ('speechSynthesis' in window) {
      try { window.speechSynthesis.cancel(); } catch (err) { /* ignore */ }
    }
    if (speechFallbackTimer) {
      clearInterval(speechFallbackTimer);
      speechFallbackTimer = null;
    }
    state.speaking = false;
    LipSync.resetMouth();
    setMood('mood.idle');
  }

  function getBestVoiceForLanguage(langCode) {
    if (!('speechSynthesis' in window) || !window.speechSynthesis.getVoices) return null;
    const voices = window.speechSynthesis.getVoices();
    if (!voices || !voices.length) return null;

    const prefix = (langCode === 'ar' || langCode === 'darija') ? 'ar' : (langCode === 'en' ? 'en' : 'fr');
    // Prioritize natural or target dialect voices
    const targetLang = (langCode === 'darija') ? 'ar-ma' : (langCode === 'ar' ? 'ar' : (langCode === 'en' ? 'en' : 'fr'));

    let match = voices.find(v => (v.lang || '').toLowerCase().startsWith(targetLang));
    if (!match) {
      match = voices.find(v => (v.lang || '').toLowerCase().startsWith(prefix));
    }
    return match || voices[0];
  }

  function speakText(text) {
    if (!text) return;
    if (!('speechSynthesis' in window) || typeof SpeechSynthesisUtterance !== 'function') {
      toast(t('toast.speakUnsupported'), 'error');
      return;
    }
    try {
      window.speechSynthesis.cancel();
    } catch (e) { /* ignore */ }

    stopSpeaking();
    const synth = window.speechSynthesis;
    const utterance = new SpeechSynthesisUtterance(text);
    state.ttsUtterance = utterance;

    const voice = state.selectedVoice || getBestVoiceForLanguage(state.lang);
    if (voice) utterance.voice = voice;

    utterance.lang = (state.lang === 'en' ? 'en-US' : (state.lang === 'darija' ? 'ar-MA' : (state.lang === 'ar' ? 'ar-SA' : 'fr-FR')));
    utterance.rate = state.speechRate || (state.lang === 'ar' || state.lang === 'darija' ? 0.68 : 0.74);
    utterance.pitch = 0.82;

    // Word boundary tracking for exact syllable mouth movements
    utterance.onboundary = (event) => {
      if (event.name === 'word') {
        const remaining = text.slice(event.charIndex);
        const match = remaining.match(/^[^\s]+/);
        const word = match ? match[0] : '';
        // Extract dominant vowels/phonemes for this word
        for (let i = 0; i < word.length; i++) {
          const char = word[i].toLowerCase();
          if ('aeiouyأإؤئءوىة'.includes(char)) {
            LipSync.setViseme(char);
            break;
          }
        }
      }
    };

    utterance.onstart = () => {
      state.speaking = true;
      setMood('mood.speaking');

      // Fallback rhythm loop in case boundary events are not fired by the browser engine
      speechFallbackTimer = setInterval(() => {
        if (!state.speaking) {
          clearInterval(speechFallbackTimer);
          return;
        }
        const sampleChars = ['a', 'o', 'e', 'i', 'm', 't', 'r'];
        const randomChar = sampleChars[Math.floor(Math.random() * sampleChars.length)];
        LipSync.setViseme(randomChar);
      }, 160);
    };

    const finish = () => {
      state.speaking = false;
      state.ttsUtterance = null;
      if (speechFallbackTimer) {
        clearInterval(speechFallbackTimer);
        speechFallbackTimer = null;
      }
      LipSync.resetMouth();
      setMood('mood.idle');
    };

    utterance.onend = finish;
    utterance.onerror = finish;

    try {
      synth.speak(utterance);
    } catch (err) {
      finish();
      toast(t('toast.speakUnsupported'), 'error');
    }
  }

  function speakCurrentResponse() {
    if (!state.response) return;
    if (state.response.fallback) {
      speakText(t('response.unknownText'));
      return;
    }
    if (state.response.customText) {
      speakText(state.response.customText);
      return;
    }
    const item = state.knowledge && state.knowledge.items.find(i => i.id === state.response.itemId);
    if (item) {
      const text = (state.lang === 'darija' && item.darija) ? item.darija : ((state.lang === 'ar' || state.lang === 'darija') ? item.ar : item.fr);
      speakText(text);
      return;
    }
    // Fallback: if we have a message in history
    if (state.history && state.history.length) {
      const lastBot = [...state.history].reverse().find(m => m.sender === 'bot');
      if (lastBot && lastBot.text) {
        speakText(lastBot.text);
      }
    }
  }

  /* =========================================================
     RECONNAISSANCE VOCALE (SPEECH-TO-TEXT)
     ========================================================= */
  async function startRecording() {
    stopSpeaking();
    state.currentTranscript = '';
    if (dom.transcript) dom.transcript.textContent = '';
    if (dom.transcriptCard) dom.transcriptCard.style.display = 'block';

    const Recognition = window.SpeechRecognition || window.webkitSpeechRecognition;
    if (!Recognition) {
      toast(t('toast.micUnsupported'), 'error');
      return;
    }

    // Try accessing microphone stream for real-time visualizer reactivity
    if (navigator.mediaDevices && navigator.mediaDevices.getUserMedia) {
      try {
        const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
        state.mediaStream = stream;
        Visualizer.attachStream(stream);
      } catch (err) {
        if (err.name === 'NotAllowedError' || err.name === 'PermissionDeniedError') {
          if (dom.micPermissionModal && dom.micPermissionModal.showModal) {
            dom.micPermissionModal.showModal();
          } else {
            toast(t('toast.micDenied'), 'error');
          }
          return;
        }
      }
    }

    try {
      const recognition = new Recognition();
      state.recognition = recognition;
      recognition.lang = (state.lang === 'en') ? 'en-US' : ((state.lang === 'darija') ? 'ar-MA' : (state.lang === 'ar' ? 'ar-SA' : 'fr-FR'));
      recognition.interimResults = true;
      recognition.continuous = false;
      recognition.maxAlternatives = 1;

      recognition.onstart = () => {
        state.listening = true;
        state.processing = false;
        setMood('mood.listening');
      };

      recognition.onresult = (event) => {
        let interim = '';
        let finalText = '';
        for (let i = event.resultIndex; i < event.results.length; i++) {
          const res = event.results[i];
          const transcript = res && res[0] ? res[0].transcript : '';
          if (res.isFinal) finalText += transcript;
          else interim += transcript;
        }

        const currentText = (finalText || interim).trim();
        state.currentTranscript = currentText;
        if (dom.transcript) dom.transcript.textContent = currentText;
        if (dom.askInput) dom.askInput.value = currentText;

        if (finalText && finalText.trim()) {
          try { recognition.stop(); } catch (e) { /* ignore */ }
          cleanUpMicrophone();
          askQuestion(finalText.trim());
        }
      };

      recognition.onerror = (event) => {
        const code = event && event.error;
        if (code === 'language-not-supported' && (recognition.lang === 'ar-MA' || state.lang === 'darija')) {
          console.warn('STT: ar-MA not supported by browser Web Speech API, falling back to ar-SA');
          recognition.lang = 'ar-SA';
          try {
            recognition.start();
            return;
          } catch (_) {}
        }
        cleanUpMicrophone();
        if (code === 'not-allowed' || code === 'service-not-allowed') {
          if (dom.micPermissionModal && dom.micPermissionModal.showModal) {
            dom.micPermissionModal.showModal();
          } else {
            toast(t('toast.micDenied'), 'error');
          }
        } else if (code === 'no-speech') {
          toast(t('toast.micFailed'), 'error');
        } else if (code !== 'aborted') {
          toast(t('toast.micFailed'), 'error');
        }
        setMood('mood.idle');
      };

      recognition.onend = () => {
        if (state.listening) {
          const buffered = (state.currentTranscript || '').trim() || (dom.askInput ? dom.askInput.value.trim() : '');
          cleanUpMicrophone();
          setMood('mood.idle');
          if (buffered) {
            askQuestion(buffered);
          }
        }
      };

      recognition.start();
    } catch (err) {
      cleanUpMicrophone();
      toast(t('toast.micFailed'), 'error');
      setMood('mood.idle');
    }
  }

  function cleanUpMicrophone() {
    state.listening = false;
    Visualizer.detachStream();
    if (state.mediaStream) {
      state.mediaStream.getTracks().forEach(track => track.stop());
      state.mediaStream = null;
    }
  }

  function cancelRecording() {
    if (state.recognition) {
      try {
        state.recognition.abort ? state.recognition.abort() : state.recognition.stop();
      } catch (e) { /* ignore */ }
    }
    cleanUpMicrophone();
    state.currentTranscript = '';
    if (dom.transcriptCard) dom.transcriptCard.style.display = 'none';
    setMood('mood.idle');
  }

  function toggleMic() {
    if (state.speaking) {
      stopSpeaking();
      return;
    }
    if (state.listening) {
      const buffered = (state.currentTranscript || '').trim() || (dom.askInput ? dom.askInput.value.trim() : '');
      cancelRecording();
      if (buffered) {
        askQuestion(buffered);
      }
      return;
    }
    startRecording();
  }

  /* =========================================================
     MOTEUR DE RECHERCHE LOCAL ET CONTEXTE MULTILINGUE
     ========================================================= */
  function normalizeText(text) {
    return String(text)
      .toLowerCase()
      .normalize('NFKD')
      .replace(/[\u0300-\u036f]/g, '')
      .replace(/[\u0610-\u061A\u064B-\u065F\u0670\u06D6-\u06ED\u08D3-\u08FF\u0640]/g, '')
      .replace(/[أإآٱ]/g, 'ا')
      .replace(/ى/g, 'ي')
      .replace(/ؤ/g, 'و')
      .replace(/ئ/g, 'ي')
      .replace(/ة/g, 'ه')
      .replace(/[^\p{L}\p{N}]+/gu, ' ')
      .trim()
      .replace(/\s+/g, ' ');
  }

  const STOP_WORDS = new Set([
    'le', 'la', 'les', 'de', 'des', 'du', 'un', 'une', 'et', 'ou', 'en', 'a', 'au', 'aux',
    'pour', 'comment', 'est', 'ce', 'que', 'qui', 'quoi', 'dans', 'sur', 'avec', 'sans',
    'je', 'tu', 'il', 'elle', 'nous', 'vous', 'ils', 'elles', 'quel', 'quelle', 'quels',
    'quelles', 'sont', 'peut', 'on', 'ca', 'cette', 'mon', 'ton', 'son', 'votre',
    'في', 'من', 'على', 'إلى', 'الى', 'عن', 'مع', 'هل', 'ما', 'كيف', 'لماذا', 'هذا',
    'هذه', 'ذلك', 'التي', 'الذي', 'و', 'او', 'أو', 'ثم', 'ان', 'أن', 'لا', 'هو', 'هي',
    'انا', 'أنا', 'نحن', 'يمكن', 'الى', 'جد', 'أجد',
    'بغيت', 'باغي', 'خاصني', 'خصني', 'عندي', 'كاين', 'كاينة', 'واش', 'شي',
    'ديال', 'ديالي', 'ف', 'عفاك', 'باش', 'فين', 'كنقلب', 'نلقى', 'نصاوب',
    'نصلح', 'ليا', 'ليك', 'لينا', 'دابا', 'هاد', 'هادي', 'هادا', 'هادشي', 'شنو',
    'اش', 'أش', 'علاش', 'شكون', 'كيفاش', 'بلا', 'مشكل', 'مشكلة', 'عطب', 'خاسر', 'خاسرة', 'بانة', 'بانا'
  ]);

  const SYNONYMS = Object.freeze({
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
    'انترنيت': ['انترنت', 'internet', 'connexion'],
    'انترنت': ['انترنيت', 'internet', 'اتصال'],
    'كونيكسيون': ['انترنت', 'اتصال', 'connexion'],
    'wifi': ['انترنت', 'ويفي', 'connexion'],
    'ويفي': ['انترنت', 'wifi']
  });

  function queryTokens(text) {
    const base = normalizeText(text).split(' ').filter(Boolean);
    const set = new Set();
    for (const token of base) {
      if (STOP_WORDS.has(token)) continue;
      set.add(token);
      if (SYNONYMS[token]) {
        for (const s of SYNONYMS[token]) set.add(normalizeText(s));
      }
      if (!/[\u0600-\u06FF]/.test(token) || token.length < 3) continue;
      const trimmed = token
        .replace(/^وال/, '')
        .replace(/^بال/, '')
        .replace(/^كال/, '')
        .replace(/^فال/, '')
        .replace(/^لل/, '')
        .replace(/^ال/, '');
      if (trimmed && trimmed !== token && !STOP_WORDS.has(trimmed)) {
        set.add(trimmed);
        if (SYNONYMS[trimmed]) {
          for (const s of SYNONYMS[trimmed]) set.add(normalizeText(s));
        }
      }
      if (token.startsWith('و') && token.length > 4) set.add(token.slice(1));
      if (trimmed.endsWith('ا') && trimmed.length > 3) set.add(trimmed.slice(0, -1));
      if (trimmed.endsWith('ات') && trimmed.length > 4) set.add(trimmed.slice(0, -2));
      if (trimmed.endsWith('ين') && trimmed.length > 4) set.add(trimmed.slice(0, -2));
      if (trimmed.endsWith('ون') && trimmed.length > 4) set.add(trimmed.slice(0, -2));
    }
    return set;
  }

  function scoreItem(item, normalizedQuery, tokens) {
    let score = 0;
    let matchesCount = 0;
    let hasPhrase = false;
    for (const keyword of item.keywords) {
      const key = normalizeText(keyword);
      if (!key || STOP_WORDS.has(key)) continue;
      if (key.includes(' ')) {
        if ((' ' + normalizedQuery + ' ').includes(' ' + key + ' ') || normalizedQuery.includes(key) || key.includes(normalizedQuery)) {
          score += 8;
          hasPhrase = true;
        }
      } else if (tokens.has(key)) {
        score += 4;
        matchesCount++;
      } else if (key.length >= 4) {
        for (const token of tokens) {
          if (token.length < 3) continue;
          if (Math.abs(token.length - key.length) > 2) continue;
          if (token.startsWith(key) || key.startsWith(token)) {
            score += 2;
            matchesCount++;
            break;
          }
        }
      }
    }
    return { score, matchesCount, hasPhrase };
  }

  function findAnswer(question) {
    if (!state.knowledge || !state.knowledge.items) return null;
    let queryToSearch = question;

    // Follow-up context handling: If question is a short follow-up, enrich with previous topic
    const norm = normalizeText(question);
    const isShortFollowUp = norm.split(' ').length <= 4 && (
      norm.includes('et') || norm.includes('ou') || norm.includes('comment') || norm.includes('فين') || norm.includes('واش')
    );
    if (isShortFollowUp && state.previousTopic) {
      const prevItem = state.knowledge.items.find(i => i.id === state.previousTopic);
      if (prevItem && prevItem.keywords && prevItem.keywords[0]) {
        queryToSearch = prevItem.keywords[0] + ' ' + question;
      }
    }

    const normalizedQuery = normalizeText(queryToSearch);
    const tokens = queryTokens(queryToSearch);

    let best = null;
    let bestScore = 0;
    let bestDetails = null;

    for (const item of state.knowledge.items) {
      const details = scoreItem(item, normalizedQuery, tokens);
      if (details.score > bestScore) {
        best = item;
        bestScore = details.score;
        bestDetails = details;
      }
    }

    if (!best || bestScore < 2) return null;

    // Reject out-of-domain foreign questions (e.g. billet de train pour Tokyo)
    const baseContentWords = normalizedQuery.split(' ').filter(w => w.length >= 3 && !STOP_WORDS.has(w));
    if (baseContentWords.length >= 3 && !bestDetails.hasPhrase && bestDetails.matchesCount <= 1 && bestScore < 4) {
      return null;
    }

    return { item: best, score: bestScore };
  }

  /* =========================================================
     TRAITEMENT DES QUESTIONS & CONVERSATION
     ========================================================= */
  function addMessageToConvo(sender, text, isLocal = false, itemId = null) {
    const time = new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
    const msg = { sender, text, time, isLocal, itemId };
    state.history.push(msg);

    if (!dom.convoMessages) return;

    const bubble = document.createElement('div');
    bubble.className = `convo-bubble ${sender === 'user' ? 'user-msg' : 'bot-msg'}`;

    const body = document.createElement('div');
    body.className = 'bubble-body';
    body.textContent = text;
    bubble.appendChild(body);

    const timeSpan = document.createElement('span');
    timeSpan.className = 'bubble-time';
    timeSpan.textContent = time;
    bubble.appendChild(timeSpan);

    dom.convoMessages.appendChild(bubble);
    dom.convoMessages.scrollTop = dom.convoMessages.scrollHeight;
  }

  function renderResponseBubble(payload) {
    if (!dom.speechBubble) return;

    if (payload.fallback) {
      dom.speechBubble.classList.add('is-fallback');
      if (dom.bubbleBadge) {
        dom.bubbleBadge.hidden = false;
        dom.bubbleBadge.className = 'badge-fallback';
        dom.bubbleBadge.textContent = t('response.unknownTitle');
      }
      dom.respTitle.textContent = t('response.unknownTitle');
      dom.respText.textContent = t('response.unknownText');
      dom.respMeta.hidden = true;
    } else if (payload.customText) {
      dom.speechBubble.classList.remove('is-fallback');
      if (dom.bubbleBadge) {
        dom.bubbleBadge.hidden = false;
        dom.bubbleBadge.className = 'badge-verified';
        dom.bubbleBadge.textContent = 'ذكاء اصطناعي • مباشر';
      }
      dom.respTitle.textContent = state.lang === 'fr' ? 'Réponse IA Le7rayfi' : 'إجابة ذكية مباشرة';
      dom.respText.textContent = payload.customText;
      dom.respMeta.hidden = false;
      dom.respMeta.textContent = state.lang === 'fr' ? 'Généré en direct par Le7rayfi AI' : 'تم التوليد مباشرة عبر ذكاء لحرايفي';
    } else {
      dom.speechBubble.classList.remove('is-fallback');
      const item = state.knowledge.items.find(i => i.id === payload.itemId);
      const answerText = (state.lang === 'darija' && item && item.darija) ? item.darija : ((state.lang === 'ar' || state.lang === 'darija') ? (item ? item.ar : '') : (item ? item.fr : ''));

      if (dom.bubbleBadge) {
        dom.bubbleBadge.hidden = false;
        dom.bubbleBadge.className = 'badge-verified';
        dom.bubbleBadge.textContent = t('response.localBadge');
      }
      dom.respTitle.textContent = t('response.localTitle');
      dom.respText.textContent = answerText;
      dom.respMeta.hidden = false;
      dom.respMeta.textContent = t('response.meta', { id: item.id });
    }

    if (dom.respSpeak) dom.respSpeak.disabled = false;
    if (dom.respReplay) dom.respReplay.disabled = false;
  }

  async function askQuestion(rawQuestion) {
    if (!state.knowledge) {
      toast(t('error.knowledgeLoad'), 'error');
      return;
    }

    const question = rawQuestion.trim();
    if (!question) return;

    stopSpeaking();
    state.currentTranscript = question;
    if (dom.askInput) dom.askInput.value = '';
    if (dom.transcript) dom.transcript.textContent = question;

    // Add user question to conversation log
    addMessageToConvo('user', question);

    state.processing = true;
    setMood('mood.thinking');

    if (state.askTimer) clearTimeout(state.askTimer);

    // Instant local knowledge base resolution (100% offline, 0ms delay)
    state.processing = false;
    const match = findAnswer(question);
    if (match) {
      state.previousTopic = match.item.id;
      state.response = { itemId: match.item.id, query: question, fallback: false };
      const answer = (state.lang === 'darija' && match.item.darija)
        ? match.item.darija
        : ((state.lang === 'ar' || state.lang === 'darija')
          ? match.item.ar
          : (state.lang === 'en' && match.item.en ? match.item.en : match.item.fr));
      renderResponseBubble(state.response);
      addMessageToConvo('bot', answer, true, match.item.id);
      speakCurrentResponse();
    } else {
      state.response = { itemId: null, query: question, fallback: true };
      renderResponseBubble(state.response);
      addMessageToConvo('bot', t('response.unknownText'), false);
      speakCurrentResponse();
    }
  }

  /* =========================================================
     LANGUES & I18N
     ========================================================= */
  function applyLanguage(lang) {
    state.lang = (lang === 'darija' || lang === 'ar' || lang === 'en') ? lang : 'fr';
    const isRtl = state.lang === 'ar' || state.lang === 'darija';

    document.documentElement.lang = isRtl ? 'ar' : (state.lang === 'en' ? 'en' : 'fr');
    document.documentElement.dir = isRtl ? 'rtl' : 'ltr';

    document.body.classList.toggle('lang-ar', state.lang === 'ar');
    document.body.classList.toggle('lang-darija', state.lang === 'darija');
    document.body.classList.toggle('lang-en', state.lang === 'en');

    try { localStorage.setItem(STORAGE.lang, state.lang); } catch (e) { /* ignore */ }

    // Update active button state
    if (dom.langFr) {
      dom.langFr.classList.toggle('is-active', state.lang === 'fr');
      dom.langFr.setAttribute('aria-pressed', String(state.lang === 'fr'));
    }
    if (dom.langAr) {
      dom.langAr.classList.toggle('is-active', state.lang === 'ar');
      dom.langAr.setAttribute('aria-pressed', String(state.lang === 'ar'));
    }
    if (dom.langDarija) {
      dom.langDarija.classList.toggle('is-active', state.lang === 'darija');
      dom.langDarija.setAttribute('aria-pressed', String(state.lang === 'darija'));
    }
    if (dom.langEn) {
      dom.langEn.classList.toggle('is-active', state.lang === 'en');
      dom.langEn.setAttribute('aria-pressed', String(state.lang === 'en'));
    }

    // Translate DOM elements
    $$('[data-i18n]').forEach(el => {
      el.textContent = t(el.getAttribute('data-i18n'));
    });
    $$('[data-i18n-placeholder]').forEach(el => {
      el.setAttribute('placeholder', t(el.getAttribute('data-i18n-placeholder')));
    });
    $$('[data-i18n-aria]').forEach(el => {
      el.setAttribute('aria-label', t(el.getAttribute('data-i18n-aria')));
    });

    if (dom.askInput) dom.askInput.dir = isRtl ? 'rtl' : 'ltr';

    document.title = t('page.title');
    renderSuggestions();

    if (state.response) renderResponseBubble(state.response);
    else {
      if (dom.respText) dom.respText.textContent = t('response.emptyText');
      if (dom.respTitle) dom.respTitle.textContent = t('response.emptyTitle');
    }

    refreshNfcStatus();
    updateNetStatus();
    updateVoiceUI();
    setMood(state.moodKey);
    populateVoiceSelect();
  }

  function renderSuggestions() {
    if (!dom.suggestions) return;
    dom.suggestions.replaceChildren();
    for (const sug of SUGGESTIONS) {
      const label = sug.label[state.lang] || sug.label.darija || sug.label.fr;
      const query = sug.query[state.lang] || sug.query.darija || sug.query.fr;
      const btn = document.createElement('button');
      btn.type = 'button';
      btn.className = 'chip';
      btn.textContent = label;
      btn.title = query;
      btn.addEventListener('click', () => askQuestion(query));
      dom.suggestions.appendChild(btn);
    }
  }

  /* =========================================================
     VOICE SELECTION & CONFIGURATION
     ========================================================= */
  function populateVoiceSelect() {
    if (!dom.selectVoice || !('speechSynthesis' in window)) return;
    const voices = window.speechSynthesis.getVoices ? window.speechSynthesis.getVoices() : [];
    dom.selectVoice.replaceChildren();

    const currentTarget = (state.lang === 'darija' || state.lang === 'ar') ? 'ar' : 'fr';
    const filtered = voices.filter(v => (v.lang || '').toLowerCase().startsWith(currentTarget));

    const options = (filtered.length ? filtered : voices);
    options.forEach(v => {
      const opt = document.createElement('option');
      opt.value = v.name;
      opt.textContent = `${v.name} (${v.lang})`;
      dom.selectVoice.appendChild(opt);
    });
  }

  /* =========================================================
     FICHE ARTISAN (NFC & QR PREVIEW)
     ========================================================= */
  function renderArtisan(id = DEMO_CARD_ID) {
    const data = DEMO_ARTISANS[id];
    if (!data || !dom.artisanCard) return;

    state.artisan = { id, data };
    const langKey = (state.lang === 'darija' ? 'darija' : (state.lang === 'ar' ? 'ar' : 'fr'));

    dom.artisanName.textContent = data.name[langKey] || data.name.fr;
    dom.artisanSub.textContent = t('artisan.sourceLine', { id, date: '23/10/2026' });

    dom.artisanFields.replaceChildren();
    const fields = [
      { key: 'artisan.field.trade', val: data.trade[langKey] || data.trade.fr },
      { key: 'artisan.field.zone', val: data.zone[langKey] || data.zone.fr },
      { key: 'artisan.field.availability', val: data.availability[langKey] || data.availability.fr },
      { key: 'artisan.field.contact', val: data.contact[langKey] || data.contact.fr }
    ];

    fields.forEach(f => {
      const div = document.createElement('div');
      div.className = 'artisan-field';
      const dt = document.createElement('dt');
      dt.textContent = t(f.key);
      const dd = document.createElement('dd');
      dd.textContent = f.val;
      div.appendChild(dt);
      div.appendChild(dd);
      dom.artisanFields.appendChild(div);
    });

    dom.artisanNote.textContent = data.note[langKey] || data.note.fr;
    dom.artisanCard.hidden = false;
    dom.artisanCard.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
  }

  function closeArtisan() {
    if (dom.artisanCard) dom.artisanCard.hidden = true;
    state.artisan = null;
  }

  /* =========================================================
     HARDWARE & OUTILS (NFC & QR)
     ========================================================= */
  function setNfcStatus(key, vars = null, tone = '') {
    state.nfcStatus = { key, vars, tone };
    if (!dom.nfcStatus || !dom.nfcText) return;
    dom.nfcStatus.className = 'nfc-status-pill' + (tone ? ' is-' + tone : '');
    dom.nfcText.textContent = t(key, vars);
  }

  function refreshNfcStatus() {
    if (!state.nfcStatus) {
      setNfcStatus('nfc.idle');
    } else {
      setNfcStatus(state.nfcStatus.key, state.nfcStatus.vars, state.nfcStatus.tone);
    }
  }

  async function readNfc() {
    if (!('NDEFReader' in window)) {
      setNfcStatus('nfc.unsupported', null, 'error');
      toast(t('toast.nfcUnsupported'), 'error');
      return;
    }
    setNfcStatus('nfc.scanning', null, 'busy');
    try {
      const ndef = new window.NDEFReader();
      await ndef.scan();
      ndef.onreading = (event) => {
        let artisanId = DEMO_CARD_ID;
        try {
          if (event && event.message && event.message.records) {
            for (const record of event.message.records) {
              if (record.recordType === 'url') {
                try {
                  const url = new URL(record.data ? new TextDecoder().decode(record.data) : record.data);
                  const id = url.searchParams.get('artisan');
                  if (id && DEMO_ARTISANS[id]) {
                    artisanId = id;
                  }
                } catch (e) {
                  // ignore
                }
              } else if (record.recordType === 'text') {
                try {
                  const text = record.data ? new TextDecoder(record.encoding || 'utf-8').decode(record.data) : '';
                  if (DEMO_ARTISANS[text]) {
                    artisanId = text;
                  }
                } catch (e) {
                  // ignore
                }
              }
            }
          }
        } catch (e) {
          // ignore parsing errors
        }
        setNfcStatus('nfc.readOk', { id: artisanId }, 'ok');
        toast(t('toast.readSuccess'));
        renderArtisan(artisanId);
      };
      ndef.onreadingerror = () => {
        setNfcStatus('nfc.error', null, 'error');
      };
    } catch (err) {
      if (err.name === 'NotAllowedError') setNfcStatus('nfc.permission', null, 'error');
      else setNfcStatus('nfc.error', null, 'error');
    }
  }

  async function writeNfc() {
    if (!('NDEFReader' in window)) {
      setNfcStatus('nfc.unsupported', null, 'error');
      toast(t('toast.nfcUnsupported'), 'error');
      return;
    }
    const demoUrl = new URL(window.location.href);
    demoUrl.searchParams.set('artisan', DEMO_CARD_ID);
    setNfcStatus('nfc.writing', null, 'busy');

    try {
      const ndef = new window.NDEFReader();
      await ndef.write({
        records: [{ recordType: 'url', data: demoUrl.href }]
      });
      setNfcStatus('nfc.writeOk', { url: demoUrl.href }, 'ok');
      toast(t('toast.writeSuccess'));
    } catch (err) {
      setNfcStatus('nfc.error', null, 'error');
    }
  }

  /* =========================================================
     BASE DE CONNAISSANCES (CHARGEMENT & SYNCHRONISATION)
     ========================================================= */
  async function loadInitialKnowledge() {
    // Check localStorage first
    try {
      const cached = localStorage.getItem(STORAGE.knowledge);
      if (cached) {
        const parsed = JSON.parse(cached);
        if (parsed && Array.isArray(parsed.items)) {
          state.knowledge = parsed;
          state.knowledgeSource = 'import';
          updateKbMeta();
          return;
        }
      }
    } catch (e) { /* ignore */ }

    // Fetch bundled knowledge.json
    try {
      const res = await fetch('knowledge.json');
      if (res.ok) {
        const data = await res.json();
        state.knowledge = data;
        state.knowledgeSource = 'bundled';
        updateKbMeta();
      }
    } catch (err) {
      console.error('Failed to load knowledge.json:', err);
    }
  }

  function updateKbMeta() {
    if (!dom.kbMeta || !state.knowledge) return;
    dom.kbMeta.textContent = `v${state.knowledge.version || '1.1'} · ${state.knowledge.items ? state.knowledge.items.length : 0} fiches`;
    if (dom.optionsStats) {
      dom.optionsStats.textContent = t('options.stats', {
        version: state.knowledge.version || '1.1',
        count: state.knowledge.items ? state.knowledge.items.length : 0,
        source: state.knowledgeSource,
        date: state.knowledge.updated || '2026-10-23'
      });
    }
  }

  function updateNetStatus() {
    if (!dom.netPill || !dom.netLabel) return;
    const online = navigator.onLine !== false;
    dom.netPill.classList.toggle('is-offline', !online);
    dom.netLabel.textContent = online ? t('net.online') : t('net.offline');
  }

  /* =========================================================
     ÉVÉNEMENTS & INITIALISATION
     ========================================================= */
  function setupEvents() {
    // Language buttons
    if (dom.langFr) dom.langFr.addEventListener('click', () => applyLanguage('fr'));
    if (dom.langAr) dom.langAr.addEventListener('click', () => applyLanguage('ar'));
    if (dom.langDarija) dom.langDarija.addEventListener('click', () => applyLanguage('darija'));
    if (dom.langEn) dom.langEn.addEventListener('click', () => applyLanguage('en'));

    // Master Hero Mic & Voice actions
    if (dom.btnMic) dom.btnMic.addEventListener('click', toggleMic);
    if (dom.btnCancelMic) dom.btnCancelMic.addEventListener('click', cancelRecording);

    // Bubble audio actions
    if (dom.respSpeak) dom.respSpeak.addEventListener('click', speakCurrentResponse);
    if (dom.respStop) dom.respStop.addEventListener('click', stopSpeaking);
    if (dom.respReplay) dom.respReplay.addEventListener('click', speakCurrentResponse);

    // Text input submission
    if (dom.askForm) {
      dom.askForm.addEventListener('submit', (e) => {
        e.preventDefault();
        const text = (dom.askInput ? dom.askInput.value.trim() : '') || (state.currentTranscript || '').trim();
        if (state.listening) {
          cancelRecording();
        }
        if (text) {
          askQuestion(text);
        }
      });
    }

    // Clear history
    if (dom.btnClearHistory) {
      dom.btnClearHistory.addEventListener('click', () => {
        state.history = [];
        if (dom.convoMessages) dom.convoMessages.replaceChildren();
      });
    }

    // Hardware buttons
    if (dom.btnNfcRead) dom.btnNfcRead.addEventListener('click', readNfc);
    if (dom.btnNfcWrite) dom.btnNfcWrite.addEventListener('click', writeNfc);

    // QR Dialog
    if (dom.btnQr && dom.qrDialog) {
      dom.btnQr.addEventListener('click', () => {
        if (dom.currentUrl) dom.currentUrl.textContent = window.location.href;
        dom.qrDialog.showModal();
      });
    }

    // Options Dialog
    if (dom.btnOptions && dom.optionsDialog) {
      dom.btnOptions.addEventListener('click', () => {
        populateVoiceSelect();
        dom.optionsDialog.showModal();
      });
    }

    // Close buttons on dialogs
    $$('[data-close]').forEach(btn => {
      btn.addEventListener('click', () => {
        const dialog = btn.closest('dialog');
        if (dialog) dialog.close();
      });
    });

    // Voice options changes
    if (dom.selectVoice) {
      dom.selectVoice.addEventListener('change', (e) => {
        const voices = window.speechSynthesis.getVoices();
        state.selectedVoice = voices.find(v => v.name === e.target.value) || null;
      });
    }

    if (dom.rangeSpeechRate) {
      dom.rangeSpeechRate.addEventListener('input', (e) => {
        state.speechRate = parseFloat(e.target.value);
        if (dom.rateValue) dom.rateValue.textContent = `${state.speechRate.toFixed(2)}x`;
        try { localStorage.setItem(STORAGE.speechRate, state.speechRate); } catch (e) { /* ignore */ }
      });
    }

    // Fiche Artisan Controls
    if (dom.artisanClose) dom.artisanClose.addEventListener('click', closeArtisan);
    if (dom.artisanSpeak) {
      dom.artisanSpeak.addEventListener('click', () => {
        if (state.artisan) {
          const d = state.artisan.data;
          const langKey = (state.lang === 'darija' ? 'darija' : (state.lang === 'ar' ? 'ar' : 'fr'));
          const text = `${d.name[langKey]}, ${d.trade[langKey]}, ${d.zone[langKey]}. ${d.note[langKey]}`;
          speakText(text);
        }
      });
    }
    if (dom.artisanStop) dom.artisanStop.addEventListener('click', stopSpeaking);

    // QR Dialog Tab Switching
    $$('[data-qr-tab]').forEach(tab => {
      tab.addEventListener('click', () => {
        $$('[data-qr-tab]').forEach(t => t.classList.remove('is-active'));
        tab.classList.add('is-active');
        const target = tab.getAttribute('data-qr-tab');
        $$('[data-qr-panel]').forEach(panel => {
          panel.hidden = panel.getAttribute('data-qr-panel') !== target;
        });
      });
    });

    if (dom.showDemoCard) {
      dom.showDemoCard.addEventListener('click', () => {
        if (dom.qrDialog) dom.qrDialog.close();
        renderArtisan(DEMO_CARD_ID);
        toast(t('toast.demoShown'));
      });
    }

    if (dom.copyUrl) {
      dom.copyUrl.addEventListener('click', async () => {
        try {
          await navigator.clipboard.writeText(window.location.href);
          toast(t('toast.copied'));
        } catch (e) {
          toast(t('toast.copyFail'), 'error');
        }
      });
    }

    // Network status listener
    window.addEventListener('online', updateNetStatus);
    window.addEventListener('offline', updateNetStatus);

    // Voices loaded asynchronously
    if ('speechSynthesis' in window) {
      window.speechSynthesis.onvoiceschanged = () => {
        populateVoiceSelect();
      };
    }

    // Retry mic button from permission dialog
    if (dom.btnRetryMic) {
      dom.btnRetryMic.addEventListener('click', () => {
        if (dom.micPermissionModal) dom.micPermissionModal.close();
        startRecording();
      });
    }

    // Service Worker registration
    if ('serviceWorker' in navigator && (window.location.protocol === 'https:' || window.location.hostname === 'localhost')) {
      try {
        navigator.serviceWorker.register('sw.js').catch(err => {
          console.warn('SW registration skipped or failed:', err);
        });
      } catch (e) {
        console.warn('SW registration exception:', e);
      }
    }
  }

  /* ---------------- Initialisation ---------------- */
  async function init() {
    cacheDom();
    Visualizer.init();
    LipSync.init();

    // Load saved preferences
    const savedLang = localStorage.getItem(STORAGE.lang);
    if (savedLang && ['fr', 'ar', 'darija', 'en'].includes(savedLang)) {
      state.lang = savedLang;
    } else {
      state.lang = 'darija';
    }

    const savedRate = localStorage.getItem(STORAGE.speechRate);
    if (savedRate) {
      state.speechRate = parseFloat(savedRate);
    } else {
      state.speechRate = 0.72;
    }
    if (dom.rangeSpeechRate) dom.rangeSpeechRate.value = state.speechRate;
    if (dom.rateValue) dom.rateValue.textContent = `${state.speechRate.toFixed(2)}x`;

    await loadInitialKnowledge();
    setupEvents();
    applyLanguage(state.lang);

    // Check if URL has artisan query param
    const params = new URLSearchParams(window.location.search);
    const artisanParam = params.get('artisan');
    if (artisanParam && DEMO_ARTISANS[artisanParam]) {
      renderArtisan(artisanParam);
    }
  }

  // Launch on DOM ready
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }

})();

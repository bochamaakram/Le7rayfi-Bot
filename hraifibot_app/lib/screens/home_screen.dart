import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/artisan_profile.dart';
import '../models/chat_message.dart';
import '../services/ai_service.dart';
import '../services/knowledge_service.dart';
import '../services/localization_service.dart';
import '../services/voice_service.dart';
import '../widgets/artisan_card_sheet.dart';
import '../widgets/nfc_action_sheet.dart';
import '../widgets/qr_display_sheet.dart';
import '../widgets/qr_scanner_sheet.dart';
import '../widgets/robot_face.dart'; // for RobotMood
import '../widgets/sahara_orb.dart';

/// Minimal Moroccan Sahara UI for Le7rayfiBot.
/// Centered around a mesmerizing 3D organic voice orb visualizer.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _conversationScrollController = ScrollController();
  final List<ChatMessage> _messages = [];

  RobotMood _mood = RobotMood.idle;
  String? _currentlySpeakingMessageId;
  String _liveTranscript = '';
  ChatMessage? _activeResponse;

  @override
  void initState() {
    super.initState();
    _initServices();
  }

  Future<void> _initServices() async {
    await KnowledgeService().init();
    await VoiceService().init();
    _setWelcomeMessage();
  }

  void _setWelcomeMessage() {
    final loc = AppLocalization();
    final welcomeText = _getWelcomeForLang(loc.currentLang);
    final welcomeMsg = ChatMessage(
      id: 'welcome',
      sender: MessageSender.bot,
      text: welcomeText,
      isLocal: false,
    );
    setState(() {
      _messages.add(welcomeMsg);
      _activeResponse = welcomeMsg;
    });
  }

  String _getWelcomeForLang(String lang) {
    switch (lang) {
      case 'darija':
        return 'السلام عليكم! أنا حريف بوت، مساعدك الذكي للحرفيين والخدمات. سولني على أي معلم أو صنعة فالمغرب والأقاليم الجنوبية.';
      case 'ar':
        return 'مرحباً بكم! أنا حريف بوت، مساعدكم الذكي للمهن والحرفيين بالمغرب. كيف يمكنني خدمتكم اليوم؟';
      case 'en':
        return 'Welcome! I am Le7rayfiBot, your smart assistant for Moroccan artisans and craftsmanship. How can I help you today?';
      case 'fr':
      default:
        return 'Salam ! Je suis Le7rayfiBot, votre assistant IA pour les artisans et savoir-faire au Maroc. Que recherchez-vous ?';
    }
  }

  void _changeLanguage(String lang) {
    if (AppLocalization().currentLang == lang) return;
    setState(() {
      AppLocalization().currentLang = lang;
      _setWelcomeMessage();
    });
    final text = _getWelcomeForLang(lang);
    _speakText(text, 'lang-change');
  }

  void _handleUserQuestion(String question) {
    final clean = question.trim();
    if (clean.isEmpty) return;
    _textController.clear();

    final loc = AppLocalization();
    final lang = loc.currentLang;

    final userMsg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      sender: MessageSender.user,
      text: clean,
    );

    setState(() {
      _messages.add(userMsg);
      _mood = RobotMood.thinking;
      _liveTranscript = '';
      _activeResponse = null;
    });

    _queryAi(clean, lang);
  }

  Future<void> _queryAi(String question, String lang) async {
    try {
      final result = await AiService().ask(
        question: question,
        lang: lang,
      );

      if (!mounted) return;

      final msgId = 'bot-${DateTime.now().millisecondsSinceEpoch}';
      final botMsg = ChatMessage(
        id: msgId,
        sender: MessageSender.bot,
        text: result.text,
        isLocal: result.isLocal,
      );

      setState(() {
        _messages.add(botMsg);
        _activeResponse = botMsg;
        _mood = RobotMood.speaking;
      });

      _speakText(result.text, msgId);
    } catch (e) {
      if (!mounted) return;
      final loc = AppLocalization();
      final errText = loc.tr('search.noMatch');
      final msgId = 'bot-err-${DateTime.now().millisecondsSinceEpoch}';
      final errBotMsg = ChatMessage(
        id: msgId,
        sender: MessageSender.bot,
        text: errText,
        isLocal: true,
      );

      setState(() {
        _messages.add(errBotMsg);
        _activeResponse = errBotMsg;
        _mood = RobotMood.idle;
      });
    }
  }

  void _speakText(String text, String messageId) {
    setState(() {
      _mood = RobotMood.speaking;
      _currentlySpeakingMessageId = messageId;
    });

    VoiceService().speak(
      text: text,
      lang: AppLocalization().currentLang,
      onComplete: () {
        if (mounted) {
          setState(() {
            _mood = RobotMood.idle;
            _currentlySpeakingMessageId = null;
          });
        }
      },
    );
  }

  void _stopVoice() {
    VoiceService().stopSpeaking();
    VoiceService().stopListening();
    setState(() {
      _mood = RobotMood.idle;
      _currentlySpeakingMessageId = null;
      _liveTranscript = '';
    });
  }

  void _toggleMic() async {
    if (_mood == RobotMood.listening) {
      final buffered = await VoiceService().stopListening(submitBuffer: true);
      setState(() {
        _mood = RobotMood.idle;
        _liveTranscript = '';
      });
      if (buffered != null && buffered.trim().isNotEmpty) {
        _handleUserQuestion(buffered);
      }
      return;
    }

    if (_mood == RobotMood.speaking) {
      _stopVoice();
    }

    setState(() {
      _mood = RobotMood.listening;
      _liveTranscript = '';
    });

    final loc = AppLocalization();
    final success = await VoiceService().startListening(
      currentLang: loc.currentLang,
      onResult: (words) {
        if (mounted) {
          setState(() {
            _liveTranscript = words;
          });
        }
      },
      onError: (err) {
        if (!mounted) return;
        setState(() {
          _mood = RobotMood.error;
          _liveTranscript = '';
        });
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) setState(() => _mood = RobotMood.idle);
        });
      },
      onListeningEnded: () {
        final recognized = VoiceService().lastRecognizedWords;
        if (mounted) {
          setState(() {
            _liveTranscript = '';
          });
        }
        if (recognized.isNotEmpty) {
          _handleUserQuestion(recognized);
        } else {
          if (mounted) setState(() => _mood = RobotMood.idle);
        }
      },
    );

    if (!success && mounted) {
      setState(() => _mood = RobotMood.error);
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) setState(() => _mood = RobotMood.idle);
      });
    }
  }

  void _openToolsSheet() {
    _stopVoice();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _buildToolsActionSheet(ctx),
    );
  }

  void _openNfcSheet(NfcMode mode) {
    _stopVoice();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => NfcActionSheet(
        initialMode: mode,
        onReadSuccess: (artisanId) {
          _showArtisanCard(artisanId);
        },
      ),
    );
  }

  void _openQrScanner() {
    _stopVoice();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => QrScannerSheet(
        onScanned: (code) {
          String artisanId = 'ART-DEMO-01';
          if (code.contains('artisan=')) {
            final uri = Uri.tryParse(code);
            if (uri != null && uri.queryParameters.containsKey('artisan')) {
              artisanId = uri.queryParameters['artisan']!;
            }
          } else if (code.contains('ART-DEMO-')) {
            artisanId = code;
          }
          _showArtisanCard(artisanId);
        },
      ),
    );
  }

  void _openQrDisplay() {
    _stopVoice();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const QrDisplaySheet(),
    );
  }

  void _showArtisanCard(String artisanId) {
    final profile = ArtisanProfile.demoProfiles[artisanId] ??
        ArtisanProfile.demoProfiles['ART-DEMO-01']!;

    setState(() => _mood = RobotMood.happy);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ArtisanCardSheet(profile: profile),
    ).then((_) {
      if (mounted) setState(() => _mood = RobotMood.idle);
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _conversationScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalization();

    return Directionality(
      textDirection: loc.direction,
      child: Scaffold(
        backgroundColor: const Color(0xFF07060A),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF07060A),
                Color(0xFF0B0912),
                Color(0xFF130E14),
              ],
              stops: [0.0, 0.65, 1.0],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // ── 1. Top Minimal Bar ────────────────────────────────
                _buildTopBar(loc),

                // ── 2. Centerpiece: Sahara Voice Orb & Response ───────
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 12),

                        // The 3D Sahara Particle Orb
                        SaharaVoiceOrb(
                          mood: _mood,
                          size: 260,
                          onTap: _toggleMic,
                        ),

                        const SizedBox(height: 14),

                        // Status pill / Live voice transcription
                        _buildStatusIndicator(loc),

                        const SizedBox(height: 16),

                        // Active Intelligent Response Bubble
                        if (_activeResponse != null)
                          _buildActiveResponseCard(_activeResponse!, loc),

                        const SizedBox(height: 16),

                        // Sahara Quick Suggestion Chips
                        _buildSaharaSuggestionChips(loc),

                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),

                // ── 3. Bottom Minimal Input Capsule ───────────────────
                _buildBottomInputBar(loc),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Top Bar ────────────────────────────────────────────────────────
  Widget _buildTopBar(AppLocalization loc) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Minimal Brand Badge
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: Color(0xFFF59E0B),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFFF59E0B),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'LE7RAYFI',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.0,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFD97706).withOpacity(0.18),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: const Color(0xFFD97706).withOpacity(0.35),
                    width: 0.5,
                  ),
                ),
                child: const Text(
                  'الصحراء',
                  style: TextStyle(
                    fontSize: 9,
                    color: Color(0xFFF59E0B),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          // Trilingual Selector Pill
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 0.6,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildLangChip('darija', 'دارجة'),
                _buildLangChip('ar', 'عربية'),
                _buildLangChip('en', 'English'),
              ],
            ),
          ),

          // Tools Sheet Icon (NFC, QR, Conversation)
          IconButton(
            onPressed: _openToolsSheet,
            tooltip: 'أدوات لحرايفي',
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.12),
                  width: 0.6,
                ),
              ),
              child: const Icon(
                Icons.hub_outlined,
                size: 17,
                color: Color(0xFFF59E0B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLangChip(String langCode, String label) {
    final isSelected = AppLocalization().currentLang == langCode;
    return GestureDetector(
      onTap: () => _changeLanguage(langCode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFD97706) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFFD97706).withOpacity(0.4),
                    blurRadius: 8,
                    spreadRadius: 0,
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.black : Colors.white60,
          ),
        ),
      ),
    );
  }

  // ── Status Indicator ───────────────────────────────────────────────
  Widget _buildStatusIndicator(AppLocalization loc) {
    if (_liveTranscript.isNotEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF0284C7).withOpacity(0.16),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF38BDF8).withOpacity(0.4),
            width: 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.mic, size: 14, color: Color(0xFF38BDF8)),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                _liveTranscript,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFFE0F2FE),
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }

    String statusText;
    Color statusColor;
    IconData statusIcon;

    switch (_mood) {
      case RobotMood.listening:
        statusText = loc.isRtl ? 'أنا كانسمع ليك... تكلّم' : 'À votre écoute…';
        statusColor = const Color(0xFF38BDF8);
        statusIcon = Icons.graphic_eq_rounded;
        break;
      case RobotMood.thinking:
        statusText = loc.isRtl ? 'كانفكر فـ الجواب...' : 'Le7rayfi réfléchit…';
        statusColor = const Color(0xFFA855F7);
        statusIcon = Icons.auto_awesome;
        break;
      case RobotMood.speaking:
        statusText = loc.isRtl ? 'حريف كيجاوْب دابا...' : 'Le7rayfi répond…';
        statusColor = const Color(0xFFF59E0B);
        statusIcon = Icons.volume_up_rounded;
        break;
      case RobotMood.error:
        statusText = loc.isRtl ? 'حاول مرة أخرى' : 'Erreur de micro';
        statusColor = Colors.redAccent;
        statusIcon = Icons.error_outline_rounded;
        break;
      case RobotMood.idle:
      default:
        statusText = loc.isRtl ? 'إلمس الدائرة وتكلّم' : 'Touchez l\'orbe pour parler';
        statusColor = Colors.white54;
        statusIcon = Icons.touch_app_outlined;
        break;
    }

    return GestureDetector(
      onTap: _toggleMic,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: statusColor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: statusColor.withOpacity(0.2),
            width: 0.6,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(statusIcon, size: 13, color: statusColor),
            const SizedBox(width: 6),
            Text(
              statusText,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: statusColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Active Response Card (Minimalist Glass Design) ─────────────────
  Widget _buildActiveResponseCard(ChatMessage msg, AppLocalization loc) {
    final isSpeakingThis = _currentlySpeakingMessageId == msg.id;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF13101C).withOpacity(0.85),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFD97706).withOpacity(0.25),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Badge + Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: msg.isLocal
                      ? const Color(0xFF10B981).withOpacity(0.16)
                      : const Color(0xFFA855F7).withOpacity(0.18),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      msg.isLocal ? Icons.offline_pin_rounded : Icons.auto_awesome,
                      size: 11,
                      color: msg.isLocal
                          ? const Color(0xFF10B981)
                          : const Color(0xFFA855F7),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      msg.isLocal
                          ? (loc.isRtl ? 'إجابة محلية' : 'Mode Local')
                          : (loc.isRtl ? 'ذكاء اصطناعي مباشر' : 'IA En Direct'),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: msg.isLocal
                            ? const Color(0xFF10B981)
                            : const Color(0xFFA855F7),
                      ),
                    ),
                  ],
                ),
              ),

              // Audio speaker & copy actions
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    iconSize: 18,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: Icon(
                      isSpeakingThis
                          ? Icons.stop_circle_rounded
                          : Icons.volume_up_rounded,
                      color: isSpeakingThis
                          ? const Color(0xFFF59E0B)
                          : Colors.white54,
                    ),
                    onPressed: () {
                      if (isSpeakingThis) {
                        _stopVoice();
                      } else {
                        _speakText(msg.text, msg.id);
                      }
                    },
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    iconSize: 16,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.copy_rounded, color: Colors.white38),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: msg.text));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(loc.isRtl ? 'تم النسخ' : 'Copié !'),
                          duration: const Duration(seconds: 1),
                          backgroundColor: const Color(0xFFD97706),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Response Body Text
          SelectableText(
            msg.text,
            style: const TextStyle(
              fontSize: 14.5,
              height: 1.6,
              color: Color(0xFFF3F4F6),
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  // ── Sahara Suggestion Chips ────────────────────────────────────────
  Widget _buildSaharaSuggestionChips(AppLocalization loc) {
    final List<({String label, String query})> chips;

    if (loc.currentLang == 'darija') {
      chips = [
        (label: '⚡ تريسيان فالعيون', query: 'كيفاش نلقى تريسيان فالعيون؟'),
        (label: '🔧 بلومبي مستعجل', query: 'خاصني بلومبي مستعجل لروبيني كيسيل'),
        (label: '🪵 نجار فالداخلة', query: 'كنقلب على نجار محترف فالداخلة'),
        (label: '☀️ طاقة شمسية', query: 'شكون كيركب الطاقة الشمسية فالجنوب؟'),
        (label: '🧵 خيمة صحراوية', query: 'شنو هي حرف الصناعة التقليدية فالصحراء؟'),
      ];
    } else if (loc.currentLang == 'ar') {
      chips = [
        (label: '⚡ كهربائي بالعيون', query: 'كيف أجد كهربائياً في العيون؟'),
        (label: '🔧 سباك مستعجل', query: 'أحتاج سباكاً لإصلاح تسرب ماء'),
        (label: '🪵 نجار بالداخلة', query: 'أبحث عن نجار مؤهل في الداخلة'),
        (label: '☀️ طاقة شمسية', query: 'تركيب أنظمة الطاقة الشمسية'),
        (label: '🧵 خيام وتراث', query: 'الصناعات التقليدية في الأقاليم الجنوبية'),
      ];
    } else if (loc.currentLang == 'en') {
      chips = [
        (label: '⚡ Electrician Laayoune', query: 'How to find a verified electrician in Laayoune?'),
        (label: '🔧 Urgent Plumber', query: 'I need an emergency plumber for a leaking pipe'),
        (label: '🪵 Carpenter Dakhla', query: 'Looking for a qualified carpenter in Dakhla'),
        (label: '☀️ Solar Energy', query: 'Who installs solar panels in southern Morocco?'),
        (label: '🧵 Sahara Crafts', query: 'What traditional crafts and tents are in the Sahara?'),
      ];
    } else {
      chips = [
        (label: '⚡ Électricien Laâyoune', query: 'Comment trouver un électricien à Laâyoune ?'),
        (label: '🔧 Plombier urgent', query: 'Je cherche un plombier pour une fuite d\'eau'),
        (label: '🪵 Menuisier Dakhla', query: 'Je cherche un menuisier qualifié à Dakhla'),
        (label: '☀️ Énergie solaire', query: 'Installation solaire dans le Sud marocain'),
        (label: '🧵 Artisanat saharien', query: 'Quels savoir-faire artisanaux au Sahara ?'),
      ];
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: chips.map((c) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              onTap: () => _handleUserQuestion(c.query),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFD97706).withOpacity(0.25),
                    width: 0.6,
                  ),
                ),
                child: Text(
                  c.label,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFFDE68A),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Bottom Input Bar ───────────────────────────────────────────────
  Widget _buildBottomInputBar(AppLocalization loc) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF120E1A).withOpacity(0.92),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: Colors.white.withOpacity(0.12),
            width: 0.7,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Glowing Mic Button
            GestureDetector(
              onTap: _toggleMic,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _mood == RobotMood.listening
                        ? [const Color(0xFF38BDF8), const Color(0xFF0284C7)]
                        : [const Color(0xFFF59E0B), const Color(0xFFD97706)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (_mood == RobotMood.listening
                              ? const Color(0xFF38BDF8)
                              : const Color(0xFFF59E0B))
                          .withOpacity(0.4),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Icon(
                  _mood == RobotMood.listening ? Icons.stop_rounded : Icons.mic,
                  color: Colors.black,
                  size: 20,
                ),
              ),
            ),

            const SizedBox(width: 10),

            // Text Input Field
            Expanded(
              child: TextField(
                controller: _textController,
                textDirection: loc.direction,
                style: const TextStyle(fontSize: 13.5, color: Colors.white),
                decoration: InputDecoration(
                  hintText: loc.isRtl
                      ? 'سول على أي حرفي أو خدمة...'
                      : 'Posez une question sur un artisan…',
                  hintStyle: TextStyle(
                    fontSize: 12.5,
                    color: Colors.white.withOpacity(0.35),
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
                onSubmitted: _handleUserQuestion,
              ),
            ),

            // Send Button
            IconButton(
              icon: const Icon(
                Icons.arrow_upward_rounded,
                size: 20,
                color: Color(0xFFF59E0B),
              ),
              onPressed: () => _handleUserQuestion(_textController.text),
            ),
          ],
        ),
      ),
    );
  }

  // ── Tools & Actions Bottom Sheet ───────────────────────────────────
  Widget _buildToolsActionSheet(BuildContext ctx) {
    final loc = AppLocalization();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
      decoration: const BoxDecoration(
        color: Color(0xFF0F0C18),
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              loc.isRtl ? 'أدوات لحرايفي السريعة' : 'Outils Rapides Le7rayfi',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),

            // NFC & QR Grid
            Row(
              children: [
                Expanded(
                  child: _buildToolButton(
                    icon: Icons.contactless_rounded,
                    label: loc.tr('btn.nfcRead'),
                    color: const Color(0xFF0284C7),
                    onTap: () {
                      Navigator.pop(ctx);
                      _openNfcSheet(NfcMode.read);
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildToolButton(
                    icon: Icons.qr_code_scanner_rounded,
                    label: loc.tr('btn.scanQr'),
                    color: const Color(0xFFD97706),
                    onTap: () {
                      Navigator.pop(ctx);
                      _openQrScanner();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildToolButton(
                    icon: Icons.qr_code_2_rounded,
                    label: loc.tr('btn.qr'),
                    color: const Color(0xFF8B5CF6),
                    onTap: () {
                      Navigator.pop(ctx);
                      _openQrDisplay();
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildToolButton(
                    icon: Icons.history_rounded,
                    label: loc.isRtl ? 'سجل المحادثة' : 'Historique',
                    color: const Color(0xFF10B981),
                    onTap: () {
                      Navigator.pop(ctx);
                      _openFullHistorySheet();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildToolButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.3), width: 0.8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Full History Sheet ─────────────────────────────────────────────
  void _openFullHistorySheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: const BoxDecoration(
            color: Color(0xFF0B0912),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                AppLocalization().isRtl ? 'سجل المحادثات' : 'Historique des échanges',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  itemCount: _messages.length,
                  itemBuilder: (c, idx) {
                    final m = _messages[idx];
                    final isUser = m.sender == MessageSender.user;
                    return Align(
                      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isUser
                              ? const Color(0xFFD97706).withOpacity(0.2)
                              : const Color(0xFF1E1B2E),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          m.text,
                          style: const TextStyle(fontSize: 13, color: Colors.white),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

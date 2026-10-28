import 'package:flutter/material.dart';
import '../models/artisan_profile.dart';
import '../services/localization_service.dart';
import '../services/voice_service.dart';

class ArtisanCardSheet extends StatefulWidget {
  final ArtisanProfile profile;

  const ArtisanCardSheet({super.key, required this.profile});

  @override
  State<ArtisanCardSheet> createState() => _ArtisanCardSheetState();
}

class _ArtisanCardSheetState extends State<ArtisanCardSheet> {
  bool _isSpeaking = false;

  void _toggleSpeak() {
    final loc = AppLocalization();
    final p = widget.profile;
    final lang = loc.currentLang;

    if (_isSpeaking) {
      VoiceService().stopSpeaking();
      setState(() => _isSpeaking = false);
    } else {
      final textToRead = '${p.name.get(lang)}. ${p.trade.get(lang)}. ${p.zone.get(lang)}. ${p.availability.get(lang)}. ${p.note.get(lang)}';
      setState(() => _isSpeaking = true);
      VoiceService().speak(
        text: textToRead,
        lang: lang,
        onComplete: () {
          if (mounted) setState(() => _isSpeaking = false);
        },
      );
    }
  }

  @override
  void dispose() {
    VoiceService().stopSpeaking();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalization();
    final lang = loc.currentLang;
    final p = widget.profile;

    return Directionality(
      textDirection: loc.direction,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Color(0xFF0F172A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Demo Badge Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.4)),
                ),
                child: Text(
                  loc.tr('demo.banner'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFFF59E0B),
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // Artisan Name & Avatar Header
              Row(
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFFD97706), Color(0xFF06B6D4)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF06B6D4).withOpacity(0.4),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.person_rounded, color: Colors.white, size: 34),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.name.get(lang),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          p.trade.get(lang),
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF22D3EE),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Read Aloud / Voice Reader button
                  IconButton.filled(
                    onPressed: _toggleSpeak,
                    style: IconButton.styleFrom(
                      backgroundColor: _isSpeaking ? Colors.redAccent : const Color(0xFF0284C7),
                      padding: const EdgeInsets.all(12),
                    ),
                    icon: Icon(_isSpeaking ? Icons.volume_off_rounded : Icons.volume_up_rounded),
                    tooltip: loc.tr('btn.readAloud'),
                  ),
                ],
              ),

              const SizedBox(height: 20),
              const Divider(color: Colors.white12),
              const SizedBox(height: 12),

              // Details List
              _buildDetailRow(loc.tr('artisan.zone'), p.zone.get(lang), Icons.location_on_outlined),
              _buildDetailRow(loc.tr('artisan.availability'), p.availability.get(lang), Icons.access_time_rounded),
              _buildDetailRow(loc.tr('artisan.contact'), p.contact.get(lang), Icons.phone_outlined),

              const SizedBox(height: 12),
              // Note box
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white10),
                ),
                child: Text(
                  p.note.get(lang),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.7),
                    height: 1.4,
                  ),
                ),
              ),

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD97706),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.check_circle_outline_rounded),
                  label: Text(loc.isRtl ? 'حسناً، فهمت' : 'Fermer la fiche'),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: const Color(0xFFD97706)),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withOpacity(0.6),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

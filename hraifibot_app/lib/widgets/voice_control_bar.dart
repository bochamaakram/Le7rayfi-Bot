import 'package:flutter/material.dart';
import '../services/localization_service.dart';
import 'robot_face.dart';

class VoiceControlBar extends StatelessWidget {
  final RobotMood mood;
  final VoidCallback onMicTap;
  final VoidCallback onCancelVoice;

  const VoiceControlBar({
    super.key,
    required this.mood,
    required this.onMicTap,
    required this.onCancelVoice,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalization();
    final isListening = mood == RobotMood.listening;
    final isSpeaking = mood == RobotMood.speaking;
    final isBusy = isListening || isSpeaking || mood == RobotMood.thinking;

    String statusText = loc.tr('voice.idle');
    Color statusColor = const Color(0xFFD97706);

    if (isListening) {
      statusText = loc.tr('voice.listening');
      statusColor = const Color(0xFF06B6D4);
    } else if (mood == RobotMood.thinking) {
      statusText = loc.tr('voice.processing');
      statusColor = const Color(0xFF8B5CF6);
    } else if (isSpeaking) {
      statusText = loc.tr('voice.speaking');
      statusColor = const Color(0xFF10B981);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: statusColor.withOpacity(0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Glowing Mic Button
          GestureDetector(
            onTap: onMicTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: isListening
                      ? [const Color(0xFF06B6D4), const Color(0xFF0284C7)]
                      : [const Color(0xFFD97706), const Color(0xFFB45309)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isListening ? const Color(0xFF06B6D4) : const Color(0xFFD97706))
                        .withOpacity(0.6),
                    blurRadius: isListening ? 18 : 10,
                    spreadRadius: isListening ? 3 : 1,
                  ),
                ],
              ),
              child: Icon(
                isListening ? Icons.mic : Icons.mic_none_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),

          const SizedBox(width: 14),

          // Status & Info text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (!isBusy)
                  Text(
                    loc.isRtl ? 'أو اختر أحد الأسئلة المقترحة أدناه' : 'Ou touchez une suggestion ci-dessous',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withOpacity(0.55),
                    ),
                  ),
              ],
            ),
          ),

          // Cancel button when speaking or listening
          if (isBusy)
            IconButton(
              onPressed: onCancelVoice,
              icon: const Icon(Icons.stop_circle_outlined, color: Colors.redAccent, size: 30),
              tooltip: loc.tr('voice.cancel'),
            ),
        ],
      ),
    );
  }
}

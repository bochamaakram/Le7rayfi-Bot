import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

enum RobotMood {
  idle,
  listening,
  thinking,
  speaking,
  happy,
  error,
}

class RobotFace extends StatefulWidget {
  final RobotMood mood;
  final VoidCallback? onTap;

  const RobotFace({
    super.key,
    this.mood = RobotMood.idle,
    this.onTap,
  });

  @override
  State<RobotFace> createState() => _RobotFaceState();
}

class _RobotFaceState extends State<RobotFace> with TickerProviderStateMixin {
  // Eye tracking
  double _eyeTargetX = 0.0;
  double _eyeTargetY = 0.0;

  // Blinking
  bool _isBlinking = false;
  Timer? _blinkTimer;

  // Speaking mouth animation
  late AnimationController _mouthController;
  late Animation<double> _mouthAnimation;

  // Mood glow animation
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();

    _mouthController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    )..repeat(reverse: true);
    _mouthAnimation = Tween<double>(begin: 0.2, end: 1.0).animate(
      CurvedAnimation(parent: _mouthController, curve: Curves.easeInOut),
    );

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _startBlinkingLoop();
  }

  void _startBlinkingLoop() {
    _scheduleNextBlink();
  }

  void _scheduleNextBlink() {
    final nextMs = 2600 + Random().nextInt(3400);
    _blinkTimer?.cancel();
    _blinkTimer = Timer(Duration(milliseconds: nextMs), () {
      if (!mounted) return;
      setState(() => _isBlinking = true);
      Timer(const Duration(milliseconds: 130), () {
        if (!mounted) return;
        setState(() => _isBlinking = false);

        // Occasional double blink
        if (Random().nextDouble() > 0.72) {
          Timer(const Duration(milliseconds: 110), () {
            if (!mounted) return;
            setState(() => _isBlinking = true);
            Timer(const Duration(milliseconds: 110), () {
              if (!mounted) return;
              setState(() => _isBlinking = false);
              _scheduleNextBlink();
            });
          });
        } else {
          _scheduleNextBlink();
        }
      });
    });
  }

  @override
  void dispose() {
    _blinkTimer?.cancel();
    _mouthController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  Color _getAntennaColor() {
    switch (widget.mood) {
      case RobotMood.listening:
        return const Color(0xFF06B6D4); // Cyan
      case RobotMood.thinking:
        return const Color(0xFF8B5CF6); // Purple
      case RobotMood.speaking:
        return const Color(0xFF10B981); // Emerald
      case RobotMood.happy:
        return const Color(0xFFF59E0B); // Amber/Gold
      case RobotMood.error:
        return const Color(0xFFEF4444); // Red
      case RobotMood.idle:
        return const Color(0xFFD97706); // Sahara Gold
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onPanUpdate: (details) {
        setState(() {
          _eyeTargetX = ((details.localPosition.dx - 80) / 80).clamp(-1.0, 1.0);
          _eyeTargetY = ((details.localPosition.dy - 80) / 80).clamp(-1.0, 1.0);
        });
      },
      onPanEnd: (_) {
        setState(() {
          _eyeTargetX = 0.0;
          _eyeTargetY = 0.0;
        });
      },
      child: Center(
        child: SizedBox(
          width: 176,
          height: 184,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              // 1. Antenna Rod
              Positioned(
                top: 0,
                child: Container(
                  width: 5,
                  height: 24,
                  decoration: BoxDecoration(
                    color: const Color(0xFF785A28),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),

              // 2. Antenna Glowing Bulb
              Positioned(
                top: -8,
                child: AnimatedBuilder(
                  animation: _glowAnimation,
                  builder: (context, child) {
                    final color = _getAntennaColor();
                    final scale = widget.mood == RobotMood.listening || widget.mood == RobotMood.speaking
                        ? _glowAnimation.value
                        : 0.9;
                    return Container(
                      width: 15,
                      height: 15,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: color.withOpacity(0.85 * scale),
                            blurRadius: 14 * scale,
                            spreadRadius: 4 * scale,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // 3. Robot Head Shell (Sahraoui Sand Gold)
              Positioned(
                top: 18,
                bottom: 0,
                left: 8,
                right: 8,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.all(Radius.elliptical(80, 76)),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFF7EEDF), // Soft light sand
                        Color(0xFFE2CDB0), // Warm desert ochre
                        Color(0xFFB59B77), // Deep dune shadow
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.32),
                        blurRadius: 24,
                        offset: const Offset(0, 12),
                      ),
                      BoxShadow(
                        color: _getAntennaColor().withOpacity(0.18),
                        blurRadius: 28,
                        spreadRadius: 2,
                      ),
                    ],
                    border: Border.all(
                      color: const Color(0xFF87663C).withOpacity(0.35),
                      width: 1.5,
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Eyebrows
                      _buildEyebrows(),

                      // Eyes visor container
                      Positioned(
                        top: 42,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildSingleEye(isLeft: true),
                            const SizedBox(width: 28),
                            _buildSingleEye(isLeft: false),
                          ],
                        ),
                      ),

                      // Cheeks (blush)
                      Positioned(
                        top: 76,
                        child: SizedBox(
                          width: 130,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildCheek(),
                              _buildCheek(),
                            ],
                          ),
                        ),
                      ),

                      // Mouth
                      Positioned(
                        bottom: 24,
                        child: _buildMouth(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEyebrows() {
    double angleL = -0.06;
    double angleR = 0.06;

    if (widget.mood == RobotMood.listening) {
      angleL = -0.22;
      angleR = 0.22;
    } else if (widget.mood == RobotMood.thinking) {
      angleL = 0.20;
      angleR = -0.20;
    } else if (widget.mood == RobotMood.happy) {
      angleL = -0.15;
      angleR = 0.15;
    }

    return Positioned(
      top: 30,
      child: SizedBox(
        width: 110,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Transform.rotate(
              angle: angleL,
              child: Container(
                width: 24,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF523619).withOpacity(0.7),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            Transform.rotate(
              angle: angleR,
              child: Container(
                width: 24,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF523619).withOpacity(0.7),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSingleEye({required bool isLeft}) {
    if (_isBlinking) {
      return Container(
        width: 38,
        height: 6,
        decoration: BoxDecoration(
          color: const Color(0xFF07191E),
          borderRadius: BorderRadius.circular(4),
        ),
      );
    }

    if (widget.mood == RobotMood.happy) {
      // Arched happy anime eyes ^ ^
      return SizedBox(
        width: 38,
        height: 42,
        child: Center(
          child: Container(
            width: 32,
            height: 16,
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: const Color(0xFF22D3EE),
                  width: 5,
                ),
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
          ),
        ),
      );
    }

    // Normal eyes with screen depth
    return Container(
      width: 38,
      height: 44,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.elliptical(20, 24)),
        gradient: const RadialGradient(
          center: Alignment(-0.2, -0.4),
          radius: 0.9,
          colors: [
            Color(0xFF15323A),
            Color(0xFF07191E),
          ],
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black45,
            offset: Offset(0, 3),
            blurRadius: 4,
          ),
        ],
        border: Border.all(
          color: const Color(0xFF87663C).withOpacity(0.35),
          width: 1.2,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Specular reflection
          Positioned(
            top: 5,
            left: isLeft ? 6 : 8,
            child: Container(
              width: 12,
              height: 8,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.85),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          // Pupil (moves with touch or thinking)
          Transform.translate(
            offset: Offset(
              _eyeTargetX * 7 + (widget.mood == RobotMood.thinking ? 4 * sin(DateTime.now().millisecondsSinceEpoch / 200) : 0),
              _eyeTargetY * 6,
            ),
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF22D3EE), // Vibrant Cyan
                boxShadow: const [
                  BoxShadow(
                    color: Color(0xFF22D3EE),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheek() {
    return Container(
      width: 18,
      height: 10,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: const Color(0xFFE28A3B).withOpacity(widget.mood == RobotMood.happy ? 0.6 : 0.28),
      ),
    );
  }

  Widget _buildMouth() {
    if (widget.mood == RobotMood.speaking) {
      return AnimatedBuilder(
        animation: _mouthAnimation,
        builder: (context, child) {
          final openFactor = _mouthAnimation.value;
          return Container(
            width: 24 + (10 * openFactor),
            height: 6 + (14 * openFactor),
            decoration: BoxDecoration(
              color: const Color(0xFF07191E),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFF10B981).withOpacity(0.8),
                width: 1.5,
              ),
            ),
            child: Center(
              child: Container(
                width: 14,
                height: 4 * openFactor,
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          );
        },
      );
    }

    if (widget.mood == RobotMood.happy) {
      return Container(
        width: 32,
        height: 14,
        decoration: BoxDecoration(
          color: const Color(0xFF07191E),
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
          border: Border.all(
            color: const Color(0xFFD97706),
            width: 1.5,
          ),
        ),
      );
    }

    // Default gentle mouth curve
    return Container(
      width: 22,
      height: 5,
      decoration: BoxDecoration(
        color: const Color(0xFF523619).withOpacity(0.6),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

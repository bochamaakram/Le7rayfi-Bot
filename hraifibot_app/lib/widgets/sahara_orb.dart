import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'robot_face.dart'; // for RobotMood enum

/// High-performance 3D Particle Sphere Visualizer inspired by the
/// Moroccan Sahara night sky, desert dunes, and futuristic audio AI orbs.
class SaharaVoiceOrb extends StatefulWidget {
  final RobotMood mood;
  final VoidCallback? onTap;
  final double size;

  const SaharaVoiceOrb({
    super.key,
    required this.mood,
    this.onTap,
    this.size = 280,
  });

  @override
  State<SaharaVoiceOrb> createState() => _SaharaVoiceOrbState();
}

class _SaharaVoiceOrbState extends State<SaharaVoiceOrb>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final List<_SpherePoint> _points = [];
  static const int _numPoints = 480;

  @override
  void initState() {
    super.initState();
    _initPoints();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
  }

  void _initPoints() {
    // Fibonacci sphere distribution for uniform 3D point cloud
    final phi = (1.0 + math.sqrt(5.0)) / 2.0; // golden ratio
    for (int i = 0; i < _numPoints; i++) {
      final y = 1.0 - (i / (_numPoints - 1.0)) * 2.0; // -1 to 1
      final radius = math.sqrt(1.0 - y * y);
      final theta = 2.0 * math.pi * i / phi;
      final x = math.cos(theta) * radius;
      final z = math.sin(theta) * radius;

      // Assign an organic base frequency & color bias
      final lat = math.asin(y.clamp(-1.0, 1.0));
      _points.add(_SpherePoint(
        baseX: x,
        baseY: y,
        baseZ: z,
        lat: lat,
        lon: theta,
        phase: (i * 0.137) % (2 * math.pi),
      ));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              size: Size(widget.size, widget.size),
              painter: _SaharaOrbPainter(
                points: _points,
                progress: _controller.value,
                mood: widget.mood,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SpherePoint {
  final double baseX;
  final double baseY;
  final double baseZ;
  final double lat;
  final double lon;
  final double phase;

  _SpherePoint({
    required this.baseX,
    required this.baseY,
    required this.baseZ,
    required this.lat,
    required this.lon,
    required this.phase,
  });
}

class _SaharaOrbPainter extends CustomPainter {
  final List<_SpherePoint> points;
  final double progress;
  final RobotMood mood;

  _SaharaOrbPainter({
    required this.points,
    required this.progress,
    required this.mood,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = size.width * 0.38;

    // Mood configuration
    double speedMultiplier = 1.0;
    double waveAmplitude = 0.12;
    double pulseScale = 1.0;
    Color glowColor = const Color(0xFF0284C7);
    Color secondaryGlow = const Color(0xFFD97706);

    switch (mood) {
      case RobotMood.listening:
        speedMultiplier = 1.6;
        waveAmplitude = 0.22;
        pulseScale = 1.0 + 0.08 * math.sin(progress * 2 * math.pi * 3);
        glowColor = const Color(0xFF06B6D4);
        secondaryGlow = const Color(0xFFF59E0B);
        break;
      case RobotMood.speaking:
        speedMultiplier = 1.4;
        waveAmplitude = 0.18;
        pulseScale = 1.0 + 0.05 * math.sin(progress * 2 * math.pi * 2.5);
        glowColor = const Color(0xFF8B5CF6);
        secondaryGlow = const Color(0xFFE08A3C);
        break;
      case RobotMood.thinking:
        speedMultiplier = 2.4;
        waveAmplitude = 0.14;
        pulseScale = 0.96;
        glowColor = const Color(0xFF6366F1);
        secondaryGlow = const Color(0xFFEC4899);
        break;
      case RobotMood.happy:
        speedMultiplier = 1.8;
        waveAmplitude = 0.16;
        pulseScale = 1.06;
        glowColor = const Color(0xFF10B981);
        secondaryGlow = const Color(0xFFF59E0B);
        break;
      case RobotMood.error:
        speedMultiplier = 0.8;
        waveAmplitude = 0.08;
        pulseScale = 0.94;
        glowColor = const Color(0xFFEF4444);
        secondaryGlow = const Color(0xFF78350F);
        break;
      case RobotMood.idle:
        speedMultiplier = 1.0;
        waveAmplitude = 0.10;
        pulseScale = 1.0 + 0.03 * math.sin(progress * 2 * math.pi);
        glowColor = const Color(0xFF0284C7);
        secondaryGlow = const Color(0xFFD97706);
        break;
    }

    final t = progress * 2 * math.pi * speedMultiplier;

    // 1. Draw subtle background radial glow (Sahara night atmosphere)
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          glowColor.withOpacity(0.24),
          secondaryGlow.withOpacity(0.12),
          Colors.transparent,
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: baseRadius * 1.35));
    canvas.drawCircle(center, baseRadius * 1.35, glowPaint);

    // 2. Compute 3D rotation angles
    final rotY = t * 0.45;
    final rotX = 0.35 + 0.18 * math.sin(t * 0.25);
    final cosY = math.cos(rotY);
    final sinY = math.sin(rotY);
    final cosX = math.cos(rotX);
    final sinX = math.sin(rotX);

    // 3. Project and collect transformed points
    final List<_ProjectedPoint> projected = [];

    for (final pt in points) {
      // Harmonic surface wave displacement
      final wave1 = math.sin(3.0 * pt.lat + 2.0 * pt.lon + t * 1.5 + pt.phase);
      final wave2 = math.cos(2.0 * pt.lat - 3.0 * pt.lon + t * 1.2);
      final displacement = 1.0 + waveAmplitude * (wave1 * 0.6 + wave2 * 0.4);

      final r = baseRadius * displacement * pulseScale;

      final x = pt.baseX * r;
      final y = pt.baseY * r;
      final z = pt.baseZ * r;

      // Rotate around Y
      final x1 = x * cosY + z * sinY;
      final z1 = -x * sinY + z * cosY;

      // Rotate around X
      final y2 = y * cosX - z1 * sinX;
      final z2 = y * sinX + z1 * cosX;

      // Depth normalized [-1, 1]
      final normZ = (z2 / (baseRadius * 1.3)).clamp(-1.0, 1.0);

      // Perspective projection
      const cameraDistance = 800.0;
      final scale = cameraDistance / (cameraDistance - z2);

      final px = center.dx + x1 * scale;
      final py = center.dy + y2 * scale;

      projected.add(_ProjectedPoint(
        offset: Offset(px, py),
        depth: normZ,
        lon: pt.lon,
        lat: pt.lat,
      ));
    }

    // Sort by depth (back to front) for natural 3D rendering
    projected.sort((a, b) => a.depth.compareTo(b.depth));

    // 4. Render points with depth-based color & size
    final paint = Paint()..style = PaintingStyle.fill;

    for (final p in projected) {
      final depthFactor = (p.depth + 1.0) / 2.0; // 0 (back) to 1 (front)

      // Color interpolation: Cyan/Azure -> Violet -> Sahara Gold
      final Color pointColor;
      if (p.depth > 0.3) {
        // Front highlighted: Azure cyan with sand gold rim
        final ratio = ((p.depth - 0.3) / 0.7).clamp(0.0, 1.0);
        pointColor = Color.lerp(
          const Color(0xFF38BDF8), // Electric cyan
          const Color(0xFFF59E0B), // Sahara Amber Gold
          ratio * 0.45,
        )!;
      } else if (p.depth > -0.2) {
        // Mid-plane: Violet / Purple
        final ratio = ((p.depth + 0.2) / 0.5).clamp(0.0, 1.0);
        pointColor = Color.lerp(
          const Color(0xFFA855F7), // Twilight violet
          const Color(0xFF38BDF8), // Cyan
          ratio,
        )!;
      } else {
        // Background: Deep indigo / magenta rim
        final ratio = ((p.depth + 1.0) / 0.8).clamp(0.0, 1.0);
        pointColor = Color.lerp(
          const Color(0xFF4338CA), // Deep indigo
          const Color(0xFFA855F7), // Violet
          ratio,
        )!;
      }

      // Radius & Opacity based on depth
      final pointRadius = 1.1 + depthFactor * 2.6; // 1.1px to 3.7px
      final opacity = (0.18 + depthFactor * 0.82).clamp(0.15, 1.0);

      paint.color = pointColor.withOpacity(opacity);
      canvas.drawCircle(p.offset, pointRadius, paint);

      // Subtle glow halo for closest front particles
      if (p.depth > 0.55) {
        final haloPaint = Paint()
          ..color = pointColor.withOpacity((p.depth - 0.55) * 0.35)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(p.offset, pointRadius * 2.2, haloPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SaharaOrbPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.mood != mood;
  }
}

class _ProjectedPoint {
  final Offset offset;
  final double depth;
  final double lon;
  final double lat;

  _ProjectedPoint({
    required this.offset,
    required this.depth,
    required this.lon,
    required this.lat,
  });
}

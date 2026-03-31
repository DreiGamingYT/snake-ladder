import 'dart:math';
import 'package:flutter/material.dart';

class ConfettiOverlay extends StatefulWidget {
  final bool active;
  const ConfettiOverlay({super.key, required this.active});

  @override
  State<ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<ConfettiOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late List<_Particle> _particles;
  final _rnd = Random();

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 4))
      ..addListener(() => setState(() {}));
    _particles = _buildParticles();
    if (widget.active) _ctrl.forward();
  }

  @override
  void didUpdateWidget(covariant ConfettiOverlay old) {
    super.didUpdateWidget(old);
    if (widget.active && !old.active) {
      _particles = _buildParticles();
      _ctrl.forward(from: 0);
    }
    if (!widget.active) _ctrl.stop();
  }

  List<_Particle> _buildParticles() => List.generate(120, (_) {
    return _Particle(
      x: _rnd.nextDouble(),
      delay: _rnd.nextDouble() * 0.5,
      speed: 0.3 + _rnd.nextDouble() * 0.7,
      size: 6 + _rnd.nextDouble() * 10,
      color: _colors[_rnd.nextInt(_colors.length)],
      shape: _rnd.nextBool(),
      angle: _rnd.nextDouble() * 2 * pi,
      swing: (_rnd.nextDouble() - 0.5) * 0.15,
    );
  });

  static const _colors = [
    Color(0xFFFFD600), Color(0xFFE53935), Color(0xFF1E88E5),
    Color(0xFF43A047), Color(0xFFE91E63), Color(0xFF00BCD4),
    Color(0xFFFF6D00), Color(0xFFAA00FF), Color(0xFFFFFFFF),
  ];

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active && _ctrl.value == 0) return const SizedBox.shrink();
    return IgnorePointer(
      child: CustomPaint(
        size: MediaQuery.of(context).size,
        painter: _ConfettiPainter(_particles, _ctrl.value),
      ),
    );
  }
}

class _Particle {
  final double x;
  final double delay;
  final double speed;
  final double size;
  final Color color;
  final bool shape; // true = rectangle, false = circle
  final double angle;
  final double swing;

  const _Particle({
    required this.x,
    required this.delay,
    required this.speed,
    required this.size,
    required this.color,
    required this.shape,
    required this.angle,
    required this.swing,
  });
}

class _ConfettiPainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;

  _ConfettiPainter(this.particles, this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (final p in particles) {
      final t = ((progress - p.delay) / (1 - p.delay)).clamp(0.0, 1.0);
      if (t <= 0) continue;

      final y = t * p.speed * size.height * 1.5;
      final x = p.x * size.width + sin(t * pi * 4 + p.angle) * p.swing * size.width;
      final opacity = t < 0.8 ? 1.0 : (1 - (t - 0.8) / 0.2);
      final rotation = t * pi * 6 + p.angle;

      paint.color = p.color.withValues(alpha: opacity.clamp(0.0, 1.0));

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rotation);

      if (p.shape) {
        canvas.drawRect(
          Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.5),
          paint,
        );
      } else {
        canvas.drawCircle(Offset.zero, p.size / 2, paint);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) => old.progress != progress;
}
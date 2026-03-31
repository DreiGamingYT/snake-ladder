import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/game_provider.dart';

class DiceWidget extends StatelessWidget {
  const DiceWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, game, _) {
        final isAdv = game.gameMode == GameMode.advanced;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Dice face(s)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _AnimatedDice(value: game.dice1, isRolling: game.isRolling),
                  if (game.useDoubleDice || (game.isRolling && game.useDoubleDice)) ...[
                    const SizedBox(width: 12),
                    _AnimatedDice(value: game.dice2, isRolling: game.isRolling, delay: 50),
                  ],
                ],
              ),
              const SizedBox(height: 10),
              // Controls row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Double dice toggle (advanced only)
                  if (isAdv) ...[
                    _DoubleDiceToggle(
                      active: game.useDoubleDice,
                      enabled: game.canRoll && !game.isRolling,
                      onTap: game.toggleDoubleDiceThisRoll,
                    ),
                    const SizedBox(width: 12),
                  ],
                  _RollButton(
                    canRoll: game.canRoll && !game.isRolling && !game.isMoving,
                    isRolling: game.isRolling,
                    onTap: game.rollDice,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Animated single die ───────────────────────────────────────────────────────

class _AnimatedDice extends StatelessWidget {
  final int value;
  final bool isRolling;
  final int delay;
  const _AnimatedDice({required this.value, required this.isRolling, this.delay = 0});

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: isRolling ? 1.15 : 1.0,
      duration: Duration(milliseconds: 120 + delay),
      child: Container(
        width: 62,
        height: 62,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 8,
              offset: const Offset(3, 5),
            ),
          ],
        ),
        child: CustomPaint(painter: _DiceFacePainter(value: value)),
      ),
    );
  }
}

// ── Roll button ───────────────────────────────────────────────────────────────

class _RollButton extends StatelessWidget {
  final bool canRoll;
  final bool isRolling;
  final VoidCallback onTap;
  const _RollButton({required this.canRoll, required this.isRolling, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: canRoll ? onTap : null,
      child: AnimatedOpacity(
        opacity: canRoll ? 1.0 : 0.5,
        duration: const Duration(milliseconds: 200),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: canRoll
                  ? [const Color(0xFFFFD600), const Color(0xFFFFAB00)]
                  : [Colors.grey.shade500, Colors.grey.shade700],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: canRoll
                ? [const BoxShadow(color: Color(0x88FFAB00), blurRadius: 10, offset: Offset(0, 4))]
                : [],
          ),
          child: Text(
            isRolling ? '🎲 Rolling…' : '🎲 Roll Dice',
            style: TextStyle(
              color: canRoll ? const Color(0xFF4E2B00) : Colors.white60,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Double dice toggle ────────────────────────────────────────────────────────

class _DoubleDiceToggle extends StatelessWidget {
  final bool active;
  final bool enabled;
  final VoidCallback onTap;
  const _DoubleDiceToggle({required this.active, required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF7E57C2) : Colors.white10,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: active ? const Color(0xFFB39DDB) : Colors.white24,
            width: 1.5,
          ),
        ),
        child: Text(
          '🎲🎲',
          style: TextStyle(fontSize: active ? 20 : 17),
        ),
      ),
    );
  }
}

// ── Dice face painter ─────────────────────────────────────────────────────────

class _DiceFacePainter extends CustomPainter {
  final int value;
  _DiceFacePainter({required this.value});

  static const _dots = {
    1: [(0.50, 0.50)],
    2: [(0.28, 0.28), (0.72, 0.72)],
    3: [(0.28, 0.28), (0.50, 0.50), (0.72, 0.72)],
    4: [(0.28, 0.28), (0.72, 0.28), (0.28, 0.72), (0.72, 0.72)],
    5: [(0.28, 0.28), (0.72, 0.28), (0.50, 0.50), (0.28, 0.72), (0.72, 0.72)],
    6: [(0.28, 0.22), (0.72, 0.22), (0.28, 0.50), (0.72, 0.50), (0.28, 0.78), (0.72, 0.78)],
  };

  @override
  void paint(Canvas canvas, Size size) {
    final dots = _dots[value.clamp(1, 6)] ?? [];
    final r = size.width * 0.085;
    final paint = Paint()..color = const Color(0xFF1A237E);
    for (final d in dots) {
      canvas.drawCircle(Offset(d.$1 * size.width, d.$2 * size.height), r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DiceFacePainter old) => old.value != value;
}
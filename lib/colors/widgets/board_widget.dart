import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/game_provider.dart';
import '../constants/board_data.dart';

class BoardWidget extends StatelessWidget {
  const BoardWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, game, _) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: InteractiveViewer(
            minScale: 0.8,
            maxScale: 3.5,
            boundaryMargin: const EdgeInsets.all(40),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF5D4037), width: 4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(4, 4),
                  ),
                ],
              ),
              child: AspectRatio(
                aspectRatio: 1,
                child: LayoutBuilder(
                  builder: (_, constraints) {
                    final size = constraints.maxWidth;
                    final cs = size / 10; // cell size
                    return Stack(
                      children: [
                        // Board
                        CustomPaint(
                          size: Size(size, size),
                          painter: _BoardPainter(
                            cellSize: cs,
                            gameMode: game.gameMode,
                          ),
                        ),
                        // Player tokens (step-by-step via AnimatedPositioned)
                        ...game.players.asMap().entries.map((e) {
                          final idx = e.key;
                          final p = e.value;
                          if (p.position == 0) return const SizedBox.shrink();
                          final center = _cellCenter(p.position, cs);
                          // Slight offset so tokens don't overlap exactly
                          final offsets = [
                            const Offset(-9, -9),
                            const Offset(9, -9),
                            const Offset(-9, 9),
                            const Offset(9, 9),
                            const Offset(0, -12),
                            const Offset(0, 12),
                          ];
                          final off = offsets[idx % offsets.length];
                          return AnimatedPositioned(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeOut,
                            left: center.dx - 14 + off.dx,
                            top: center.dy - 14 + off.dy,
                            child: _Token(
                              avatar: p.avatar,
                              color: p.color,
                              isCurrent: idx == game.currentPlayerIndex &&
                                  game.phase == GamePhase.playing,
                            ),
                          );
                        }),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  static Offset _cellCenter(int sq, double cs) {
    final idx = sq - 1;
    final row = idx ~/ 10;
    var col = idx % 10;
    if (row % 2 == 1) col = 9 - col;
    final displayRow = 9 - row;
    return Offset(col * cs + cs / 2, displayRow * cs + cs / 2);
  }
}

// ── Token ─────────────────────────────────────────────────────────────────────

class _Token extends StatelessWidget {
  final String avatar;
  final Color color;
  final bool isCurrent;
  const _Token({required this.avatar, required this.color, required this.isCurrent});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: isCurrent ? Colors.white : Colors.white54,
          width: isCurrent ? 2.5 : 1.5,
        ),
        boxShadow: [
          if (isCurrent)
            BoxShadow(color: color.withOpacity(0.7), blurRadius: 10, spreadRadius: 2),
          const BoxShadow(color: Colors.black38, blurRadius: 3),
        ],
      ),
      child: Center(child: Text(avatar, style: const TextStyle(fontSize: 14))),
    );
  }
}

// ── Board Painter ─────────────────────────────────────────────────────────────

class _BoardPainter extends CustomPainter {
  final double cellSize;
  final GameMode gameMode;
  _BoardPainter({required this.cellSize, required this.gameMode});

  static const _colorA = Color(0xFFF9F6EF);
  static const _colorB = Color(0xFFD7E8D0);

  @override
  void paint(Canvas canvas, Size size) {
    _drawCells(canvas);
    if (gameMode == GameMode.advanced) _drawSpecialTiles(canvas);
    _drawLadders(canvas);
    _drawSnakes(canvas);
    _drawNumbers(canvas);
    if (gameMode == GameMode.advanced) _drawSafeZoneMarkers(canvas);
  }

  void _drawCells(Canvas canvas) {
    for (int r = 0; r < 10; r++) {
      for (int c = 0; c < 10; c++) {
        final paint = Paint()
          ..color = (r + c) % 2 == 0 ? _colorA : _colorB
          ..style = PaintingStyle.fill;
        canvas.drawRect(Rect.fromLTWH(c * cellSize, r * cellSize, cellSize, cellSize), paint);
      }
    }
    // Grid lines
    final gp = Paint()..color = const Color(0xFF8BC34A).withOpacity(0.3)..strokeWidth = 0.5;
    for (int i = 0; i <= 10; i++) {
      canvas.drawLine(Offset(i * cellSize, 0), Offset(i * cellSize, 10 * cellSize), gp);
      canvas.drawLine(Offset(0, i * cellSize), Offset(10 * cellSize, i * cellSize), gp);
    }
  }

  void _drawSpecialTiles(Canvas canvas) {
    for (final entry in kAdvancedTiles.entries) {
      final sq = entry.key;
      final tile = entry.value;
      final c = _cellCenter(sq);
      final rect = Rect.fromCenter(center: c, width: cellSize - 2, height: cellSize - 2);

      // Tinted background
      canvas.drawRect(
        rect,
        Paint()..color = tile.tileColor.withOpacity(0.28),
      );

      // Rounded border
      final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(4));
      canvas.drawRRect(rrect, Paint()
        ..color = tile.tileColor.withOpacity(0.7)
        ..strokeWidth = 1.2
        ..style = PaintingStyle.stroke);

      // Emoji label
      _drawText(canvas, tile.emoji, c + Offset(0, cellSize * 0.1), cellSize * 0.3);
    }
  }

  void _drawSafeZoneMarkers(Canvas canvas) {
    for (final sq in kSafeZones) {
      if (kSnakes.containsKey(sq)) {
        // Draw a shield overlay on this snake head
        final c = _cellCenter(sq);
        canvas.drawCircle(c, cellSize * 0.2,
            Paint()..color = const Color(0xFF0288D1).withOpacity(0.4));
        _drawText(canvas, '🛡️', c, cellSize * 0.28);
      }
    }
  }

  void _drawNumbers(Canvas canvas) {
    for (int sq = 1; sq <= 100; sq++) {
      final c = _cellCenter(sq);
      final tp = TextPainter(
        text: TextSpan(
          text: '$sq',
          style: TextStyle(
            color: const Color(0xFF33691E),
            fontSize: cellSize * 0.19,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(c.dx - tp.width / 2, c.dy - tp.height / 2 - cellSize * 0.2));
    }
  }

  void _drawSnakes(Canvas canvas) {
    for (final entry in kSnakes.entries) {
      final head = _cellCenter(entry.key);
      final tail = _cellCenter(entry.value);

      // Check if this is a safe zone (draw differently)
      final isSafe = gameMode == GameMode.advanced && kSafeZones.contains(entry.key);

      final bodyPaint = Paint()
        ..color = isSafe
            ? const Color(0xFF90A4AE).withOpacity(0.6)
            : const Color(0xFFB71C1C)
        ..strokeWidth = cellSize * 0.13
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      final ctrl1 = Offset(
        head.dx + (tail.dx - head.dx) * 0.25 + 20,
        head.dy + (tail.dy - head.dy) * 0.25,
      );
      final ctrl2 = Offset(
        head.dx + (tail.dx - head.dx) * 0.75 - 20,
        head.dy + (tail.dy - head.dy) * 0.75,
      );

      final path = Path()
        ..moveTo(head.dx, head.dy)
        ..cubicTo(ctrl1.dx, ctrl1.dy, ctrl2.dx, ctrl2.dy, tail.dx, tail.dy);

      canvas.drawPath(path, bodyPaint);

      if (!isSafe) {
        canvas.drawPath(
          path,
          Paint()
            ..color = const Color(0xFFE53935).withOpacity(0.45)
            ..strokeWidth = cellSize * 0.065
            ..strokeCap = StrokeCap.round
            ..style = PaintingStyle.stroke,
        );
      }

      // Head circle
      canvas.drawCircle(head, cellSize * 0.12,
          Paint()..color = isSafe ? Colors.grey : const Color(0xFF7B1FA2));
      // Eyes
      const eo = 0.045;
      canvas.drawCircle(Offset(head.dx - cellSize * eo, head.dy - cellSize * eo),
          cellSize * 0.028, Paint()..color = Colors.white);
      canvas.drawCircle(Offset(head.dx + cellSize * eo, head.dy - cellSize * eo),
          cellSize * 0.028, Paint()..color = Colors.white);
    }
  }

  void _drawLadders(Canvas canvas) {
    for (final entry in kLadders.entries) {
      final bottom = _cellCenter(entry.key);
      final top = _cellCenter(entry.value);
      final dx = top.dx - bottom.dx;
      final dy = top.dy - bottom.dy;
      final len = Offset(dx, dy).distance;
      final nx = (-dy / len) * cellSize * 0.085;
      final ny = (dx / len) * cellSize * 0.085;

      final railPaint = Paint()
        ..color = const Color(0xFF6D4C41)
        ..strokeWidth = cellSize * 0.065
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(Offset(bottom.dx + nx, bottom.dy + ny),
          Offset(top.dx + nx, top.dy + ny), railPaint);
      canvas.drawLine(Offset(bottom.dx - nx, bottom.dy - ny),
          Offset(top.dx - nx, top.dy - ny), railPaint);

      final rungPaint = Paint()
        ..color = const Color(0xFF8D6E63)
        ..strokeWidth = cellSize * 0.05
        ..strokeCap = StrokeCap.round;

      final steps = (len / (cellSize * 0.38)).round().clamp(2, 12);
      for (int i = 0; i <= steps; i++) {
        final t = i / steps;
        final rx = bottom.dx + dx * t;
        final ry = bottom.dy + dy * t;
        canvas.drawLine(Offset(rx + nx, ry + ny), Offset(rx - nx, ry - ny), rungPaint);
      }
    }
  }

  void _drawText(Canvas canvas, String text, Offset center, double size) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(fontSize: size)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  Offset _cellCenter(int sq) {
    final idx = sq - 1;
    final row = idx ~/ 10;
    var col = idx % 10;
    if (row % 2 == 1) col = 9 - col;
    final displayRow = 9 - row;
    return Offset(col * cellSize + cellSize / 2, displayRow * cellSize + cellSize / 2);
  }

  @override
  bool shouldRepaint(covariant _BoardPainter old) => old.gameMode != gameMode;
}
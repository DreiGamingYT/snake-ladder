import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/game_provider.dart';
import '../constants/board_data.dart';

class PlayerInfoPanel extends StatelessWidget {
  const PlayerInfoPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, game, _) {
        return SizedBox(
          height: 76,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            itemCount: game.players.length,
            itemBuilder: (ctx, i) {
              final p = game.players[i];
              final isCurrent = i == game.currentPlayerIndex;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isCurrent ? p.color : Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isCurrent ? Colors.white : Colors.transparent,
                    width: 2,
                  ),
                  boxShadow: isCurrent
                      ? [BoxShadow(color: p.color.withValues(alpha: 0.5), blurRadius: 10)]
                      : [],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(p.avatar, style: TextStyle(fontSize: isCurrent ? 26 : 20)),
                    const SizedBox(width: 8),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.name,
                          style: TextStyle(
                            color: isCurrent ? Colors.white : Colors.white60,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              p.position == 0 ? 'Start' : 'Sq ${p.position}',
                              style: TextStyle(
                                color: isCurrent ? Colors.white70 : Colors.white38,
                                fontSize: 11,
                              ),
                            ),
                            if (p.skipNextTurn) ...[
                              const SizedBox(width: 4),
                              const Text('💤', style: TextStyle(fontSize: 11)),
                            ],
                          ],
                        ),
                      ],
                    ),
                    // Power-up badges
                    if (p.powerUps.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: p.powerUps
                            .map((pu) => Text(pu.emoji, style: const TextStyle(fontSize: 13)))
                            .toList(),
                      ),
                    ],
                    if (game.phase == GamePhase.finished && game.winner == p) ...[
                      const SizedBox(width: 6),
                      const Text('🏆', style: TextStyle(fontSize: 18)),
                    ],
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

// ── Timer bar ─────────────────────────────────────────────────────────────────

class TimerBar extends StatelessWidget {
  const TimerBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, game, _) {
        final s = game.timerSeconds.clamp(0, 30);
        final color = s <= 10 ? Colors.red.shade400 : s <= 20 ? Colors.orange.shade400 : Colors.green.shade400;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              Icon(Icons.timer_outlined, color: color, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: s / 30,
                    backgroundColor: Colors.white24,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 10,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text('${s}s',
                  style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
        );
      },
    );
  }
}

// ── Power-up action bar ───────────────────────────────────────────────────────

class PowerUpBar extends StatelessWidget {
  const PowerUpBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, game, _) {
        if (game.gameMode != GameMode.advanced) return const SizedBox.shrink();
        if (game.phase != GamePhase.playing) return const SizedBox.shrink();
        if (!game.canRoll && !game.isMoving) return const SizedBox.shrink();

        final player = game.currentPlayer;
        if (player.powerUps.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Power-ups: ',
                  style: TextStyle(color: Colors.white60, fontSize: 12)),
              ...player.powerUps.map((pu) => _PowerUpButton(pu: pu, game: game)),
            ],
          ),
        );
      },
    );
  }
}

class _PowerUpButton extends StatelessWidget {
  final PowerUp pu;
  final GameProvider game;
  const _PowerUpButton({required this.pu, required this.game});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        switch (pu) {
          case PowerUp.extraRoll:
            if (!game.canRoll) game.useExtraRoll();
            break;
          case PowerUp.skipOpponent:
            game.initiateSkipOpponent();
            break;
          case PowerUp.shield:
          // Shield is auto-used; show info
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('🛡️ Shield activates automatically when you hit a snake!'),
                duration: Duration(seconds: 2),
                backgroundColor: Color(0xFF0288D1),
              ),
            );
            break;
        }
      },
      child: Container(
        margin: const EdgeInsets.only(left: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white12,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white30),
        ),
        child: Text(
          '${pu.emoji} ${pu.label}',
          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

// ── Dice history row ──────────────────────────────────────────────────────────

class DiceHistoryBar extends StatelessWidget {
  const DiceHistoryBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, game, _) {
        if (game.diceHistory.isEmpty) return const SizedBox.shrink();
        return SizedBox(
          height: 38,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            itemCount: game.diceHistory.length,
            itemBuilder: (_, i) {
              final h = game.diceHistory[i];
              final color = h['color'] as Color;
              final rolls = h['rolls'] as List<int>;
              final total = h['total'] as int;
              return Container(
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: i == 0 ? 0.35 : 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: color.withValues(alpha: i == 0 ? 0.8 : 0.3), width: i == 0 ? 1.5 : 1),
                ),
                child: Text(
                  '${h['avatar']} ${rolls.length == 1 ? '$total' : '${rolls[0]}+${rolls[1]}=$total'}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: i == 0 ? 1.0 : 0.6),
                    fontSize: 12,
                    fontWeight: i == 0 ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
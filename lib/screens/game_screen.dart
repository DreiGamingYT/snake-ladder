import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../colors/widgets/board_widget.dart';
import '../colors/widgets/dice_widget.dart';
import '../colors/widgets/player_info_panel.dart';
import '../colors/widgets/confetti_widget.dart';
import '../colors/widgets/move_history_sheet.dart';

class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A2A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        title: Consumer<GameProvider>(
          builder: (_, game, __) => Text(
            game.gameMode == GameMode.advanced
                ? '⚡ Advanced Mode'
                : '🐍 Classic Mode',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        actions: [
          Consumer<GameProvider>(
            builder: (_, game, __) => Row(children: [
              IconButton(
                icon: Icon(game.musicEnabled ? Icons.music_note : Icons.music_off, size: 20),
                onPressed: game.toggleMusic,
              ),
              IconButton(
                icon: Icon(game.sfxEnabled ? Icons.volume_up : Icons.volume_off, size: 20),
                onPressed: game.toggleSFX,
              ),
              IconButton(
                icon: const Icon(Icons.history, size: 20),
                tooltip: 'Move History',
                onPressed: () => MoveHistorySheet.show(context),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, size: 20),
                onPressed: () {
                  context.read<GameProvider>().resetGame();
                  Navigator.pop(context);
                },
              ),
            ]),
          ),
        ],
      ),
      body: Consumer<GameProvider>(
        builder: (context, game, _) {
          // Trigger win dialog
          if (game.phase == GamePhase.finished) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (ModalRoute.of(context)?.isCurrent ?? false) {
                _showWinDialog(context, game);
              }
            });
          }

          // Trigger swap/skip dialogs
          if (game.phase == GamePhase.pendingSwap) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (ModalRoute.of(context)?.isCurrent ?? false) {
                _showPickPlayerDialog(
                  context, game,
                  title: '🔄 Swap Positions',
                  subtitle: 'Choose a player to swap with',
                  targetIndices: game.swapTargetIndices,
                  onPick: game.resolveSwap,
                  onCancel: game.cancelPending,
                );
              }
            });
          }

          if (game.phase == GamePhase.pendingSkipOpponent) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (ModalRoute.of(context)?.isCurrent ?? false) {
                _showPickPlayerDialog(
                  context, game,
                  title: '🚫 Skip Opponent',
                  subtitle: 'Choose a player to skip',
                  targetIndices: game.swapTargetIndices,
                  onPick: game.resolveSkipOpponent,
                  onCancel: game.cancelPending,
                );
              }
            });
          }

          return Stack(
            children: [
              // Main layout
              LayoutBuilder(
                builder: (ctx, constraints) {
                  if (constraints.maxWidth > constraints.maxHeight) {
                    return _LandscapeLayout();
                  }
                  return _PortraitLayout();
                },
              ),

              // Event cutscene overlay
              if (game.currentEvent != GameEvent.none)
                _CutsceneOverlay(event: game.currentEvent, message: game.message),

              // Confetti
              ConfettiOverlay(active: game.phase == GamePhase.finished),
            ],
          );
        },
      ),
    );
  }

  void _showWinDialog(BuildContext context, GameProvider game) {
    if (game.winner == null) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1B5E20), Color(0xFF1A237E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.amber, width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🎉 Game Over! 🎉',
                  style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Text(game.winner!.avatar, style: const TextStyle(fontSize: 72)),
              const SizedBox(height: 6),
              Text('${game.winner!.name} Wins!',
                  style: TextStyle(
                      color: game.winner!.color, fontSize: 26, fontWeight: FontWeight.w900),
                  textAlign: TextAlign.center),
              const SizedBox(height: 4),
              const Text('🏆 Congratulations! 🏆',
                  style: TextStyle(color: Colors.white60, fontSize: 14)),
              const SizedBox(height: 16),
              // Quick stats
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: game.players.map((p) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(children: [
                      Text('${p.avatar} ${p.name}: ',
                          style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      Text('${p.totalMoves} moves  🐍${p.snakesHit}  🪜${p.laddersClimbed}',
                          style: const TextStyle(color: Colors.white, fontSize: 12)),
                    ]),
                  )).toList(),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _DlgBtn(
                    label: '🏠 Menu',
                    onTap: () {
                      Navigator.pop(context);
                      game.resetGame();
                      Navigator.pop(context);
                    },
                  ),
                  _DlgBtn(
                    label: '🔄 Play Again',
                    isPrimary: true,
                    onTap: () {
                      Navigator.pop(context);
                      game.resetGame();
                      game.startGame();
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPickPlayerDialog(
      BuildContext context,
      GameProvider game, {
        required String title,
        required String subtitle,
        required List<int> targetIndices,
        required void Function(int) onPick,
        required VoidCallback onCancel,
      }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: const Color(0xFF1B2B1B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 13)),
              const SizedBox(height: 18),
              ...targetIndices.map((idx) {
                final p = game.players[idx];
                return GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    onPick(idx);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: p.color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: p.color.withValues(alpha: 0.5)),
                    ),
                    child: Row(children: [
                      Text(p.avatar, style: const TextStyle(fontSize: 24)),
                      const SizedBox(width: 12),
                      Text(p.name,
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                      const Spacer(),
                      Text('Sq ${p.position}',
                          style: const TextStyle(color: Colors.white54, fontSize: 12)),
                    ]),
                  ),
                );
              }),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  onCancel();
                },
                child: const Text('Cancel', style: TextStyle(color: Colors.white38)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Layouts ───────────────────────────────────────────────────────────────────

class _PortraitLayout extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      const PlayerInfoPanel(),
      const TimerBar(),
      const DiceHistoryBar(),
      const SizedBox(height: 4),
      const Expanded(child: Padding(padding: EdgeInsets.all(8), child: BoardWidget())),
      const DiceWidget(),
      const PowerUpBar(),
      const _MessageBanner(),
      const SizedBox(height: 6),
    ]);
  }
}

class _LandscapeLayout extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      const Expanded(
          flex: 5, child: Padding(padding: EdgeInsets.all(8), child: BoardWidget())),
      Expanded(
        flex: 4,
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: const [
          PlayerInfoPanel(),
          TimerBar(),
          DiceHistoryBar(),
          DiceWidget(),
          PowerUpBar(),
          _MessageBanner(),
        ]),
      ),
    ]);
  }
}

// ── Message banner ────────────────────────────────────────────────────────────

class _MessageBanner extends StatelessWidget {
  const _MessageBanner();

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (_, game, __) => AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: Padding(
          key: ValueKey(game.message),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Text(game.message,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
        ),
      ),
    );
  }
}

// ── Cutscene overlay ──────────────────────────────────────────────────────────

class _CutsceneOverlay extends StatelessWidget {
  final GameEvent event;
  final String message;
  const _CutsceneOverlay({required this.event, required this.message});

  String get _emoji {
    switch (event) {
      case GameEvent.snakeBite: return '🐍';
      case GameEvent.ladderClimb: return '🪜';
      case GameEvent.safeZone: return '🛡️';
      case GameEvent.shieldBlocked: return '🛡️';
      case GameEvent.trap: return '🪤';
      case GameEvent.boost: return '🚀';
      case GameEvent.teleport: return '🌀';
      case GameEvent.bonusRoll: return '🎲';
      default: return '✨';
    }
  }

  Color get _color {
    switch (event) {
      case GameEvent.snakeBite: return Colors.red.shade900;
      case GameEvent.ladderClimb: return Colors.green.shade900;
      case GameEvent.safeZone:
      case GameEvent.shieldBlocked: return Colors.blue.shade900;
      case GameEvent.trap: return Colors.brown.shade900;
      case GameEvent.boost: return Colors.cyan.shade900;
      case GameEvent.teleport: return Colors.purple.shade900;
      case GameEvent.bonusRoll: return Colors.amber.shade900;
      default: return Colors.black87;
    }
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 350),
      builder: (_, v, child) => Opacity(opacity: v, child: child),
      child: Align(
        alignment: Alignment.center,
        child: IgnorePointer(
          child: Container(
            margin: const EdgeInsets.all(40),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _color.withValues(alpha: 0.88),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white24, width: 2),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.5, end: 1.0),
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.elasticOut,
                  builder: (_, s, child) => Transform.scale(scale: s, child: child),
                  child: Text(_emoji, style: const TextStyle(fontSize: 72)),
                ),
                const SizedBox(height: 12),
                Text(message,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Dialog button ─────────────────────────────────────────────────────────────

class _DlgBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isPrimary;
  const _DlgBtn({required this.label, required this.onTap, this.isPrimary = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isPrimary ? Colors.amber : Colors.white12,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(label,
            style: TextStyle(
                color: isPrimary ? const Color(0xFF4E2B00) : Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14)),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../colors/widgets/board_widget.dart';
import '../colors/widgets/dice_widget.dart';
import '../colors/widgets/player_info_panel.dart';

class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A2A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        title: const Text(
          '🐍 Snake & Ladder 🪜',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          // Sound toggles
          Consumer<GameProvider>(
            builder: (_, game, __) => Row(
              children: [
                IconButton(
                  icon: Icon(game.musicEnabled ? Icons.music_note : Icons.music_off, size: 20),
                  tooltip: 'Toggle Music',
                  onPressed: game.toggleMusic,
                ),
                IconButton(
                  icon: Icon(game.sfxEnabled ? Icons.volume_up : Icons.volume_off, size: 20),
                  tooltip: 'Toggle SFX',
                  onPressed: game.toggleSFX,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, size: 22),
            tooltip: 'Restart',
            onPressed: () {
              context.read<GameProvider>().resetGame();
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: Consumer<GameProvider>(
        builder: (context, game, _) {
          // Show win dialog when game finishes
          if (game.phase == GamePhase.finished) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (ModalRoute.of(context)?.isCurrent ?? false) {
                _showWinDialog(context, game);
              }
            });
          }

          return LayoutBuilder(
            builder: (ctx, constraints) {
              final isLandscape = constraints.maxWidth > constraints.maxHeight;
              if (isLandscape) {
                return _LandscapeLayout();
              }
              return _PortraitLayout();
            },
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
                  style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Text(game.winner!.avatar, style: const TextStyle(fontSize: 72)),
              const SizedBox(height: 8),
              Text(
                '${game.winner!.name} Wins!',
                style: TextStyle(
                  color: game.winner!.color,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              const Text('🏆 Congratulations! 🏆',
                  style: TextStyle(color: Colors.white60, fontSize: 15)),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _DialogButton(
                    label: '🏠 Menu',
                    onTap: () {
                      Navigator.pop(context);
                      game.resetGame();
                      Navigator.pop(context);
                    },
                  ),
                  _DialogButton(
                    label: '🔄 Play Again',
                    isPrimary: true,
                    onTap: () {
                      Navigator.pop(context);
                      game.resetGame();
                      for (final p in game.players) {
                        p.position = 0;
                      }
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
}

// ── Layouts ───────────────────────────────────────────────────────────────────

class _PortraitLayout extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const PlayerInfoPanel(),
        const TimerBar(),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: const BoardWidget(),
          ),
        ),
        const DiceWidget(),
        const _MessageBanner(),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _LandscapeLayout extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 5,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: const BoardWidget(),
          ),
        ),
        Expanded(
          flex: 4,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              PlayerInfoPanel(),
              TimerBar(),
              DiceWidget(),
              _MessageBanner(),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Message banner ────────────────────────────────────────────────────────────

class _MessageBanner extends StatelessWidget {
  const _MessageBanner();

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, game, _) => AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        child: Padding(
          key: ValueKey(game.message),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Text(
            game.message,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

// ── Win dialog button ─────────────────────────────────────────────────────────

class _DialogButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isPrimary;

  const _DialogButton({
    required this.label,
    required this.onTap,
    this.isPrimary = false,
  });

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
        child: Text(
          label,
          style: TextStyle(
            color: isPrimary ? const Color(0xFF4E2B00) : Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}
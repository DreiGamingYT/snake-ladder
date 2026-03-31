import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../colors/constants/board_data.dart';
import '../providers/game_provider.dart';
import '../services/stats_service.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFF1A2A1A),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1B5E20),
          foregroundColor: Colors.white,
          title: const Text('📊 Statistics', style: TextStyle(fontWeight: FontWeight.bold)),
          actions: [
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              tooltip: 'Clear leaderboard',
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    backgroundColor: const Color(0xFF1B2B1B),
                    title: const Text('Clear Leaderboard?',
                        style: TextStyle(color: Colors.white)),
                    content: const Text('This will delete all saved stats.',
                        style: TextStyle(color: Colors.white60)),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel', style: TextStyle(color: Colors.white38))),
                      TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Clear',
                              style: TextStyle(color: Colors.red))),
                    ],
                  ),
                );
                if (ok == true && context.mounted) {
                  await context.read<GameProvider>().stats.clearAll();
                  if (context.mounted) Navigator.pop(context);
                }
              },
            ),
          ],
          bottom: const TabBar(
            labelColor: Colors.amber,
            unselectedLabelColor: Colors.white54,
            indicatorColor: Colors.amber,
            tabs: [
              Tab(text: '🏆 Leaderboard'),
              Tab(text: '🎮 This Game'),
            ],
          ),
        ),
        body: Consumer<GameProvider>(
          builder: (context, game, _) {
            return TabBarView(
              children: [
                _LeaderboardTab(stats: game.stats),
                _CurrentGameTab(game: game),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ── Leaderboard tab ───────────────────────────────────────────────────────────

class _LeaderboardTab extends StatelessWidget {
  final StatsService stats;
  const _LeaderboardTab({required this.stats});

  @override
  Widget build(BuildContext context) {
    final entries = stats.entries;
    if (entries.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('🏆', style: TextStyle(fontSize: 48)),
            SizedBox(height: 12),
            Text('No games recorded yet.',
                style: TextStyle(color: Colors.white38, fontSize: 15)),
            SizedBox(height: 4),
            Text('Play a game to see stats here!',
                style: TextStyle(color: Colors.white24, fontSize: 13)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: entries.length,
      itemBuilder: (_, i) {
        final e = entries[i];
        final medalEmoji = i == 0 ? '🥇' : i == 1 ? '🥈' : i == 2 ? '🥉' : '▪️';
        final winRate = e.gamesPlayed > 0 ? (e.wins / e.gamesPlayed * 100).round() : 0;
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: i == 0
                ? const Color(0xFFFFD600).withValues(alpha: 0.12)
                : Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: i == 0
                  ? const Color(0xFFFFD600).withValues(alpha: 0.4)
                  : Colors.white12,
              width: i == 0 ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Text(medalEmoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Text(e.avatar, style: const TextStyle(fontSize: 26)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(e.name,
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                    Text(
                      '${e.gamesPlayed} games  •  $winRate% win rate',
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                    Text(
                      '🐍 ${e.snakesHit}  🪜 ${e.laddersClimbed}  👣 ${e.totalMoves} moves',
                      style: const TextStyle(color: Colors.white38, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  Text('${e.wins}',
                      style: const TextStyle(
                          color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 22)),
                  const Text('wins',
                      style: TextStyle(color: Colors.white38, fontSize: 11)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Current game tab ──────────────────────────────────────────────────────────

class _CurrentGameTab extends StatelessWidget {
  final GameProvider game;
  const _CurrentGameTab({required this.game});

  @override
  Widget build(BuildContext context) {
    if (game.players.isEmpty) {
      return const Center(
        child: Text('No active game.',
            style: TextStyle(color: Colors.white38, fontSize: 15)),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Mode badge
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: game.gameMode == GameMode.advanced
                  ? const Color(0xFF7E57C2).withValues(alpha: 0.3)
                  : Colors.green.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: game.gameMode == GameMode.advanced
                      ? Colors.purple.shade300
                      : Colors.green.shade300),
            ),
            child: Text(
              game.gameMode == GameMode.advanced ? '⚡ Advanced Mode' : '🏛️ Classic Mode',
              style: TextStyle(
                  color: game.gameMode == GameMode.advanced
                      ? Colors.purple.shade200
                      : Colors.green.shade300,
                  fontWeight: FontWeight.bold,
                  fontSize: 13),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Player stats cards
        ...game.players.map((p) {
          final isWinner = game.winner == p;
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: p.color.withValues(alpha: isWinner ? 0.22 : 0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: p.color.withValues(alpha: isWinner ? 0.7 : 0.3), width: isWinner ? 2 : 1),
            ),
            child: Row(
              children: [
                Text(p.avatar, style: const TextStyle(fontSize: 30)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Text(p.name,
                            style: const TextStyle(
                                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                        if (isWinner) ...[
                          const SizedBox(width: 6),
                          const Text('🏆', style: TextStyle(fontSize: 16)),
                        ],
                      ]),
                      Text(
                        'Position: ${p.position == 0 ? "Start" : "Square ${p.position}"}',
                        style: TextStyle(color: p.color, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '👣 ${p.totalMoves} moves  •  🐍 ${p.snakesHit} snakes  •  🪜 ${p.laddersClimbed} ladders',
                        style: const TextStyle(color: Colors.white54, fontSize: 11),
                      ),
                      if (p.powerUpsUsed > 0)
                        Text(
                          '⚡ ${p.powerUpsUsed} power-ups used',
                          style: const TextStyle(color: Colors.amber, fontSize: 11),
                        ),
                      if (p.powerUps.isNotEmpty)
                        Text(
                          'Holding: ${p.powerUps.map((pu) => pu.emoji).join(' ')}',
                          style: const TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),

        // Move count
        if (game.moveHistory.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _Stat('Total Turns', '${game.moveHistory.length}', '🎯'),
                _Stat(
                    'Total Snakes',
                    '${game.players.fold(0, (a, b) => a + b.snakesHit)}',
                    '🐍'),
                _Stat(
                    'Total Ladders',
                    '${game.players.fold(0, (a, b) => a + b.laddersClimbed)}',
                    '🪜'),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final String emoji;
  const _Stat(this.label, this.value, this.emoji);

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(emoji, style: const TextStyle(fontSize: 20)),
      Text(value,
          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
      Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10)),
    ]);
  }
}
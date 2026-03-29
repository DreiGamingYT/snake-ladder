import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../colors/constants/board_data.dart';
import '../providers/game_provider.dart';
import 'game_screen.dart';
import 'hotspot_host_setup_screen.dart';
import 'hotspot_join_screen.dart';
import 'hotspot_multiplayer_screen.dart';
import 'stats_screen.dart';
import 'hotspot_multiplayer_screen.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  int _playerCount = 2;
  final List<TextEditingController> _controllers =
  List.generate(6, (i) => TextEditingController(text: 'Player ${i + 1}'));
  final List<int> _avatarIdx = List.generate(6, (i) => i % kAvatarEmojis.length);

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1B5E20), Color(0xFF2E7D32), Color(0xFF1A237E)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Snake & Ladder',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            'Choose classic or hotspot multiplayer',
                            style: TextStyle(color: Colors.white54, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const StatsScreen()),
                        );
                      },
                      icon: const Icon(Icons.leaderboard_outlined, color: Colors.white70),
                      tooltip: 'Leaderboard',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _ModeCard(
                      title: 'Classic',
                      subtitle: 'Pure local game',
                      emoji: '🎲',
                      selected: game.gameMode == GameMode.classic,
                      onTap: () => game.setGameMode(GameMode.classic),
                    ),
                    const SizedBox(width: 10),
                    _ModeCard(
                      title: 'Advanced',
                      subtitle: 'Power-ups and special tiles',
                      emoji: '⚡',
                      selected: game.gameMode == GameMode.advanced,
                      onTap: () => game.setGameMode(GameMode.advanced),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => HotspotHostSetupScreen()),
                          );
                        },
                        child: const Text('Host Game'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => HotspotJoinScreen()),
                          );
                        },
                        child: const Text('Join Game'),
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 250),
                child: game.gameMode == GameMode.advanced
                    ? Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7E57C2).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFFB39DDB).withOpacity(0.4),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Text('⚡', style: TextStyle(fontSize: 20)),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Always Roll Double Dice',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Switch(
                          value: game.doubleDiceMode,
                          onChanged: game.setDoubleDiceMode,
                          activeColor: const Color(0xFFB39DDB),
                        ),
                      ],
                    ),
                  ),
                )
                    : const SizedBox.shrink(),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Players',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(5, (i) {
                          final n = i + 2;
                          final selected = _playerCount == n;
                          return GestureDetector(
                            onTap: () => setState(() => _playerCount = n),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: selected ? Colors.amber : Colors.white12,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: selected
                                    ? [const BoxShadow(color: Color(0x88FFAB00), blurRadius: 8)]
                                    : [],
                              ),
                              child: Center(
                                child: Text(
                                  '$n',
                                  style: TextStyle(
                                    color: selected ? const Color(0xFF4E2B00) : Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  itemCount: _playerCount,
                  itemBuilder: (_, i) => _PlayerCard(
                    index: i,
                    controller: _controllers[i],
                    avatarIndex: _avatarIdx[i],
                    color: kPlayerColors[i],
                    onAvatarTap: () => _pickAvatar(i),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _startGame,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: const Color(0xFF4E2B00),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      elevation: 6,
                      textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    child: Text('Start ${game.gameMode == GameMode.advanced ? 'Advanced' : 'Classic'} Game'),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickAvatar(int index) async {
    final picked = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: const Color(0xFF1B5E20),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Choose Avatar',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(kAvatarEmojis.length, (j) {
                return GestureDetector(
                  onTap: () => Navigator.pop(context, j),
                  child: Container(
                    width: 56,
                    height: 56,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: _avatarIdx[index] == j ? Colors.amber : Colors.white12,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(kAvatarEmojis[j], style: const TextStyle(fontSize: 30)),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );

    if (picked != null) {
      setState(() => _avatarIdx[index] = picked);
    }
  }

  void _startGame() {
    final game = context.read<GameProvider>();

    if (game.gameMode == GameMode.multiplayer) {
      // Multiplayer will handle player init via network
      return;
    }

    game.initPlayers(_playerCount);

    for (int i = 0; i < _playerCount; i++) {
      game.updatePlayer(
        i,
        name: _controllers[i].text.trim().isEmpty ? 'Player ${i + 1}' : _controllers[i].text.trim(),
        avatar: kAvatarEmojis[_avatarIdx[i]],
        color: kPlayerColors[i],
      );
    }

    game.startGame();

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const GameScreen()),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String emoji;
  final bool selected;
  final VoidCallback onTap;

  const _ModeCard({
    required this.title,
    required this.subtitle,
    required this.emoji,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected ? Colors.white.withOpacity(0.18) : Colors.white.withOpacity(0.07),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? Colors.amber : Colors.white24,
              width: selected ? 2 : 1,
            ),
            boxShadow: selected ? [const BoxShadow(color: Color(0x55FFD600), blurRadius: 12)] : [],
          ),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(height: 6),
              Text(
                title,
                style: TextStyle(
                  color: selected ? Colors.amber : Colors.white70,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                subtitle,
                style: const TextStyle(color: Colors.white38, fontSize: 11),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlayerCard extends StatelessWidget {
  final int index;
  final TextEditingController controller;
  final int avatarIndex;
  final Color color;
  final VoidCallback onAvatarTap;

  const _PlayerCard({
    required this.index,
    required this.controller,
    required this.avatarIndex,
    required this.color,
    required this.onAvatarTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.5), width: 1.5),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onAvatarTap,
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: color, width: 2),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Text(kAvatarEmojis[avatarIndex], style: const TextStyle(fontSize: 26)),
                  Positioned(
                    bottom: 2,
                    right: 2,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      child: const Icon(Icons.edit, size: 10, color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                labelText: 'Player ${index + 1}',
                labelStyle: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: color.withOpacity(0.6))),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: color, width: 2)),
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(width: 14, height: 14, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        ],
      ),
    );
  }
}

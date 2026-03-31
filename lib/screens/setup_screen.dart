import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../colors/constants/board_data.dart';
import 'game_screen.dart';
import 'stats_screen.dart';
import 'hotspot_multiplayer_screen.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});
  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  int _count = 2;
  final List<TextEditingController> _controllers =
  List.generate(6, (i) => TextEditingController(text: 'Player ${i + 1}'));
  final List<int> _avatarIdx = List.generate(6, (i) => i % kAvatarEmojis.length);

  @override
  void dispose() {
    for (final c in _controllers) c.dispose();
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
              // ── Header ───────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('🐍 Snake & Ladder 🪜',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900)),
                          Text('Choose your game mode',
                              style: TextStyle(color: Colors.white54, fontSize: 13)),
                        ],
                      ),
                    ),
                    // Multiplayer button
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                      child: SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white30, width: 1.5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          icon: const Text('📡', style: TextStyle(fontSize: 18)),
                          label: const Text('Hotspot Multiplayer',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const HotspotMultiplayerScreen()),
                          ),
                        ),
                      ),
                    ),
                    // Stats button
                    IconButton(
                      onPressed: () => Navigator.push(
                          context, MaterialPageRoute(builder: (_) => const StatsScreen())),
                      icon: const Icon(Icons.leaderboard_outlined, color: Colors.white70),
                      tooltip: 'Leaderboard',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Game mode selector ───────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _ModeCard(
                      title: 'Classic',
                      subtitle: 'Pure snake & ladder',
                      emoji: '🏛️',
                      selected: game.gameMode == GameMode.classic,
                      onTap: () => game.setGameMode(GameMode.classic),
                    ),
                    const SizedBox(width: 10),
                    _ModeCard(
                      title: 'Advanced',
                      subtitle: 'Power-ups & special tiles',
                      emoji: '⚡',
                      selected: game.gameMode == GameMode.advanced,
                      onTap: () => game.setGameMode(GameMode.advanced),
                    ),
                  ],
                ),
              ),

              // ── Advanced options ─────────────────────────────
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                child: game.gameMode == GameMode.advanced
                    ? Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7E57C2).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: const Color(0xFFB39DDB).withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        const Text('🎲🎲', style: TextStyle(fontSize: 20)),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text('Always Roll Double Dice',
                              style: TextStyle(color: Colors.white, fontSize: 13,fontWeight: FontWeight.w600)),
                        ),
                        Switch(
                          value: game.doubleDiceMode,
                          onChanged: game.setDoubleDiceMode,
                          activeThumbColor: const Color(0xFFB39DDB),
                        ),
                      ],
                    ),
                  ),
                )
                    : const SizedBox.shrink(),
              ),

              const SizedBox(height: 12),

              // ── Player count ─────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Players',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(5, (i) {
                          final n = i + 2;
                          final sel = _count == n;
                          return GestureDetector(
                            onTap: () => setState(() => _count = n),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: sel ? Colors.amber : Colors.white12,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: sel
                                    ? [const BoxShadow(
                                    color: Color(0x88FFAB00), blurRadius: 8)]
                                    : [],
                              ),
                              child: Center(
                                child: Text('$n',
                                    style: TextStyle(
                                        color: sel
                                            ? const Color(0xFF4E2B00)
                                            : Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20)),
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

              // ── Player cards ─────────────────────────────────
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  itemCount: _count,
                  itemBuilder: (_, i) => _PlayerCard(
                    index: i,
                    controller: _controllers[i],
                    avatarIndex: _avatarIdx[i],
                    color: kPlayerColors[i],
                    onAvatarTap: () => _pickAvatar(i),
                  ),
                ),
              ),

              // ── Start button ─────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: const Color(0xFF4E2B00),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18)),
                      elevation: 6,
                      textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    onPressed: _startGame,
                    child: Text(
                      '🎲  Start ${game.gameMode == GameMode.advanced ? "Advanced" : "Classic"} Game!',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _pickAvatar(int i) async {
    final picked = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: const Color(0xFF1B5E20),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Choose Avatar',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(kAvatarEmojis.length, (j) {
                final sel = _avatarIdx[i] == j;
                return GestureDetector(
                  onTap: () => Navigator.pop(context, j),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: sel ? Colors.amber : Colors.white12,
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
    if (picked != null) setState(() => _avatarIdx[i] = picked);
  }

  void _startGame() {
    final game = context.read<GameProvider>();
    game.initPlayers(_count);
    for (int i = 0; i < _count; i++) {
      game.updatePlayer(i,
          name: _controllers[i].text.trim().isEmpty
              ? 'Player ${i + 1}'
              : _controllers[i].text.trim(),
          avatar: kAvatarEmojis[_avatarIdx[i]],
          color: kPlayerColors[i]);
    }
    game.startGame();
    Navigator.push(context, MaterialPageRoute(builder: (_) => const GameScreen()));
  }
}

// ── Mode card ─────────────────────────────────────────────────────────────────

class _ModeCard extends StatelessWidget {
  final String title, subtitle, emoji;
  final bool selected;
  final VoidCallback onTap;
  const _ModeCard({
    required this.title, required this.subtitle,
    required this.emoji, required this.selected, required this.onTap,
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
            color: selected ? Colors.white.withValues(alpha: 0.18) : Colors.white.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? Colors.amber : Colors.white24,
              width: selected ? 2 : 1,
            ),
            boxShadow: selected
                ? [const BoxShadow(color: Color(0x55FFD600), blurRadius: 12)]
                : [],
          ),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(height: 6),
              Text(title,
                  style: TextStyle(
                    color: selected ? Colors.amber : Colors.white70,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  )),
              Text(subtitle,
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Player card ───────────────────────────────────────────────────────────────

class _PlayerCard extends StatelessWidget {
  final int index;
  final TextEditingController controller;
  final int avatarIndex;
  final Color color;
  final VoidCallback onAvatarTap;

  const _PlayerCard({
    required this.index, required this.controller,
    required this.avatarIndex, required this.color, required this.onAvatarTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1.5),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onAvatarTap,
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: color, width: 2),
              ),
              child: Stack(alignment: Alignment.center, children: [
                Text(kAvatarEmojis[avatarIndex], style: const TextStyle(fontSize: 26)),
                Positioned(
                  bottom: 2,
                  right: 2,
                  child: Container(
                    width: 16, height: 16,
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: const Icon(Icons.edit, size: 10, color: Colors.grey),
                  ),
                ),
              ]),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                labelText: 'Player ${index + 1}',
                labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: color.withValues(alpha: 0.6))),
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
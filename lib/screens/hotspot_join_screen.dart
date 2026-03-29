import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/hotspot_player.dart';
import '../models/hotspot_room_discovery.dart';
import '../providers/hotspot_multiplayer_provider.dart';
import 'hotspot_lobby_screen.dart';

class HotspotJoinScreen extends StatefulWidget {
  const HotspotJoinScreen({super.key});

  @override
  State<HotspotJoinScreen> createState() => _HotspotJoinScreenState();
}

class _HotspotJoinScreenState extends State<HotspotJoinScreen> {
  final TextEditingController _playerNameController = TextEditingController(text: 'Player 2');

  @override
  void dispose() {
    _playerNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HotspotMultiplayerProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Join Room')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _playerNameController,
              decoration: const InputDecoration(labelText: 'Your name'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    icon: const Icon(Icons.radar),
                    label: Text(provider.isScanning ? 'Scanning...' : 'Scan Rooms'),
                    onPressed: provider.isScanning
                        ? null
                        : () async {
                            await provider.scanRooms();
                          },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: provider.rooms.isEmpty
                  ? const Center(child: Text('No rooms found yet.'))
                  : ListView.separated(
                      itemCount: provider.rooms.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final room = provider.rooms[index];
                        return _RoomCard(
                          room: room,
                          onJoin: () async {
                            final playerName = _playerNameController.text.trim().isEmpty
                                ? 'Player 2'
                                : _playerNameController.text.trim();
                            await provider.joinRoom(
                              room: room,
                              player: HotspotPlayer(
                                id: DateTime.now().millisecondsSinceEpoch.toString(),
                                name: playerName,
                                colorValue: 0xFF2E7D32,
                                isHost: false,
                                ready: false,
                              ),
                            );
                            if (!context.mounted) return;
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (_) => const HotspotLobbyScreen(isHost: false)),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoomCard extends StatelessWidget {
  final HotspotRoomDiscovery room;
  final VoidCallback onJoin;

  const _RoomCard({required this.room, required this.onJoin});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(room.roomName),
        subtitle: Text('${room.hostName} • ${room.currentPlayers}/${room.maxPlayers} players • ${room.turnSeconds}s turn'),
        trailing: FilledButton(
          onPressed: onJoin,
          child: const Text('Join'),
        ),
      ),
    );
  }
}

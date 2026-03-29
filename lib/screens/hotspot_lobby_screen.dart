import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/hotspot_multiplayer_provider.dart';

class HotspotLobbyScreen extends StatelessWidget {
  final bool isHost;

  const HotspotLobbyScreen({super.key, required this.isHost});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HotspotMultiplayerProvider>();
    final room = provider.isHosting ? provider.rooms.isNotEmpty ? provider.rooms.first : null : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lobby'),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () async {
              await provider.stopSession();
              if (context.mounted) Navigator.pop(context);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isHost)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Hosting: ${provider.draftConfig.roomName}', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Text('Players: ${provider.draftConfig.maxPlayers}'),
                      Text('Turn timer: ${provider.draftConfig.turnSeconds}s'),
                      Text('Bonus tiles: ${provider.draftConfig.bonusTiles}'),
                      Text('Advanced mode: ${provider.draftConfig.advancedMode ? 'On' : 'Off'}'),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 12),
            Text(provider.status ?? 'Waiting for players...'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () async {
                await provider.broadcastHostMessage({'type': 'start_game'});
              },
              child: const Text('Start Game'),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: room == null
                  ? const Center(child: Text('Lobby status will appear here.'))
                  : const Center(child: Text('Connected.')), 
            ),
          ],
        ),
      ),
    );
  }
}

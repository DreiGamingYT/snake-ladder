import 'package:flutter/material.dart';

import 'hotspot_host_setup_screen.dart';
import 'hotspot_join_screen.dart';

class HotspotMultiplayerScreen extends StatelessWidget {
  const HotspotMultiplayerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hotspot Multiplayer')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 12),
            const Text(
              'Host shares mobile hotspot. Other players scan the room name and join locally.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              icon: const Icon(Icons.wifi_tethering),
              label: const Text('Create Host Room'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HotspotHostSetupScreen()),
                );
              },
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.radar),
              label: const Text('Join Room'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HotspotJoinScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

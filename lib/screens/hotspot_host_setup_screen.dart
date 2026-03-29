import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/hotspot_multiplayer_provider.dart';
import 'hotspot_lobby_screen.dart';

class HotspotHostSetupScreen extends StatefulWidget {
  const HotspotHostSetupScreen({super.key});

  @override
  State<HotspotHostSetupScreen> createState() => _HotspotHostSetupScreenState();
}

class _HotspotHostSetupScreenState extends State<HotspotHostSetupScreen> {
  late final TextEditingController _roomNameController;
  late final TextEditingController _hostNameController;
  late final TextEditingController _playersController;
  late final TextEditingController _turnSecondsController;
  late final TextEditingController _bonusTilesController;
  late final TextEditingController _snakePenaltyController;
  late final TextEditingController _ladderBonusController;
  bool _advancedMode = true;

  @override
  void initState() {
    super.initState();
    final draft = context.read<HotspotMultiplayerProvider>().draftConfig;
    _roomNameController = TextEditingController(text: draft.roomName);
    _hostNameController = TextEditingController(text: 'Host');
    _playersController = TextEditingController(text: draft.maxPlayers.toString());
    _turnSecondsController = TextEditingController(text: draft.turnSeconds.toString());
    _bonusTilesController = TextEditingController(text: draft.bonusTiles.toString());
    _snakePenaltyController = TextEditingController(text: draft.snakePenalty.toString());
    _ladderBonusController = TextEditingController(text: draft.ladderBonus.toString());
    _advancedMode = draft.advancedMode;
  }

  @override
  void dispose() {
    _roomNameController.dispose();
    _hostNameController.dispose();
    _playersController.dispose();
    _turnSecondsController.dispose();
    _bonusTilesController.dispose();
    _snakePenaltyController.dispose();
    _ladderBonusController.dispose();
    super.dispose();
  }

  int _parseInt(TextEditingController controller, int fallback) {
    return int.tryParse(controller.text.trim()) ?? fallback;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HotspotMultiplayerProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Host Setup')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(
            controller: _hostNameController,
            decoration: const InputDecoration(labelText: 'Host name'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _roomNameController,
            decoration: const InputDecoration(labelText: 'Room name'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _playersController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Number of players'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _turnSecondsController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Turn timer (seconds)'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _bonusTilesController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Bonus tiles'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _snakePenaltyController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Snake penalty'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _ladderBonusController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Ladder bonus'),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Advanced mode'),
            subtitle: const Text('Enable bonus tiles and special rules'),
            value: _advancedMode,
            onChanged: (value) => setState(() => _advancedMode = value),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: provider.isHosting
                ? null
                : () async {
                    provider.updateDraft(
                      roomName: _roomNameController.text.trim(),
                      maxPlayers: _parseInt(_playersController, 4),
                      turnSeconds: _parseInt(_turnSecondsController, 20),
                      bonusTiles: _parseInt(_bonusTilesController, 4),
                      snakePenalty: _parseInt(_snakePenaltyController, 1),
                      ladderBonus: _parseInt(_ladderBonusController, 1),
                      advancedMode: _advancedMode,
                    );
                    await provider.startHosting(hostName: _hostNameController.text.trim().isEmpty
                        ? 'Host'
                        : _hostNameController.text.trim());
                    if (!context.mounted) return;
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const HotspotLobbyScreen(isHost: true)),
                    );
                  },
            child: const Text('Create Room'),
          ),
          const SizedBox(height: 12),
          if (provider.status != null)
            Text(
              provider.status!,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
        ],
      ),
    );
  }
}

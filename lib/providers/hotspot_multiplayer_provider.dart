import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/hotspot_player.dart';
import '../models/hotspot_room_config.dart';
import '../models/hotspot_room_discovery.dart';
import '../services/hotspot_multiplayer_service.dart';
import '../services/hotspot_multiplayer_service_io.dart'
    if (dart.library.html) '../services/hotspot_multiplayer_service_stub.dart';

class HotspotMultiplayerProvider extends ChangeNotifier {
  final HotspotMultiplayerService _service;

  HotspotMultiplayerProvider({HotspotMultiplayerService? service})
      : _service = service ?? HotspotMultiplayerServiceIo();

  HotspotRoomConfig _draftConfig = HotspotRoomConfig.defaults();
  HotspotRoomConfig get draftConfig => _draftConfig;

  List<HotspotRoomDiscovery> _rooms = [];
  List<HotspotRoomDiscovery> get rooms => _rooms;

  bool _isScanning = false;
  bool get isScanning => _isScanning;

  bool _isHosting = false;
  bool get isHosting => _isHosting;

  bool _isJoined = false;
  bool get isJoined => _isJoined;

  HostSession? _hostSession;
  ClientSession? _clientSession;
  StreamSubscription? _hostMessageSub;
  StreamSubscription? _clientMessageSub;

  String? _status;
  String? get status => _status;

  void updateDraft({
    String? roomName,
    int? maxPlayers,
    int? turnSeconds,
    int? bonusTiles,
    int? snakePenalty,
    int? ladderBonus,
    bool? advancedMode,
  }) {
    _draftConfig = _draftConfig.copyWith(
      roomName: roomName,
      maxPlayers: maxPlayers,
      turnSeconds: turnSeconds,
      bonusTiles: bonusTiles,
      snakePenalty: snakePenalty,
      ladderBonus: ladderBonus,
      advancedMode: advancedMode,
    );
    notifyListeners();
  }

  Future<void> scanRooms() async {
    _isScanning = true;
    _status = 'Scanning for rooms...';
    _rooms = [];
    notifyListeners();

    final collected = <HotspotRoomDiscovery>[];
    await for (final rooms in _service.scanRooms(timeout: const Duration(seconds: 5))) {
      collected
        ..clear()
        ..addAll(rooms);
      _rooms = List<HotspotRoomDiscovery>.from(collected);
      notifyListeners();
    }

    _isScanning = false;
    _status = _rooms.isEmpty ? 'No rooms found.' : 'Scan complete.';
    notifyListeners();
  }

  Future<void> startHosting({required String hostName}) async {
    await stopSession();
    _isHosting = true;
    _status = 'Starting host room...';
    notifyListeners();

    _hostSession = await _service.startHosting(hostName: hostName, config: _draftConfig);
    _hostMessageSub = _hostSession!.messages.listen((message) {
      if (message['type'] == 'join') {
        _status = '${message['player']?['name'] ?? 'Player'} joined the room.';
        notifyListeners();
      }
    });

    _status = 'Hosting ${_hostSession!.discovery.roomName}';
    notifyListeners();
  }

  Future<void> joinRoom({
    required HotspotRoomDiscovery room,
    required HotspotPlayer player,
  }) async {
    await stopSession();
    _status = 'Joining room...';
    notifyListeners();

    _clientSession = await _service.joinRoom(room: room, player: player);
    _clientMessageSub = _clientSession!.messages.listen((message) {
      _status = 'Received: ${message['type'] ?? 'message'}';
      notifyListeners();
    });
    _isJoined = true;
    _status = 'Connected to ${room.roomName}';
    notifyListeners();
  }

  Future<void> sendClientMessage(Map<String, dynamic> message) async {
    await _clientSession?.send(message);
  }

  Future<void> broadcastHostMessage(Map<String, dynamic> message) async {
    await _hostSession?.broadcast(message);
  }

  Future<void> stopSession() async {
    await _hostMessageSub?.cancel();
    await _clientMessageSub?.cancel();
    _hostMessageSub = null;
    _clientMessageSub = null;

    await _hostSession?.stop();
    await _clientSession?.disconnect();

    _hostSession = null;
    _clientSession = null;
    _isHosting = false;
    _isJoined = false;
    _status = 'Disconnected.';
    notifyListeners();
  }

  @override
  void dispose() {
    stopSession();
    super.dispose();
  }
}

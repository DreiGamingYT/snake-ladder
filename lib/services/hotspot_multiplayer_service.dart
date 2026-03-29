import '../models/hotspot_player.dart';
import '../models/hotspot_room_config.dart';
import '../models/hotspot_room_discovery.dart';

abstract class HotspotMultiplayerService {
  Stream<List<HotspotRoomDiscovery>> scanRooms({Duration timeout = const Duration(seconds: 5)});

  Future<HostSession> startHosting({
    required String hostName,
    required HotspotRoomConfig config,
    int udpPort,
    int tcpPort,
  });

  Future<ClientSession> joinRoom({
    required HotspotRoomDiscovery room,
    required HotspotPlayer player,
  });
}

class HostSession {
  final String roomId;
  final HotspotRoomDiscovery discovery;
  final Stream<HotspotPlayer> joinedPlayers;
  final Stream<Map<String, dynamic>> messages;
  final Future<void> Function() stop;
  final Future<void> Function(Map<String, dynamic> message) broadcast;

  HostSession({
    required this.roomId,
    required this.discovery,
    required this.joinedPlayers,
    required this.messages,
    required this.stop,
    required this.broadcast,
  });
}

class ClientSession {
  final HotspotRoomDiscovery room;
  final Stream<Map<String, dynamic>> messages;
  final Future<void> Function(Map<String, dynamic> message) send;
  final Future<void> Function() disconnect;

  ClientSession({
    required this.room,
    required this.messages,
    required this.send,
    required this.disconnect,
  });
}

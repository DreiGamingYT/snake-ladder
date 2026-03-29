import '../models/hotspot_player.dart';
import '../models/hotspot_room_config.dart';
import '../models/hotspot_room_discovery.dart';
import 'hotspot_multiplayer_service.dart';

class HotspotMultiplayerServiceStub implements HotspotMultiplayerService {
  @override
  Stream<List<HotspotRoomDiscovery>> scanRooms({Duration timeout = const Duration(seconds: 5)}) async* {
    yield <HotspotRoomDiscovery>[];
  }

  @override
  Future<HostSession> startHosting({
    required String hostName,
    required HotspotRoomConfig config,
    int udpPort = 4040,
    int tcpPort = 4041,
  }) async {
    throw UnsupportedError('Hotspot multiplayer is not supported on this platform.');
  }

  @override
  Future<ClientSession> joinRoom({
    required HotspotRoomDiscovery room,
    required HotspotPlayer player,
  }) async {
    throw UnsupportedError('Hotspot multiplayer is not supported on this platform.');
  }
}

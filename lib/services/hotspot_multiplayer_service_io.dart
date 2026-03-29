import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import '../models/hotspot_player.dart';
import '../models/hotspot_room_config.dart';
import '../models/hotspot_room_discovery.dart';
import 'hotspot_multiplayer_service.dart';

class HotspotMultiplayerServiceIo implements HotspotMultiplayerService {
  static const int discoveryPort = 4040;
  static const int tcpPortDefault = 4041;
  static const String discoveryAddress = '255.255.255.255';

  final Random _random = Random();

  @override
  Stream<List<HotspotRoomDiscovery>> scanRooms({Duration timeout = const Duration(seconds: 5)}) async* {
    final socket = await RawDatagramSocket.bind(
      InternetAddress.anyIPv4,
      discoveryPort,
      reuseAddress: true,
      reusePort: true,
    );

    final rooms = <String, HotspotRoomDiscovery>{};
    final controller = StreamController<List<HotspotRoomDiscovery>>();

    socket.listen((event) {
      if (event == RawSocketEvent.read) {
        final datagram = socket.receive();
        if (datagram == null) return;
        try {
          final text = utf8.decode(datagram.data);
          final room = HotspotRoomDiscovery.decode(text);
          rooms['${room.hostIp}:${room.tcpPort}'] = room;
          controller.add(rooms.values.toList()
            ..sort((a, b) => a.roomName.toLowerCase().compareTo(b.roomName.toLowerCase())));
        } catch (_) {
          // Ignore malformed packets.
        }
      }
    });

    final timer = Timer(timeout, () async {
      await controller.close();
      socket.close();
    });

    try {
      yield* controller.stream;
    } finally {
      timer.cancel();
      await controller.close();
      socket.close();
    }
  }

  @override
  Future<HostSession> startHosting({
    required String hostName,
    required HotspotRoomConfig config,
    int udpPort = discoveryPort,
    int tcpPort = tcpPortDefault,
  }) async {
    final roomId = '${DateTime.now().millisecondsSinceEpoch}-${_random.nextInt(99999)}';
    final hostIp = await _getLocalIp() ?? '192.168.43.1';
    final discovery = HotspotRoomDiscovery.fromConfig(
      roomId: roomId,
      hostName: hostName,
      hostIp: hostIp,
      tcpPort: tcpPort,
      udpPort: udpPort,
      config: config,
      currentPlayers: 1,
    );

    final udpSocket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    udpSocket.broadcastEnabled = true;

    final tcpServer = await ServerSocket.bind(InternetAddress.anyIPv4, tcpPort, shared: true);
    final joinedPlayersController = StreamController<HotspotPlayer>.broadcast();
    final hostMessagesController = StreamController<Map<String, dynamic>>.broadcast();
    final clients = <Socket>[];
    var stopped = false;

    void broadcastRoom() {
      final data = utf8.encode(discovery.encode());
      udpSocket.send(data, InternetAddress(discoveryAddress), udpPort);
    }

    final broadcastTimer = Timer.periodic(const Duration(seconds: 1), (_) => broadcastRoom());
    broadcastRoom();

    tcpServer.listen((socket) {
      clients.add(socket);
      socket
          .cast<List<int>>() // 🔥 Fix type issue
          .transform(utf8.decoder)
          .transform(const LineSplitter()).listen((line) {
        try {
          final message = jsonDecode(line) as Map<String, dynamic>;
          hostMessagesController.add(message);
          if (message['type'] == 'join') {
            final player = HotspotPlayer.fromJson((message['player'] as Map).cast<String, dynamic>());
            joinedPlayersController.add(player);
          }
        } catch (_) {
          // Ignore.
        }
      }, onDone: () {
        clients.remove(socket);
      });
    });

    Future<void> stop() async {
      if (stopped) return;
      stopped = true;
      broadcastTimer.cancel();
      udpSocket.close();
      await tcpServer.close();
      for (final socket in clients) {
        socket.destroy();
      }
      await joinedPlayersController.close();
      await hostMessagesController.close();
    }

    Future<void> broadcast(Map<String, dynamic> message) async {
      final encoded = '${jsonEncode(message)}\n';
      for (final socket in List<Socket>.from(clients)) {
        socket.write(encoded);
      }
    }

    return HostSession(
      roomId: roomId,
      discovery: discovery,
      joinedPlayers: joinedPlayersController.stream,
      messages: hostMessagesController.stream,
      stop: stop,
      broadcast: broadcast,
    );
  }

  @override
  Future<ClientSession> joinRoom({
    required HotspotRoomDiscovery room,
    required HotspotPlayer player,
  }) async {
    final socket = await Socket.connect(room.hostIp, room.tcpPort, timeout: const Duration(seconds: 5));
    final controller = StreamController<Map<String, dynamic>>.broadcast();

    socket
        .cast<List<int>>() // 🔥 Fix type issue
        .transform(utf8.decoder)
        .transform(const LineSplitter()).listen((line) {
      try {
        controller.add(jsonDecode(line) as Map<String, dynamic>);
      } catch (_) {
        // Ignore.
      }
    }, onDone: () async {
      await controller.close();
    });

    Future<void> send(Map<String, dynamic> message) async {
      socket.write('${jsonEncode(message)}\n');
    }

    Future<void> disconnect() async {
      socket.destroy();
      await controller.close();
    }

    await send({
      'type': 'join',
      'player': player.toJson(),
      'clientTime': DateTime.now().toIso8601String(),
    });

    return ClientSession(
      room: room,
      messages: controller.stream,
      send: send,
      disconnect: disconnect,
    );
  }

  Future<String?> _getLocalIp() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLinkLocal: false,
      );

      for (final iface in interfaces) {
        for (final addr in iface.addresses) {
          final ip = addr.address;
          if (!ip.startsWith('127.') && !ip.startsWith('169.254.')) {
            return ip;
          }
        }
      }
    } catch (_) {
      // Ignore.
    }
    return null;
  }
}

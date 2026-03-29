import 'dart:convert';

import 'hotspot_room_config.dart';

class HotspotRoomDiscovery {
  final String roomId;
  final String roomName;
  final String hostName;
  final String hostIp;
  final int tcpPort;
  final int udpPort;
  final int currentPlayers;
  final int maxPlayers;
  final int turnSeconds;
  final bool advancedMode;
  final DateTime createdAt;

  const HotspotRoomDiscovery({
    required this.roomId,
    required this.roomName,
    required this.hostName,
    required this.hostIp,
    required this.tcpPort,
    required this.udpPort,
    required this.currentPlayers,
    required this.maxPlayers,
    required this.turnSeconds,
    required this.advancedMode,
    required this.createdAt,
  });

  factory HotspotRoomDiscovery.fromConfig({
    required String roomId,
    required String hostName,
    required String hostIp,
    required int tcpPort,
    required int udpPort,
    required HotspotRoomConfig config,
    int currentPlayers = 1,
  }) {
    return HotspotRoomDiscovery(
      roomId: roomId,
      roomName: config.roomName,
      hostName: hostName,
      hostIp: hostIp,
      tcpPort: tcpPort,
      udpPort: udpPort,
      currentPlayers: currentPlayers,
      maxPlayers: config.maxPlayers,
      turnSeconds: config.turnSeconds,
      advancedMode: config.advancedMode,
      createdAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'roomId': roomId,
        'roomName': roomName,
        'hostName': hostName,
        'hostIp': hostIp,
        'tcpPort': tcpPort,
        'udpPort': udpPort,
        'currentPlayers': currentPlayers,
        'maxPlayers': maxPlayers,
        'turnSeconds': turnSeconds,
        'advancedMode': advancedMode,
        'createdAt': createdAt.toIso8601String(),
      };

  factory HotspotRoomDiscovery.fromJson(Map<String, dynamic> json) {
    return HotspotRoomDiscovery(
      roomId: (json['roomId'] ?? '').toString(),
      roomName: (json['roomName'] ?? '').toString(),
      hostName: (json['hostName'] ?? '').toString(),
      hostIp: (json['hostIp'] ?? '').toString(),
      tcpPort: (json['tcpPort'] ?? 4041) as int,
      udpPort: (json['udpPort'] ?? 4040) as int,
      currentPlayers: (json['currentPlayers'] ?? 1) as int,
      maxPlayers: (json['maxPlayers'] ?? 4) as int,
      turnSeconds: (json['turnSeconds'] ?? 20) as int,
      advancedMode: (json['advancedMode'] ?? true) as bool,
      createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()) ?? DateTime.now(),
    );
  }

  String encode() => jsonEncode(toJson());

  factory HotspotRoomDiscovery.decode(String source) {
    return HotspotRoomDiscovery.fromJson(jsonDecode(source) as Map<String, dynamic>);
  }
}

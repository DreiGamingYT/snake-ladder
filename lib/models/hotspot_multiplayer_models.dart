import 'dart:convert';

import 'package:flutter/material.dart';

class HotspotRoomConfig {
  final String roomName;
  final String hostName;
  final int maxPlayers;
  final int turnSeconds;
  final int bonusTiles;
  final int snakes;
  final int ladders;
  final bool advancedMode;
  final bool doubleDiceMode;

  const HotspotRoomConfig({
    required this.roomName,
    required this.hostName,
    required this.maxPlayers,
    required this.turnSeconds,
    required this.bonusTiles,
    required this.snakes,
    required this.ladders,
    required this.advancedMode,
    required this.doubleDiceMode,
  });

  Map<String, dynamic> toJson() => {
        'roomName': roomName,
        'hostName': hostName,
        'maxPlayers': maxPlayers,
        'turnSeconds': turnSeconds,
        'bonusTiles': bonusTiles,
        'snakes': snakes,
        'ladders': ladders,
        'advancedMode': advancedMode,
        'doubleDiceMode': doubleDiceMode,
      };

  factory HotspotRoomConfig.fromJson(Map<String, dynamic> json) {
    return HotspotRoomConfig(
      roomName: json['roomName']?.toString() ?? 'Snake & Ladder',
      hostName: json['hostName']?.toString() ?? 'Host',
      maxPlayers: (json['maxPlayers'] as num?)?.toInt() ?? 2,
      turnSeconds: (json['turnSeconds'] as num?)?.toInt() ?? 30,
      bonusTiles: (json['bonusTiles'] as num?)?.toInt() ?? 0,
      snakes: (json['snakes'] as num?)?.toInt() ?? 0,
      ladders: (json['ladders'] as num?)?.toInt() ?? 0,
      advancedMode: json['advancedMode'] == true,
      doubleDiceMode: json['doubleDiceMode'] == true,
    );
  }

  factory HotspotRoomConfig.fromEncoded(String value) =>
      HotspotRoomConfig.fromJson(jsonDecode(value) as Map<String, dynamic>);
}

class HotspotPeer {
  final String id;
  final String name;
  final String avatar;
  final int colorValue;
  final bool isHost;
  final bool ready;

  const HotspotPeer({
    required this.id,
    required this.name,
    required this.avatar,
    required this.colorValue,
    required this.isHost,
    required this.ready,
  });

  Color get color => Color(colorValue);

  HotspotPeer copyWith({
    String? id,
    String? name,
    String? avatar,
    int? colorValue,
    bool? isHost,
    bool? ready,
  }) {
    return HotspotPeer(
      id: id ?? this.id,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      colorValue: colorValue ?? this.colorValue,
      isHost: isHost ?? this.isHost,
      ready: ready ?? this.ready,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'avatar': avatar,
        'colorValue': colorValue,
        'isHost': isHost,
        'ready': ready,
      };

  factory HotspotPeer.fromJson(Map<String, dynamic> json) {
    return HotspotPeer(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Player',
      avatar: json['avatar']?.toString() ?? '🙂',
      colorValue: (json['colorValue'] as num?)?.toInt() ?? Colors.amber.value,
      isHost: json['isHost'] == true,
      ready: json['ready'] == true,
    );
  }
}

class HotspotDiscoveredRoom {
  final String roomId;
  final String roomName;
  final String hostName;
  final String hostIp;
  final int port;
  final int playerCount;
  final HotspotRoomConfig config;
  final DateTime lastSeen;

  const HotspotDiscoveredRoom({
    required this.roomId,
    required this.roomName,
    required this.hostName,
    required this.hostIp,
    required this.port,
    required this.playerCount,
    required this.config,
    required this.lastSeen,
  });

  HotspotDiscoveredRoom copyWith({
    String? roomId,
    String? roomName,
    String? hostName,
    String? hostIp,
    int? port,
    int? playerCount,
    HotspotRoomConfig? config,
    DateTime? lastSeen,
  }) {
    return HotspotDiscoveredRoom(
      roomId: roomId ?? this.roomId,
      roomName: roomName ?? this.roomName,
      hostName: hostName ?? this.hostName,
      hostIp: hostIp ?? this.hostIp,
      port: port ?? this.port,
      playerCount: playerCount ?? this.playerCount,
      config: config ?? this.config,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }

  Map<String, dynamic> toJson() => {
        'roomId': roomId,
        'roomName': roomName,
        'hostName': hostName,
        'hostIp': hostIp,
        'port': port,
        'playerCount': playerCount,
        'config': config.toJson(),
        'lastSeen': lastSeen.toIso8601String(),
      };

  factory HotspotDiscoveredRoom.fromJson(Map<String, dynamic> json) {
    return HotspotDiscoveredRoom(
      roomId: json['roomId']?.toString() ?? '',
      roomName: json['roomName']?.toString() ?? 'Snake & Ladder',
      hostName: json['hostName']?.toString() ?? 'Host',
      hostIp: json['hostIp']?.toString() ?? '',
      port: (json['port'] as num?)?.toInt() ?? 40440,
      playerCount: (json['playerCount'] as num?)?.toInt() ?? 1,
      config: HotspotRoomConfig.fromJson(
        (json['config'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
      lastSeen: DateTime.tryParse(json['lastSeen']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  factory HotspotDiscoveredRoom.fromBeacon(String hostIp, Map<String, dynamic> json) {
    final config = HotspotRoomConfig.fromJson(
      (json['config'] as Map?)?.cast<String, dynamic>() ?? const {},
    );
    return HotspotDiscoveredRoom(
      roomId: '${hostIp}:${json['port'] ?? 40440}',
      roomName: json['roomName']?.toString() ?? config.roomName,
      hostName: json['hostName']?.toString() ?? config.hostName,
      hostIp: hostIp,
      port: (json['port'] as num?)?.toInt() ?? 40440,
      playerCount: (json['playerCount'] as num?)?.toInt() ?? 1,
      config: config,
      lastSeen: DateTime.now(),
    );
  }
}

class HotspotLobbyState {
  final bool isHost;
  final bool connected;
  final String statusMessage;
  final HotspotRoomConfig config;
  final List<HotspotPeer> peers;

  const HotspotLobbyState({
    required this.isHost,
    required this.connected,
    required this.statusMessage,
    required this.config,
    required this.peers,
  });

  HotspotLobbyState copyWith({
    bool? isHost,
    bool? connected,
    String? statusMessage,
    HotspotRoomConfig? config,
    List<HotspotPeer>? peers,
  }) {
    return HotspotLobbyState(
      isHost: isHost ?? this.isHost,
      connected: connected ?? this.connected,
      statusMessage: statusMessage ?? this.statusMessage,
      config: config ?? this.config,
      peers: peers ?? this.peers,
    );
  }
}

class HotspotGameStartPayload {
  final HotspotRoomConfig config;
  final List<HotspotPeer> peers;

  const HotspotGameStartPayload({required this.config, required this.peers});

  Map<String, dynamic> toJson() => {
        'config': config.toJson(),
        'peers': peers.map((p) => p.toJson()).toList(),
      };

  factory HotspotGameStartPayload.fromJson(Map<String, dynamic> json) {
    return HotspotGameStartPayload(
      config: HotspotRoomConfig.fromJson(
        (json['config'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
      peers: ((json['peers'] as List?) ?? const [])
          .map((item) => HotspotPeer.fromJson((item as Map).cast<String, dynamic>()))
          .toList(),
    );
  }
}

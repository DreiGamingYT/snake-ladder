import 'dart:convert';

class HotspotRoomConfig {
  final String roomName;
  final int maxPlayers;
  final int turnSeconds;
  final int bonusTiles;
  final int snakePenalty;
  final int ladderBonus;
  final bool advancedMode;

  const HotspotRoomConfig({
    required this.roomName,
    required this.maxPlayers,
    required this.turnSeconds,
    required this.bonusTiles,
    required this.snakePenalty,
    required this.ladderBonus,
    required this.advancedMode,
  });

  factory HotspotRoomConfig.defaults() => const HotspotRoomConfig(
        roomName: 'Snake & Ladder Room',
        maxPlayers: 4,
        turnSeconds: 20,
        bonusTiles: 4,
        snakePenalty: 1,
        ladderBonus: 1,
        advancedMode: true,
      );

  Map<String, dynamic> toJson() => {
        'roomName': roomName,
        'maxPlayers': maxPlayers,
        'turnSeconds': turnSeconds,
        'bonusTiles': bonusTiles,
        'snakePenalty': snakePenalty,
        'ladderBonus': ladderBonus,
        'advancedMode': advancedMode,
      };

  factory HotspotRoomConfig.fromJson(Map<String, dynamic> json) {
    return HotspotRoomConfig(
      roomName: (json['roomName'] ?? 'Snake & Ladder Room').toString(),
      maxPlayers: (json['maxPlayers'] ?? 4) as int,
      turnSeconds: (json['turnSeconds'] ?? 20) as int,
      bonusTiles: (json['bonusTiles'] ?? 4) as int,
      snakePenalty: (json['snakePenalty'] ?? 1) as int,
      ladderBonus: (json['ladderBonus'] ?? 1) as int,
      advancedMode: (json['advancedMode'] ?? true) as bool,
    );
  }

  String encode() => jsonEncode(toJson());

  factory HotspotRoomConfig.decode(String source) {
    return HotspotRoomConfig.fromJson(jsonDecode(source) as Map<String, dynamic>);
  }

  HotspotRoomConfig copyWith({
    String? roomName,
    int? maxPlayers,
    int? turnSeconds,
    int? bonusTiles,
    int? snakePenalty,
    int? ladderBonus,
    bool? advancedMode,
  }) {
    return HotspotRoomConfig(
      roomName: roomName ?? this.roomName,
      maxPlayers: maxPlayers ?? this.maxPlayers,
      turnSeconds: turnSeconds ?? this.turnSeconds,
      bonusTiles: bonusTiles ?? this.bonusTiles,
      snakePenalty: snakePenalty ?? this.snakePenalty,
      ladderBonus: ladderBonus ?? this.ladderBonus,
      advancedMode: advancedMode ?? this.advancedMode,
    );
  }
}

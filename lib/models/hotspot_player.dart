import 'dart:convert';

class HotspotPlayer {
  final String id;
  final String name;
  final int colorValue;
  final bool isHost;
  final bool ready;

  const HotspotPlayer({
    required this.id,
    required this.name,
    required this.colorValue,
    required this.isHost,
    required this.ready,
  });

  HotspotPlayer copyWith({
    String? id,
    String? name,
    int? colorValue,
    bool? isHost,
    bool? ready,
  }) {
    return HotspotPlayer(
      id: id ?? this.id,
      name: name ?? this.name,
      colorValue: colorValue ?? this.colorValue,
      isHost: isHost ?? this.isHost,
      ready: ready ?? this.ready,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'colorValue': colorValue,
        'isHost': isHost,
        'ready': ready,
      };

  factory HotspotPlayer.fromJson(Map<String, dynamic> json) {
    return HotspotPlayer(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      colorValue: (json['colorValue'] ?? 0xFF2E7D32) as int,
      isHost: (json['isHost'] ?? false) as bool,
      ready: (json['ready'] ?? false) as bool,
    );
  }

  String encode() => jsonEncode(toJson());

  factory HotspotPlayer.decode(String source) =>
      HotspotPlayer.fromJson(jsonDecode(source) as Map<String, dynamic>);
}

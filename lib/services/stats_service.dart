import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class PlayerStatEntry {
  final String name;
  final String avatar;
  int wins;
  int gamesPlayed;
  int totalMoves;
  int snakesHit;
  int laddersClimbed;

  PlayerStatEntry({
    required this.name,
    required this.avatar,
    this.wins = 0,
    this.gamesPlayed = 0,
    this.totalMoves = 0,
    this.snakesHit = 0,
    this.laddersClimbed = 0,
  });

  factory PlayerStatEntry.fromJson(Map<String, dynamic> j) => PlayerStatEntry(
    name: j['name'] ?? '',
    avatar: j['avatar'] ?? '🦊',
    wins: j['wins'] ?? 0,
    gamesPlayed: j['gamesPlayed'] ?? 0,
    totalMoves: j['totalMoves'] ?? 0,
    snakesHit: j['snakesHit'] ?? 0,
    laddersClimbed: j['laddersClimbed'] ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'avatar': avatar,
    'wins': wins,
    'gamesPlayed': gamesPlayed,
    'totalMoves': totalMoves,
    'snakesHit': snakesHit,
    'laddersClimbed': laddersClimbed,
  };
}

class StatsService {
  static const _key = 'sl_leaderboard_v1';

  List<PlayerStatEntry> _entries = [];
  List<PlayerStatEntry> get entries => List.unmodifiable(_entries);

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw != null) {
        final list = jsonDecode(raw) as List<dynamic>;
        _entries = list.map((e) => PlayerStatEntry.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
  }

  Future<void> recordGame({
    required String name,
    required String avatar,
    required bool won,
    required int totalMoves,
    required int snakesHit,
    required int laddersClimbed,
  }) async {
    final idx = _entries.indexWhere((e) => e.name == name);
    if (idx >= 0) {
      _entries[idx].gamesPlayed++;
      _entries[idx].wins += won ? 1 : 0;
      _entries[idx].totalMoves += totalMoves;
      _entries[idx].snakesHit += snakesHit;
      _entries[idx].laddersClimbed += laddersClimbed;
    } else {
      _entries.add(PlayerStatEntry(
        name: name,
        avatar: avatar,
        wins: won ? 1 : 0,
        gamesPlayed: 1,
        totalMoves: totalMoves,
        snakesHit: snakesHit,
        laddersClimbed: laddersClimbed,
      ));
    }
    // Sort by wins desc
    _entries.sort((a, b) => b.wins.compareTo(a.wins));
    await _save();
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, jsonEncode(_entries.map((e) => e.toJson()).toList()));
    } catch (_) {}
  }

  Future<void> clearAll() async {
    _entries.clear();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
    } catch (_) {}
  }
}
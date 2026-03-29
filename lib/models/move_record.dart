import 'package:flutter/material.dart';

class MoveRecord {
  final String playerName;
  final String playerAvatar;
  final Color playerColor;
  final List<int> diceRolls;
  final int fromPosition;
  final int toPosition;
  final String? event; // 'snake', 'ladder', 'trap', 'boost', 'teleport', 'bonus_roll', 'skip_turn', 'swap', 'safe_zone', 'shield_blocked', etc.

  const MoveRecord({
    required this.playerName,
    required this.playerAvatar,
    required this.playerColor,
    required this.diceRolls,
    required this.fromPosition,
    required this.toPosition,
    this.event,
  });

  int get totalRoll => diceRolls.fold(0, (a, b) => a + b);

  String get diceDisplay =>
      diceRolls.length == 1 ? '${diceRolls[0]}' : '${diceRolls[0]}+${diceRolls[1]}=${totalRoll}';

  String get eventDisplay {
    if (event == null) return '';
    switch (event!) {
      case 'snake': return '🐍 Snake! $fromPosition→$toPosition';
      case 'ladder': return '🪜 Ladder! $fromPosition→$toPosition';
      case 'safe_zone': return '🛡️ Safe Zone!';
      case 'shield_blocked': return '🛡️ Shield blocked snake!';
      case 'trap': return '🪤 Trap! Went back 3';
      case 'boost': return '🚀 Boost! Moved forward';
      case 'teleport': return '🌀 Teleport to $toPosition!';
      case 'bonus_roll': return '🎲 Bonus Roll!';
      case 'skip_turn': return '💤 Skipped next turn';
      case 'swap': return '🔄 Swapped positions!';
      case 'overshoot': return '🎯 Needs exact roll';
      default: return event!;
    }
  }
}